//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_driver.svh
//  Last modified+updates: 12/06/2026 (BTS)
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : AHB Completer Driver with proper address and data phase handling.
//                         Handles 2-transaction pattern: NONSEQ (address) + SEQ (data).
//                         Supports ready signals for both phases, data transmission, and error responses.
//  ======================================================================================================

class ahb_driver extends uvm_driver #(ahb_item);
  `uvm_component_utils(ahb_driver)

  virtual ahb_tb_if vif;
  ahb_memory mem;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_top.print_topology();
    if (!uvm_config_db#(virtual ahb_tb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_tb_if");
    end
    if (!uvm_config_db#(ahb_memory)::get(this, "", "mem", mem)) begin
      `uvm_fatal(get_type_name(), "No ahb_memory handle received")
    end
  endfunction

  // Initialize slave outputs to safe values
  virtual task zero_values_slv();
    vif.cb_drv.hready <= 0;
    vif.cb_drv.hrdata <= 0;
    vif.cb_drv.hresp  <= 0;
    @(posedge vif.rst_n);
    @(vif.cb_drv);
  endtask

  task wait_rst_n_end();
    @(negedge vif.rst_n);
    zero_values_slv();
    @(vif.cb_drv);
  endtask

  virtual task run_phase(uvm_phase phase);
    zero_values_slv();
    forever begin
      fork : run_phase_fork
        wait_rst_n_end();
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
      `uvm_info(get_type_name(),$sformatf("TRANSACTION DONE: %s", rsp.sprint()),UVM_NONE)
      seq_item_port.item_done();
    end
  endtask

  task drive_address_phase(ahb_item ahb_item_s);
    @(vif.cb_drv iff (vif.cb_drv.htrans inside {NONSEQ,SEQ}));
    ahb_item_s.htrans = ahb_trans_e'(vif.cb_drv.htrans);
    ahb_item_s.haddr  = vif.cb_drv.haddr;
  endtask

  task drive_data_phase(ahb_item ahb_item_s);
    bit en_error = 0;
    bit next_error = 0;
    int data_beat = 0;
    bit hit;

    while (data_beat < ahb_item_s.burst_len) begin
      // Check CURRENT address for error
    `uvm_info(get_type_name(),$sformatf("addr: %h", vif.haddr),UVM_NONE)
      en_error = check_error_condition(vif.haddr);
      // BEFORE clock edge: Also peek at what comes NEXT to handle back-to-back
      $display("en_error is %b at time %t for addr 0x%0h", en_error, $realtime, vif.cb_drv.haddr);
      if(en_error) begin
        insert_error_hresp();
        data_beat++;
      end else begin
        vif.cb_drv.hready <= 1;
        vif.cb_drv.hresp  <= 0;
        @(vif.cb_drv);
        // Check htrans to determine what to do
        if (vif.cb_drv.htrans inside {NONSEQ, SEQ}) begin
          // Valid transfer
          if (vif.cb_drv.hwrite == 0) begin
            // READ - drive data with ready
            vif.cb_drv.hrdata <= mem.load(vif.cb_drv.haddr, hit);
          end else begin
            // WRITE - print data
            mem.store(vif.cb_drv.haddr, vif.cb_drv.hwdata);
            `uvm_info(get_type_name(),$sformatf("SLAVE WRITE [%0d/%0d]: data=%h",data_beat, ahb_item_s.burst_len, vif.cb_drv.hwdata),UVM_LOW)
          end
          data_beat++;
        end

        // Wait states - only after valid transfers
        if (ahb_item_s.delay > 0 && data_beat > 0 && vif.cb_drv.htrans inside {NONSEQ, SEQ})
          begin
            vif.cb_drv.hready <= 0;
            repeat (ahb_item_s.delay) @(vif.cb_drv);
          end
        end
      end
  endtask

  function bit check_error_condition(bit [ADDR_WIDTH-1:0] addr);
    // Check for unaligned address (word alignment)
    if (addr[1:0] != 2'b00) begin
      `uvm_info(get_type_name(),$sformatf("ERROR: Unaligned address detected: 0x%0h at time %t", addr, $realtime),UVM_NONE)
      return 1;
    end
    return 0;
  endfunction

  task insert_error_hresp();
    bit next_will_error;
    `uvm_info(get_type_name(), $sformatf("Inserting ERROR response at time %t for addr 0x%0h", $realtime, vif.cb_drv.haddr), UVM_NONE)
    vif.cb_drv.hresp  <= 1;
    vif.cb_drv.hready <= 0;
    vif.cb_drv.hrdata <= 'h0;
    @(vif.cb_drv);
    vif.cb_drv.hready <= 1;
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
