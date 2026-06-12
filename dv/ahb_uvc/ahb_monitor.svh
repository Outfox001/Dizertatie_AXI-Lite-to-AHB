//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_item.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb monitor class, which is responsible for collecting coverage data for AHB transactions,
//                         and connecting the driver and monitor components.
//  ======================================================================================================

class ahb_monitor extends uvm_monitor;

  `uvm_component_utils(ahb_monitor)

  virtual ahb_tb_if vif;
  ahb_memory mem;
  ahb_item item;

  uvm_analysis_port #(ahb_item) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ahb_tb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_tb_if")
    end
    if (!uvm_config_db#(ahb_memory)::get(this, "", "mem", mem)) begin
      `uvm_fatal(get_type_name(), "No ahb_memory handle received")
    end
    analysis_port = new("analysis_port", this);
    item = ahb_item::type_id::create("item", this);
  endfunction


  virtual task run_phase(uvm_phase phase);
    bit [31:0] prev_addr;
    bit        prev_write;
    bit [2:0]  prev_hsize;
    bit [1:0]  prev_htrans;
    bit        first_beat;

    first_beat = 1'b1;
    item.hready = vif.cb_mon.hready;
    forever begin
      @(vif.cb_mon iff (vif.cb_mon.hready &&vif.cb_mon.htrans inside {NONSEQ, SEQ}));
        if (first_beat) begin
          // ------------------------------------------------------------
          // First valid AHB address phase
          // ------------------------------------------------------------
          prev_addr   = vif.cb_mon.haddr;
          prev_write  = vif.cb_mon.hwrite;
          prev_hsize  = vif.cb_mon.hsize;
          prev_htrans = vif.cb_mon.htrans;
          first_beat  = 1'b0;
          `uvm_info(get_type_name(),$sformatf("AHB MON FIRST ADDR: addr=0x%0h write=%0b trans=%0d",prev_addr,prev_write,prev_htrans),UVM_LOW)
          // If first transfer is read, prepare data for driver
          if (!vif.cb_mon.hwrite) begin
            mem.prepare_read(vif.cb_mon.haddr);
          end
        end
        else begin
          // ------------------------------------------------------------
          // Complete previous transfer using current data phase signals
          // ------------------------------------------------------------
          item = ahb_item::type_id::create("item", this);
          item.haddr  = prev_addr;
          item.hwrite = prev_write;
          item.hsize  = prev_hsize;
          item.htrans = ahb_trans_e'(prev_htrans);
          item.hresp  = vif.cb_mon.hresp;
          // item.hready = vif.cb_mon.hready;
          if (prev_write) begin
            item.hwdata = vif.cb_mon.hwdata;
            // Store write data into memory model
            mem.store(item.haddr, item.hwdata);
            `uvm_info(get_type_name(),$sformatf("AHB MON WRITE COMPLETE: addr=0x%0h data=0x%0h trans=%0d",item.haddr,item.hwdata,item.htrans),UVM_LOW)
            `uvm_info(get_type_name(),$sformatf("AHB MON item%s",item.sprint()),UVM_LOW)
          end
          else begin
            item.hrdata = vif.cb_mon.hrdata;
            `uvm_info(get_type_name(),$sformatf("AHB MON READ COMPLETE: addr=0x%0h data=0x%0h trans=%0d",item.haddr,item.hrdata,item.htrans),UVM_LOW)
            `uvm_info(get_type_name(),$sformatf("AHB MON item%s",item.sprint()),UVM_LOW)
          end
          analysis_port.write(item);
          // ------------------------------------------------------------
          // Capture current address phase for next transfer
          // ------------------------------------------------------------
          prev_addr   = vif.cb_mon.haddr;
          prev_write  = vif.cb_mon.hwrite;
          prev_hsize  = vif.cb_mon.hsize;
          prev_htrans = vif.cb_mon.htrans;
          `uvm_info(get_type_name(),$sformatf("AHB MON NEXT ADDR: addr=0x%0h write=%0b trans=%0d",prev_addr,prev_write,prev_htrans),UVM_LOW)
          // If current transfer is read, prepare read data for AHB driver
          if (!vif.cb_mon.hwrite) begin
            mem.prepare_read(vif.cb_mon.haddr);
          end
        end

    end
  endtask

endclass : ahb_monitor

