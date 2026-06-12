
//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_coverage.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite coverage class, which is responsible for collecting coverage data for AXI Lite transactions.
//  ======================================================================================================

`uvm_analysis_imp_decl(_wr_req)
`uvm_analysis_imp_decl(_wr_rsp)
`uvm_analysis_imp_decl(_rd_req)
`uvm_analysis_imp_decl(_rd_rsp)

class axi_lite_coverage extends uvm_component;

  uvm_analysis_imp_wr_req #(axi_lite_item, axi_lite_coverage) wr_req;
  uvm_analysis_imp_wr_rsp #(axi_lite_item, axi_lite_coverage) wr_rsp;
  uvm_analysis_imp_rd_req #(axi_lite_item, axi_lite_coverage) rd_req;
  uvm_analysis_imp_rd_rsp #(axi_lite_item, axi_lite_coverage) rd_rsp;

  `uvm_component_utils(axi_lite_coverage)

  axi_lite_item tx;

  //----------------------------------
  // Constructor
  //----------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);

    wr_req = new("wr_req", this);
    wr_rsp = new("wr_rsp", this);
    rd_req = new("rd_req", this);
    rd_rsp = new("rd_rsp", this);

    cg_axi_wr_addr   = new();
    cg_axi_rd_addr   = new();
    cg_axi_op        = new();
    cg_axi_wr_resp   = new();
    cg_axi_rd_resp   = new();
    cg_axi_wr_data   = new();
    cg_axi_rd_data   = new();

  endfunction

  // -----------------------------
  // Write Address Coverage
  // -----------------------------
  covergroup cg_axi_wr_addr;

    option.per_instance = 1;
    CP_AWADDR: coverpoint tx.awaddr {
      bins addr_range[16] = {[32'h0000_0000 : 32'hFFFF_FFFF]};
    }
    CP_AWALIGN: coverpoint tx.awaddr[2:0] {
      bins aligned_64bit   = {3'b000};
      bins unaligned_64bit = default;
    }
  endgroup

  // -----------------------------
  // Read Address Coverage
  // -----------------------------
  covergroup cg_axi_rd_addr;

    option.per_instance = 1;

    CP_ARADDR: coverpoint tx.araddr {
      bins addr_range[16] = {[32'h0000_0000 : 32'hFFFF_FFFF]};
    }

    CP_ARALIGN: coverpoint tx.araddr[2:0] {
      bins aligned_64bit   = {3'b000};
      bins unaligned_64bit = default;
    }
  endgroup


  // -----------------------------
  // Operation Coverage
  // -----------------------------
  covergroup cg_axi_op;
    option.per_instance = 1;
    // row = 1 -> write
    // row = 0 -> read
    CP_OP: coverpoint tx.row_mon {
      bins read  = {0};
      bins write = {1};
    }
  endgroup


  // -----------------------------
  // Write Response Coverage
  // -----------------------------
  covergroup cg_axi_wr_resp;
    option.per_instance = 1;
    CP_BRESP: coverpoint tx.bresp {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
    }
  endgroup


  // -----------------------------
  // Read Response Coverage
  // -----------------------------
  covergroup cg_axi_rd_resp;
    option.per_instance = 1;
    CP_RRESP: coverpoint tx.rresp {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
    }
  endgroup


  // -----------------------------
  // Write Data Coverage
  // -----------------------------
  covergroup cg_axi_wr_data;
    option.per_instance = 1;

    CP_WDATA: coverpoint tx.wdata {

      bins zero = {64'h0000_0000_0000_0000};
      bins ones = {64'hFFFF_FFFF_FFFF_FFFF};
      bins walking_1[] = {
        64'h0000_0000_0000_0001,
        64'h0000_0000_0000_0002,
        64'h0000_0000_0000_0004,
        64'h0000_0000_0000_0008,
        64'h0000_0000_0000_0010,
        64'h0000_0000_0000_0020,
        64'h0000_0000_0000_0040,
        64'h0000_0000_0000_0080
      };

    }
  endgroup

  // -----------------------------
  // Read Data Coverage
  // -----------------------------
  covergroup cg_axi_rd_data;

    option.per_instance = 1;

    CP_RDATA: coverpoint tx.rdata {

      bins zero = {64'h0000_0000_0000_0000};
      bins ones = {64'hFFFF_FFFF_FFFF_FFFF};

      bins walking_1[] = {
        64'h0000_0000_0000_0001,
        64'h0000_0000_0000_0002,
        64'h0000_0000_0000_0004,
        64'h0000_0000_0000_0008,
        64'h0000_0000_0000_0010,
        64'h0000_0000_0000_0020,
        64'h0000_0000_0000_0040,
        64'h0000_0000_0000_0080
      };

      bins random = default;
    }
  endgroup

  // -----------------------------
  // Subscriber write method
  // -----------------------------
  function void write_wr_req(axi_lite_item t);
    tx = t;
    cg_axi_op.sample();
    cg_axi_wr_addr.sample();
    cg_axi_wr_data.sample();
  endfunction

  function void write_wr_rsp(axi_lite_item t);
    tx = t;
    cg_axi_wr_resp.sample();
  endfunction

  function void write_rd_req(axi_lite_item t);
    tx = t;
    cg_axi_op.sample();
    cg_axi_rd_addr.sample();
  endfunction

  function void write_rd_rsp(axi_lite_item t);
    tx = t;
    cg_axi_rd_data.sample();
    cg_axi_rd_resp.sample();
  endfunction

endclass : axi_lite_coverage
