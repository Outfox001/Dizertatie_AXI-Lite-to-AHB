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

import ahb_parameter_pkg::*;
import ahb_pkg::*; // import this for enum type htrans_e
`include "uvm_macros.svh"

interface ahb_if #(
    parameter DATA_WIDTH    = 32, // Data width
    parameter HBURST_WIDTH  = 3

) (
    input clk,
    input reset
);

  import uvm_pkg::*;

  // ahb signals
  logic [   DATA_WIDTH-1:0] hrdata;
  logic                     hready;
  logic                     hresp;
  logic [              1:0] htrans;
  logic [ HBURST_WIDTH-1:0] hburst;

  logic [32-1:0]  haddr;
  logic           hwrite;
  logic [1:0]     htrans;
  logic [2:0]     hburst;
  logic [2:0]     hsize;
  logic [32-1:0]  hwdata;
  logic           hwstrb;

  ahb_trans_e htrans_e;
  ahb_burst_e hburst_e;
  assign htrans_e = ahb_trans_e'(htrans); // cast it so you can see text for each htrans
  assign hburst_e = ahb_burst_e'(hburst);

  // driver clocking block
  clocking cb_drv @(posedge clk);
    input  haddr;
    input  hwrite;
    input  htrans;
    input  hburst;
    input  hsize;
    input  hwdata;
    input  hwstrb;
    output hrdata;
    output hready;
    output hresp;
  endclocking : cb_drv

  // monitor clocking block
  clocking cb_mon @(posedge clk);
    input haddr;
    input hwrite;
    input htrans;
    input hburst;
    input hsize;
    input hwdata;
    input hwstrb;
    input hrdata;
    input hready;
    input hresp;
  endclocking : cb_mon

endinterface