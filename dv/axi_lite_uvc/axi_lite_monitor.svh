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

class axi_lite_monitor extends uvm_monitor;

  `uvm_component_utils (axi_lite_monitor)


  //monitor constructor
  function new (string name = "axi_lite_monitor" , uvm_component parent = null);
    super.new (name, parent);
  endfunction: new

  axi_lite_item m_item;

  virtual axi_lite_if vif_axi; //declaration of virtual interface

  uvm_analysis_port #(axi_lite_item) mon_analysis_port; //data analysis port input for monitor

  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif_axi", vif_axi)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_if");
     end
    //Creation of declared analysis port
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction: build_phase


  virtual task run_phase(uvm_phase phase);
    m_item = axi_lite_item::type_id::create("m_item",this);
    forever begin
      collect_items();
    end
  endtask : run_phase

  task collect_items();
    collect_wr_addr(m_item);
    collect_wr_data(m_item);
    collect_wr_response(m_item);
    //$display("%s", m_item.sprint());
    mon_analysis_port.write(m_item);
  endtask : collect_items

  task collect_wr_addr(ref axi_lite_item item);
    @(posedge vif_axi.clk iff (vif_axi.awvalid & vif_axi.awready));
    item.awaddr   = vif_axi.awaddr;
  endtask : collect_wr_addr

  task collect_wr_data(ref axi_lite_item item);
    @(posedge vif_axi.clk iff (vif_axi.wvalid & vif_axi.wready));
      item.wdata = vif_axi.wdata;
  endtask : collect_wr_data

  task collect_wr_response(ref axi_lite_item item);
    @(posedge vif_axi.clk iff (vif_axi.bvalid & vif_axi.bready));
    item.bresp = vif_axi.bresp;
  endtask : collect_wr_response

  task collect_rd_addr(ref axi_lite_item item);
    @(posedge vif_axi.clk iff (vif_axi.arvalid & vif_axi.arready));
    item.araddr   = vif_axi.araddr;
  endtask : collect_rd_addr

  task collect_rd_data(ref axi_lite_item item);
    @(posedge vif_axi.clk iff (vif_axi.rvalid & vif_axi.rready));
      item.rdata = vif_axi.rdata;
      item.rresp = vif_axi.rresp;
  endtask : collect_rd_data

endclass : axi_lite_monitor
