//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_item.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite monitor, responsible for observing AXI-Lite transactions on the interface,
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class axi_lite_monitor extends uvm_monitor;

  `uvm_component_utils(axi_lite_monitor)

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------
  function new(string name = "axi_lite_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  // --------------------------------------------------------------------------
  // Virtual interface
  // --------------------------------------------------------------------------
  virtual axi_lite_tb_if vif_axi;
  // --------------------------------------------------------------------------
  // Analysis ports

  // --------------------------------------------------------------------------
  uvm_analysis_port #(axi_lite_item) wr_req_port;
  uvm_analysis_port #(axi_lite_item) wr_rsp_port;
  uvm_analysis_port #(axi_lite_item) rd_req_port;
  uvm_analysis_port #(axi_lite_item) rd_rsp_port;
  // --------------------------------------------------------------------------

  mailbox #(bit[31:0]) awaddr_mb;
  mailbox #(bit[63:0]) wdata_mb;

  // --------------------------------------------------------------------------
  // Build phase
  // --------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_lite_tb_if)::get(this, "", "vif_axi", vif_axi)) begin
      `uvm_fatal(get_type_name(), "No handle received for vif_axi")
    end

    wr_req_port = new("wr_req_port", this);
    wr_rsp_port = new("wr_rsp_port", this);
    rd_req_port = new("rd_req_port", this);
    rd_rsp_port = new("rd_rsp_port", this);

    awaddr_mb = new();
    wdata_mb  = new();

  endfunction : build_phase

  // --------------------------------------------------------------------------
  // Run phase
  //
  // All AXI-Lite channels are monitored independently.
  // --------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);

    wait_for_rst_n_done();
    fork
      collect_wr_addr();
      collect_wr_data();
      pair_write_transactions();
      collect_wr_response();
      collect_rd_addr();
      collect_rd_data();
    join

  endtask : run_phase
  // --------------------------------------------------------------------------
  // WRITE ADDRESS CHANNEL: AWVALID/AWREADY
  // Captures every AW handshake immediately.
  // Does not wait for W or B.
  // --------------------------------------------------------------------------
  task collect_wr_addr();
    bit [31:0] awaddr;
    forever begin
      @(vif_axi.cb_mon iff (vif_axi.cb_mon.awvalid && vif_axi.cb_mon.awready));
      awaddr = vif_axi.cb_mon.awaddr;
      awaddr_mb.put(awaddr);
      `uvm_info(get_type_name(),$sformatf("AW captured: awaddr=0x%0h",awaddr), UVM_LOW)
    end

  endtask : collect_wr_addr
  // --------------------------------------------------------------------------
  // WRITE DATA CHANNEL: WVALID/WREADY
  // Captures every W handshake immediately.
  // Does not wait for AW or B.
  // --------------------------------------------------------------------------
  task collect_wr_data();
    bit [63:0] wdata;

    forever begin
      @(vif_axi.cb_mon iff (vif_axi.cb_mon.wvalid && vif_axi.cb_mon.wready));
      wdata = vif_axi.cb_mon.wdata;
      wdata_mb.put(wdata);
      `uvm_info(get_type_name(),$sformatf("W captured: wdata=0x%0h", wdata),UVM_LOW)
    end

  endtask : collect_wr_data
  // --------------------------------------------------------------------------
  // WRITE REQUEST PAIRING
  // Sends WRITE request when both AW and W are available.
  // This does NOT wait for B response.
  // --------------------------------------------------------------------------

  task pair_write_transactions();
    bit [31:0] addr;
    bit [63:0] data;
    axi_lite_item wr_req_item;

    forever begin
      wr_req_item = axi_lite_item::type_id::create("wr_req_item", this);
      // Blocking calls → waits until both are available
      awaddr_mb.get(addr);
      wdata_mb.get(data);
      wr_req_item.row_mon = 1'b1;
      wr_req_item.awaddr  = addr;
      wr_req_item.wdata   = data;
      wr_req_port.write(wr_req_item);
      `uvm_info(get_type_name(),$sformatf("WRITE paired and sent:\n%s", wr_req_item.sprint()), UVM_LOW)
    end

  endtask

  // --------------------------------------------------------------------------
  // WRITE RESPONSE CHANNEL: BVALID/BREADY
  // Captures B response independently.
  // Does not block new AW/W transactions.
  // --------------------------------------------------------------------------
  task collect_wr_response();
    axi_lite_item wr_rsp_item;

    forever begin
      wr_rsp_item = axi_lite_item::type_id::create("wr_rsp_item", this);
      @(vif_axi.cb_mon iff (vif_axi.cb_mon.bvalid && vif_axi.cb_mon.bready));
      wr_rsp_item.row_mon = 1'b1;
      wr_rsp_item.bresp   = vif_axi.cb_mon.bresp;
      wr_rsp_port.write(wr_rsp_item);
      `uvm_info(get_type_name(),$sformatf("WRITE response sent on rsp_port:\n%s",wr_rsp_item.sprint()),UVM_LOW)
    end
  endtask : collect_wr_response
  // --------------------------------------------------------------------------
  // READ ADDRESS CHANNEL: ARVALID/ARREADY
  //
  // Captures every AR handshake immediately.
  // Does not wait for R response.
  // --------------------------------------------------------------------------
  task collect_rd_addr();
    axi_lite_item rd_req_item;

    forever begin
      rd_req_item = axi_lite_item::type_id::create("rd_req_item", this);
      @(vif_axi.cb_mon iff (vif_axi.cb_mon.arvalid && vif_axi.cb_mon.arready));
      rd_req_item.row_mon = 1'b0;
      rd_req_item.araddr  = vif_axi.cb_mon.araddr;
      rd_req_port.write(rd_req_item);
      `uvm_info(get_type_name(),$sformatf("READ request sent on req_port:\n%s",rd_req_item.sprint()),UVM_LOW)
    end

  endtask : collect_rd_addr
  // --------------------------------------------------------------------------
  // READ DATA CHANNEL: RVALID/RREADY
  //
  // Captures R data/response independently.
  // Does not block new AR transactions.
  // --------------------------------------------------------------------------
  task collect_rd_data();
    axi_lite_item rd_rsp_item;

    forever begin
      rd_rsp_item = axi_lite_item::type_id::create("rd_rsp_item", this);
      @(vif_axi.cb_mon iff (vif_axi.cb_mon.rvalid && vif_axi.cb_mon.rready));
      rd_rsp_item.row_mon = 1'b0;
      rd_rsp_item.rdata   = vif_axi.cb_mon.rdata;
      rd_rsp_item.rresp   = vif_axi.cb_mon.rresp;
      rd_rsp_port.write(rd_rsp_item);
      `uvm_info(get_type_name(),$sformatf("READ response sent on rsp_port:\n%s",rd_rsp_item.sprint()),UVM_LOW)
    end

  endtask : collect_rd_data
  // --------------------------------------------------------------------------
  // rst_n wait
  // --------------------------------------------------------------------------
  task wait_for_rst_n_done();
    `uvm_info(get_type_name(), "Waiting for rst_n deassertion", UVM_LOW)
    @(posedge vif_axi.rst_n);
    `uvm_info(get_type_name(), "rst_n deasserted. AXI-Lite monitor started.", UVM_LOW)
  endtask : wait_for_rst_n_done

endclass : axi_lite_monitor