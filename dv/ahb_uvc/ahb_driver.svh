//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_item.svh
//  Last modified+updates: 02/03/2026 (BTS) - Initial Version
//
//  Project              : ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb transaction item,
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class ahb_driver extends uvm_driver #(ahb_item);
  `uvm_component_utils(ahb_driver)

  virtual ahb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     uvm_top.print_topology();
    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_if");
    end
  endfunction

  virtual task zero_values_slv();
    vif.cb_drv.hready <= 0;
    vif.cb_drv.hrdata <= 0;
    vif.cb_drv.hresp  <= 0;
    @(posedge vif.reset);
    @(vif.cb_drv);
  endtask

  task wait_reset_end();
    @(negedge vif.reset);
    zero_values_slv();
    @(vif.cb_drv);
  endtask

  virtual task run_phase(uvm_phase phase);
    zero_values_slv();
    forever begin
      fork : run_phase_fork
        wait_reset_end();
        get_and_drive();
      join
      disable run_phase_fork;
    end
  endtask

  task get_and_drive();
    forever begin
      seq_item_port.get_next_item(req);
      $cast(rsp, req.clone());
      rsp.set_id_info(req);
      drive_transfer(rsp);
      `uvm_info(get_type_name(),
              $sformatf("TRANSACTION DONE: %s", rsp.sprint()),
              UVM_NONE)
      seq_item_port.item_done();
    end
  endtask

  task drive_address_phase(ahb_item ahb_item_s);
    // @(vif.cb_drv iff (vif.cb_drv.htrans inside {NONSEQ,SEQ, IDLE, BUSY}));
    ahb_item_s.hburst = ahb_burst_e'(vif.cb_drv.hburst);
    ahb_item_s.htrans = ahb_trans_e'(vif.cb_drv.htrans);
    ahb_item_s.update_burst_from_hburst();
  endtask

  task drive_data_phase(ahb_item ahb_item_s);
    bit en_error = 0;
    bit next_error = 0;
    int data_beat = 0;

    while (data_beat < ahb_item_s.burst_len) begin
      // BEFORE clock edge: Check CURRENT address for error
      en_error = check_error_condition(vif.cb_drv.haddr);

      // BEFORE clock edge: Also peek at what comes NEXT to handle back-to-back
      // We need to know this BEFORE we finish the current error response

      $display("en_error is %b at time %t for addr 0x%0h", en_error, $realtime, vif.cb_drv.haddr);

      if(en_error) begin
        insert_error_hresp();
        data_beat++;  // Count the errored beat
      end else begin
        vif.cb_drv.hready <= 1;
        vif.cb_drv.hresp  <= 0;

        @(vif.cb_drv);  // Wait for next cycle

        // Check htrans to determine what to do
        if (vif.cb_drv.htrans inside {NONSEQ, SEQ}) begin
          // Valid transfer
          if (vif.cb_drv.hwrite == 0) begin
            // READ - drive data
            vif.cb_drv.hrdata <= ahb_item_s.hrdata_array[data_beat];
          end else begin
            // WRITE - print data
            `uvm_info(get_type_name(),
                      $sformatf("SLAVE WRITE [%0d/%0d]: data=%h",
                                data_beat, ahb_item_s.burst_len, vif.cb_drv.hwdata),
                      UVM_HIGH)
          end
          data_beat++;

        end else if (vif.cb_drv.htrans inside {BUSY}) begin
          // BUSY - no data transfer
          if (vif.cb_drv.hwrite == 0) begin
            vif.cb_drv.hrdata <= 'hx;
          end
          `uvm_info(get_type_name(),
                    $sformatf("SLAVE: BUSY (data_beat=%0d/%0d)", data_beat, ahb_item_s.burst_len),
                    UVM_HIGH)

        end else if (vif.cb_drv.htrans inside {IDLE}) begin
          // IDLE - no data transfer
          if (vif.cb_drv.hwrite == 0) begin
            $display("idle slave read at time %t", $realtime);
          end
        end

        // Wait states - only after valid transfers
        if (ahb_item_s.delay > 0 && data_beat > 0 &&
            vif.cb_drv.htrans inside {NONSEQ, SEQ}) begin
          vif.cb_drv.hready <= 0;
          repeat (ahb_item_s.delay) @(vif.cb_drv);
        end
      end
    end
  endtask

  function bit check_error_condition(bit [ADDR_WIDTH-1:0] addr);
    // Check for unaligned address (word alignment)
    if (addr[1:0] != 2'b00) begin
      `uvm_info(get_type_name(),
                $sformatf("ERROR: Unaligned address detected: 0x%0h at time %t", addr, $realtime),
                UVM_NONE)
      return 1;
    end
    return 0;
  endfunction

  task insert_error_hresp();
    bit next_will_error;

    `uvm_info(get_type_name(),
              $sformatf("Inserting ERROR response at time %t for addr 0x%0h",
                        $realtime, vif.cb_drv.haddr),
              UVM_NONE)

    // First cycle: HRESP=1, HREADY=0
    vif.cb_drv.hresp  <= 1;
    vif.cb_drv.hready <= 0;
    vif.cb_drv.hrdata <= 'h0;
    @(vif.cb_drv);

    // Second cycle: HRESP=1, HREADY=1
    vif.cb_drv.hready <= 1;
    // HRESP stays 1

    // NOW check if the NEXT address (visible now after clock edge) will also error
    if (vif.cb_drv.htrans inside {NONSEQ, SEQ}) begin
      next_will_error = check_error_condition(vif.cb_drv.haddr);
    end else begin
      next_will_error = 0;
    end

    @(vif.cb_drv);  // Move to next cycle

    // Only clear HRESP if next is NOT an error
    if (!next_will_error) begin
      vif.cb_drv.hresp <= 0;
      `uvm_info(get_type_name(), "Clearing HRESP", UVM_NONE)
    end else begin
      // Keep HRESP=1 for back-to-back error
      `uvm_info(get_type_name(), "Back-to-back error: keeping HRESP=1", UVM_NONE)
    end
  endtask

  task drive_transfer(ahb_item ref_item);
    ahb_item ahb_item_s;
    $cast(ahb_item_s, ref_item);
    fork
      drive_address_phase(ahb_item_s);
      drive_data_phase(ahb_item_s);
    join
  endtask
endclass : ahb_driver
