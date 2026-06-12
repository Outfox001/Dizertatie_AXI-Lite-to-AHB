//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_driver.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite driver class, responsible for driving AXI Lite transactions to the DUT.
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class axi_lite_driver extends uvm_driver#(axi_lite_item);

  `uvm_component_utils(axi_lite_driver)

  virtual axi_lite_tb_if vif_axi;
  // Mailboxes
  mailbox #(axi_lite_item) awaddr_mbox;
  mailbox #(axi_lite_item) araddr_mbox;
  mailbox #(axi_lite_item) wdata_mbox;
  mailbox #(axi_lite_item) resp_mbox;
  mailbox #(axi_lite_item) rdata_mbox;
  // Queues for debug / FIFO tracking only
  axi_lite_item outstanding_writes[$];
  axi_lite_item outstanding_reads[$];
  // Outstanding transaction control
  localparam int MAX_AW_OUTSTANDING = 16;
  localparam int MAX_AR_OUTSTANDING = 16;

  semaphore aw_slots;
  semaphore ar_slots;
  semaphore aw_count_lock;
  semaphore ar_count_lock;

  int unsigned aw_outstanding_count = 0;
  int unsigned ar_outstanding_count = 0;
  int unsigned next_internal_id = 0;
  // Events to wake response threads
  event wr_outstanding_ev;
  event rd_outstanding_ev;


  // Class constructor
  function new(string name = "axi_lite_driver", uvm_component parent = null);
    super.new(name, parent);
    awaddr_mbox = new();
    araddr_mbox = new();
    wdata_mbox  = new();
    resp_mbox   = new();
    rdata_mbox  = new();
    // 16 credits = maximum 16 transactions waiting for response
    aw_slots = new(MAX_AW_OUTSTANDING);
    ar_slots = new(MAX_AR_OUTSTANDING);
    aw_count_lock = new(1);
    ar_count_lock = new(1);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_tb_if)::get(this, "", "vif_axi", vif_axi)) begin
      `uvm_fatal(get_type_name(), "No handle received for axi_lite_tb_if")
    end
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    init();
    forever begin
      // Așteaptă reset activ (LOW)
      @(negedge vif_axi.rst_n);
      `uvm_info(get_type_name(), "RESET ASSERTED", UVM_MEDIUM)
      // Curăță complet driverul
      flush_driver();
      init(); // reset semnale
      // Așteaptă release reset
      @(posedge vif_axi.rst_n);
      `uvm_info(get_type_name(), "RESET RELEASED", UVM_MEDIUM)
      // Pornește toate procesele
      fork
        begin
          fork
            wr_resp_handshake();
            rd_data_handshake();
            get_and_drive();
          join_none
          @(negedge vif_axi.rst_n);
        end
      join_any
      disable fork;
    end
  endtask

  task init();
    @(vif_axi.cb_drv);
    vif_axi.awvalid <= 1'b0;
    vif_axi.awaddr  <= 32'b0;
    vif_axi.arvalid <= 1'b0;
    vif_axi.araddr  <= 32'b0;
    vif_axi.wvalid  <= 1'b0;
    vif_axi.wdata   <= 64'b0;
    vif_axi.bready  <= 1'b0;
    vif_axi.rready  <= 1'b0;
  endtask : init

  task flush_driver();
    outstanding_reads.delete();
    outstanding_writes.delete();
    aw_slots = new(MAX_AW_OUTSTANDING);
    ar_slots = new(MAX_AR_OUTSTANDING);
    aw_outstanding_count = 0;
    ar_outstanding_count = 0;
    awaddr_mbox = new();
    araddr_mbox = new();
    wdata_mbox  = new();
    rdata_mbox  = new();
  endtask

  task reserve_aw_slot(axi_lite_item item);
    aw_slots.get(1);
    aw_count_lock.get(1);
    item.internal_id = next_internal_id++;
    aw_outstanding_count++;
    if (aw_outstanding_count > MAX_AW_OUTSTANDING) begin
      `uvm_error(get_type_name(), $sformatf("[WRITE] AW outstanding exceeded! count=%0d", aw_outstanding_count))
    end
    `uvm_info(get_type_name(), $sformatf("[WRITE] Reserved AW slot. internal_id=%0d aw_outstanding_count=%0d", item.internal_id, aw_outstanding_count), UVM_LOW)
    aw_count_lock.put(1);
  endtask

  task release_aw_slot(axi_lite_item item);
    aw_count_lock.get(1);

    if (aw_outstanding_count > 0)
      aw_outstanding_count--;
    else
      `uvm_error(get_type_name(), "[WRITE] Release AW slot when count is already 0")

    `uvm_info(get_type_name(), $sformatf("[WRITE] Released AW slot. internal_id=%0d aw_outstanding_count=%0d", item.internal_id, aw_outstanding_count), UVM_LOW)

    aw_count_lock.put(1);

    // Important: avoid issuing a new AW in the exact same sampling cycle as B completion
    @(vif_axi.cb_drv);
    aw_slots.put(1);
  endtask

  task reserve_ar_slot(axi_lite_item item);
    ar_slots.get(1);
    ar_count_lock.get(1);
    item.internal_id = next_internal_id++;
    ar_outstanding_count++;
    if (ar_outstanding_count > MAX_AR_OUTSTANDING) begin
      `uvm_error(get_type_name(), $sformatf("[READ] AR outstanding exceeded! count=%0d", ar_outstanding_count))
    end
    `uvm_info(get_type_name(), $sformatf("[READ] Reserved AR slot. internal_id=%0d ar_outstanding_count=%0d", item.internal_id, ar_outstanding_count), UVM_LOW)
    ar_count_lock.put(1);
  endtask

  task release_ar_slot(axi_lite_item item);
    ar_count_lock.get(1);
    if (ar_outstanding_count > 0)
      ar_outstanding_count--;
    else
      `uvm_error(get_type_name(), "[READ] Release AR slot when count is already 0")
    `uvm_info(get_type_name(), $sformatf("[READ] Released AR slot. internal_id=%0d ar_outstanding_count=%0d", item.internal_id, ar_outstanding_count), UVM_LOW)
    ar_count_lock.put(1);
    @(vif_axi.cb_drv);
    ar_slots.put(1);
  endtask

  task get_and_drive();
    forever begin
     seq_item_port.get_next_item(req);

     `uvm_info("Getting next item...", $sformatf("req.row : %h", req.row), UVM_LOW)
     $cast(rsp, req.clone());
     rsp.set_id_info(req);
     `uvm_info(get_type_name(), $sformatf("TRANSACTION %s", rsp.sprint()), UVM_NONE)
     if (rsp.row) begin
       // WRITE
       reserve_aw_slot(rsp);
       outstanding_writes.push_back(rsp);
       -> wr_outstanding_ev;
       awaddr_mbox.put(rsp);
       fork
         wr_addr_handshake();
         wr_data_handshake();
       join
     end
     else begin
       // READ
       reserve_ar_slot(rsp);
       outstanding_reads.push_back(rsp);
       -> rd_outstanding_ev;
       araddr_mbox.put(rsp);
       rd_addr_handshake();
     end
     seq_item_port.item_done();
    end
  endtask : get_and_drive



//------------------------------------------------------------------------------
// AXI WRITE ADDRESS CHANNEL
//------------------------------------------------------------------------------
  task wr_addr_handshake();
    axi_lite_item item;
    awaddr_mbox.get(item);
    case(item.addr_hsk_type)
      VAL_BFR_RDY: begin
        repeat(item.addr_val_rdy_dly) @(vif_axi.cb_drv);
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        vif_axi.cb_drv.awvalid <= 1'b1;
        `uvm_info(get_type_name(), $sformatf("WRITE AW start: addr=0x%0h awready=%0b id=%0d", item.awaddr, vif_axi.awready, item.internal_id), UVM_LOW)
        @(vif_axi.cb_drv iff (vif_axi.awvalid && vif_axi.awready));
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
      RDY_BFR_VAL: begin
        repeat(item.addr_rdy_val_dly) @(vif_axi.cb_drv);
        @(vif_axi.cb_drv iff vif_axi.cb_drv.awready);
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        vif_axi.cb_drv.awvalid <= 1'b1;
        `uvm_info(get_type_name(), $sformatf("WRITE AW start: addr=0x%0h awready=%0b id=%0d", item.awaddr, vif_axi.awready, item.internal_id), UVM_LOW)
        @(vif_axi.cb_drv iff (vif_axi.awvalid && vif_axi.awready));
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
      VAL_AND_RDY: begin
        @(vif_axi.cb_drv);
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        vif_axi.cb_drv.awvalid <= 1'b1;
        `uvm_info(get_type_name(), $sformatf("WRITE AW start: addr=0x%0h awready=%0b id=%0d", item.awaddr, vif_axi.awready, item.internal_id), UVM_LOW)
        @(vif_axi.cb_drv iff (vif_axi.awvalid && vif_axi.awready));
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
    endcase
    wdata_mbox.put(item);
  endtask : wr_addr_handshake



//------------------------------------------------------------------------------
// AXI WRITE DATA CHANNEL
//------------------------------------------------------------------------------

  task wr_data_handshake();
    axi_lite_item item;
    @( vif_axi.cb_drv);
    wdata_mbox.get(item);
    case(item.data_hsk_type)
      VAL_BFR_RDY: begin
        repeat(item.data_val_rdy_dly)
          @(vif_axi.cb_drv);
        vif_axi.cb_drv.wvalid <= 1'b1;
        vif_axi.cb_drv.wdata  <= item.wdata;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.wready);
        vif_axi.cb_drv.wvalid <= 1'b0;
      end
      RDY_BFR_VAL: begin
        @(vif_axi.cb_drv iff vif_axi.cb_drv.wready);
        repeat(item.data_rdy_val_dly)
          @(vif_axi.cb_drv);
        vif_axi.cb_drv.wvalid <= 1'b1;
        vif_axi.cb_drv.wdata  <= item.wdata;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.wready);
        vif_axi.cb_drv.wvalid <= 1'b0;
      end
      VAL_AND_RDY: begin
        @(vif_axi.cb_drv iff vif_axi.cb_drv.wready);
        vif_axi.cb_drv.wvalid <= 1'b1;
        vif_axi.cb_drv.wdata  <= item.wdata;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.wready);
        vif_axi.cb_drv.wvalid <= 1'b0;
      end
    endcase

  endtask : wr_data_handshake

task wr_resp_handshake();
  axi_lite_item item;
  forever begin
    while (outstanding_writes.size() == 0) begin
      @wr_outstanding_ev;
    end
    item = outstanding_writes[0];
    case (item.resp_hsk_type)
      VAL_BFR_RDY: begin
        // DUT asserts BVALID first
        @(vif_axi.cb_drv iff vif_axi.cb_drv.bvalid);
        repeat (item.resp_val_rdy_dly) begin
          @(vif_axi.cb_drv);
        end
        // Driver asserts BREADY
        vif_axi.cb_drv.bready <= 1'b1;
        // Do NOT sample bready.
        // Wait one cycle so driven bready is visible to DUT/checker.
        @(vif_axi.cb_drv);
        // Now wait only for DUT signal BVALID.
        while (!vif_axi.cb_drv.bvalid) begin
          @(vif_axi.cb_drv);
        end
        `uvm_info(get_type_name(),$sformatf("B RESPONSE ACCEPTED: id=%0d bvalid=%0b time=%0t",item.internal_id, vif_axi.cb_drv.bvalid, $time),UVM_LOW)
        // Keep BREADY high for this accepted cycle, then drop next cycle
        @(vif_axi.cb_drv);
        vif_axi.cb_drv.bready <= 1'b0;
      end
      RDY_BFR_VAL: begin
        repeat (item.resp_rdy_val_dly) begin
          @(vif_axi.cb_drv);
        end
        // Driver asserts BREADY before BVALID
        vif_axi.cb_drv.bready <= 1'b1;
        // Wait one cycle after driving BREADY
        @(vif_axi.cb_drv);
        // Wait only for DUT BVALID
        while (!vif_axi.cb_drv.bvalid) begin
          @(vif_axi.cb_drv);
        end
        `uvm_info(get_type_name(), $sformatf("B RESPONSE ACCEPTED: id=%0d bvalid=%0b time=%0t",item.internal_id, vif_axi.cb_drv.bvalid, $time),UVM_LOW)
        @(vif_axi.cb_drv);
        vif_axi.cb_drv.bready <= 1'b0;
      end

      VAL_AND_RDY: begin
        // Driver asserts BREADY immediately
        vif_axi.cb_drv.bready <= 1'b1;
        // Wait one cycle after driving BREADY
        @(vif_axi.cb_drv);
        // Wait only for DUT BVALID
        while (!vif_axi.cb_drv.bvalid) begin
          @(vif_axi.cb_drv);
        end
        `uvm_info(get_type_name(),$sformatf("B RESPONSE ACCEPTED: id=%0d bvalid=%0b time=%0t",item.internal_id, vif_axi.cb_drv.bvalid, $time),UVM_LOW)
        @(vif_axi.cb_drv);
        vif_axi.cb_drv.bready <= 1'b0;
      end
    endcase
    void'(outstanding_writes.pop_front());
    release_aw_slot(item);
    if (outstanding_writes.size() == 0) begin
      vif_axi.cb_drv.bready <= 1'b0;
    end
  end
endtask : wr_resp_handshake

//------------------------------------------------------------------------------
// AXI READ ADDRESS CHANNEL
//------------------------------------------------------------------------------

  task rd_addr_handshake();
    axi_lite_item item;
    @(vif_axi.cb_drv);
    araddr_mbox.get(item);
    case(item.addr_hsk_type)
      VAL_BFR_RDY: begin
        repeat(item.addr_val_rdy_dly)
          @(vif_axi.cb_drv);
        vif_axi.cb_drv.arvalid <= 1'b1;
        vif_axi.cb_drv.araddr  <= item.araddr;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.arready);
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
      RDY_BFR_VAL: begin
        repeat(item.addr_rdy_val_dly)
          @(vif_axi.cb_drv);
        vif_axi.cb_drv.arvalid <= 1'b1;
        vif_axi.cb_drv.araddr  <= item.araddr;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.arready);
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
      VAL_AND_RDY: begin
        @(vif_axi.cb_drv iff vif_axi.cb_drv.arready);
        vif_axi.cb_drv.arvalid <= 1'b1;
        vif_axi.cb_drv.araddr  <= item.araddr;
        @(vif_axi.cb_drv iff vif_axi.cb_drv.arready);
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
    endcase
    rdata_mbox.put(item);

  endtask : rd_addr_handshake

  task rd_data_handshake();
    axi_lite_item item;
    forever begin
      rdata_mbox.get(item);
      case(item.data_hsk_type)
        //----------------------------------------
        VAL_BFR_RDY:
        //----------------------------------------
        begin
          // DUT first: wait for RVALID
          @(vif_axi.cb_drv iff vif_axi.cb_drv.rvalid);
          repeat(item.data_val_rdy_dly)
            @(vif_axi.cb_drv);
          // Driver asserts RREADY
          vif_axi.cb_drv.rready <= 1'b1;
          // wait one cycle after driving
          @(vif_axi.cb_drv);
          // wait only for DUT signal
          while (!vif_axi.cb_drv.rvalid)
            @(vif_axi.cb_drv);
          `uvm_info(get_type_name(),$sformatf("R RESPONSE ACCEPTED: id=%0d time=%0t",item.internal_id, $time), UVM_LOW)
          @(vif_axi.cb_drv);
          vif_axi.cb_drv.rready <= 1'b0;
        end
        //----------------------------------------
        RDY_BFR_VAL:
        //----------------------------------------
        begin
          repeat(item.data_rdy_val_dly)
            @(vif_axi.cb_drv);
          vif_axi.cb_drv.rready <= 1'b1;
          @(vif_axi.cb_drv);
          while (!vif_axi.cb_drv.rvalid)
            @(vif_axi.cb_drv);
          `uvm_info(get_type_name(),$sformatf("R RESPONSE ACCEPTED: id=%0d time=%0t",item.internal_id, $time), UVM_LOW)
          @(vif_axi.cb_drv);
          vif_axi.cb_drv.rready <= 1'b0;
        end
        //----------------------------------------
        VAL_AND_RDY:
        //----------------------------------------
        begin
          vif_axi.cb_drv.rready <= 1'b1;
          @(vif_axi.cb_drv);
          while (!vif_axi.cb_drv.rvalid)
            @(vif_axi.cb_drv);
          `uvm_info(get_type_name(),$sformatf("R RESPONSE ACCEPTED: id=%0d time=%0t",item.internal_id, $time), UVM_LOW)
          @(vif_axi.cb_drv);
          vif_axi.cb_drv.rready <= 1'b0;
        end
      endcase
      if (outstanding_reads.size() > 0)
        void'(outstanding_reads.pop_front());
      else
        `uvm_error(get_type_name(),
          "Received R but outstanding_reads is empty")
      release_ar_slot(item);
    end
  endtask


endclass : axi_lite_driver


