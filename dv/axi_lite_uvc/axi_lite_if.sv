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

import axi_lite_parameter_pkg::*;
`include "uvm_macros.svh"

interface axi_lite_if #(
    parameter ADDR_WIDTH    = 32, // Addr width
    parameter DATA_WIDTH    = 64 // Data width
) (
    input clk,
    input reset
);

  import uvm_pkg::*;

  // axi read signals
  logic [   ADDR_WIDTH-1:0] araddr;
  logic                     arvalid;
  logic                     arready;
  logic [   DATA_WIDTH-1:0] rdata;
  logic                     rvalid;
  logic                     rready;
  logic [   1           :0] rresp;

  // axi write signals
  logic [   ADDR_WIDTH-1:0] awaddr;
  logic                     awvalid;
  logic                     awready;
  logic [   DATA_WIDTH-1:0] wdata;
  logic                     wvalid;
  logic                     wready;
  logic [   1           :0] bresp;
  logic                     bvalid;
  logic                     bready;


  // driver clocking block
  clocking cb_drv @(posedge clk);
    output araddr;
    output arvalid;
    input  arready;
    input  rdata;
    output rready;
    input  rvalid;
    input  rresp;
    output awaddr;
    output awvalid;
    input  awready;
    output wdata;
    output wvalid;
    input  wready;
    input  bresp;
    input  bvalid;
    output bready;
  endclocking : cb_drv

  // monitor clocking block
  clocking cb_mon @(posedge clk);
    input arvalid;
    input arready;
    input rdata;
    input rready;
    input rvalid;
    input rresp;
    input awaddr;
    input awvalid;
    input awready;
    input wdata;
    input wvalid;
    input wready;
    input bresp;
    input bvalid;
    input bready;
  endclocking : cb_mon

endinterface