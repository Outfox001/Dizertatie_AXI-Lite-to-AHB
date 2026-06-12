//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_coverage.svh
//  Last modified+updates: 12/06/2026 (BTS)
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb coverage class, which is responsible for collecting coverage data for AHB transactions.
//  ======================================================================================================

class ahb_coverage extends uvm_subscriber #(ahb_item);

  `uvm_component_utils(ahb_coverage)

  ahb_item tx;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_ahb = new();
  endfunction

//----------------------------------
  // Covergroup
  //----------------------------------
  covergroup cg_ahb;

    //-----------------------------
    // Transfer Type Coverage
    //-----------------------------
    CP_HTRANS: coverpoint tx.htrans {
      bins nonseq = {2'b10};
      bins seq    = {2'b11};
    }

    //-----------------------------
    // Read / Write Coverage
    //-----------------------------
    CP_HWRITE: coverpoint tx.hwrite {
      bins read  = {0};
      bins write = {1};
    }

    //-----------------------------
    // Response Coverage
    //-----------------------------
    CP_HRESP: coverpoint tx.hresp {
      bins ok    = {0};
      bins error = {1};
    }

    //-----------------------------
    // Ready Behavior
    //-----------------------------
    CP_HREADY: coverpoint tx.hready {
      bins ready     = {1};
      bins not_ready = {0};
    }

    //-----------------------------
    // Address Coverage
    //-----------------------------
    CP_HADDR: coverpoint tx.haddr {
      bins low  = {[32'h0000_0000 : 32'h0FFF_FFFF]};
      bins mid  = {[32'h1000_0000 : 32'h7FFF_FFFF]};
      bins high = {[32'h8000_0000 : 32'hFFFF_FFFF]};
    }

    //-----------------------------
    // Cross Coverage
    //-----------------------------

    // Transfer type vs operation
    CROSS_TRANS_OP: cross CP_HTRANS, CP_HWRITE;

    // Response vs operation
    CROSS_RESP_OP: cross CP_HRESP, CP_HWRITE;

    // Ready vs transfer type
    CROSS_READY_TRANS: cross CP_HREADY, CP_HTRANS;

  endgroup


  virtual function void write(ahb_item t);
    tx = t;
    `uvm_info ("AHB_COV",$sformatf("item : %s ",tx.sprint()), UVM_LOW)
    cg_ahb.sample();
  endfunction

endclass
