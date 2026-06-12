///  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_tb_if.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb testbench interface.
//  ======================================================================================================

import ahb_parameter_pkg::*;
import ahb_pkg::*; // import this for enum type htrans_e
`include "uvm_macros.svh"

interface ahb_tb_if #(
    parameter DATA_WIDTH    = 32, // Data width
    parameter ADDR_WIDTH    = 32, // Address width
    parameter HBURST_WIDTH  = 3

) (
    input clk,
    input rst_n
);

  import uvm_pkg::*;

  // ahb signals
  logic [  DATA_WIDTH-1:0] hrdata;
  logic                    hready;
  logic                    hwrite;
  logic                    hresp;
  logic [             1:0] htrans;
  logic [  ADDR_WIDTH-1:0] haddr;
  logic [             2:0] hsize;
  logic [  DATA_WIDTH-1:0] hwdata;


  // driver clocking block
  clocking cb_drv @(posedge clk);
    input  haddr;
    input  hwrite;
    input  htrans;
    input  hsize;
    input  hwdata;
    output hrdata;
    output hready;
    output hresp;
  endclocking : cb_drv

  // monitor clocking block
  clocking cb_mon @(posedge clk);
    input haddr;
    input hwrite;
    input htrans;
    input hsize;
    input hwdata;
    input hrdata;
    input hready;
    input hresp;
  endclocking : cb_mon

  // ------------------------------------------------------------
  // Address phase beat counter (tracks only address phases)
  // ------------------------------------------------------------
  logic [1:0] addr_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_count <= 0;
    end
    else begin
      if (!$isunknown({htrans, hready})) begin
        // Start of transfer (NONSEQ)
        if (hready && (htrans == 2'b10)) begin
          addr_count <= 1;
        end
        // Second beat (SEQ)
        else if (hready && (htrans == 2'b11)) begin
          addr_count <= addr_count + 1;
        end
        // Any other case → rst_n
        else if (hready) begin
          addr_count <= 0;
        end
      end
    end
  end

  // ------------------------------------------------------------
  // 1. Only NONSEQ and SEQ allowed
  // ------------------------------------------------------------
  a_only_valid_trans:
    assert property (@(posedge clk) disable iff (!rst_n)
      (hready) |-> (htrans inside {2'b00 ,2'b10, 2'b11})
    )
  else `uvm_error("AHB_HTRANS",$sformatf("[%0t] Illegal HTRANS (only NONSEQ/SEQ allowed), htrans = %b", $time, htrans));



  // ------------------------------------------------------------
  // 2. First address phase must be NONSEQ
  // ------------------------------------------------------------
  a_first_nonseq:
    assert property (@(posedge clk) disable iff (!rst_n)
      (hready && addr_count == 0 && (htrans inside {2'b10,2'b11}))|-> (htrans == 2'b10)
    )
  else `uvm_error("AHB_FIRST", $sformatf("[%0t] First address must be NONSEQ", $time));

  // ------------------------------------------------------------
  // 3. Second address phase must be SEQ
  // ------------------------------------------------------------
  a_second_seq:
  assert property (@(posedge clk) disable iff (!rst_n)
    (hready && addr_count == 1)|-> (htrans == 2'b11)
  )
  else `uvm_error("AHB_SECOND", $sformatf("[%0t] Second address must be SEQ", $time));

  // ------------------------------------------------------------
  // 4. No more than 2 address phases
  // ------------------------------------------------------------
  a_max_two_beats:
  assert property (@(posedge clk) disable iff (!rst_n)
    addr_count <= 2
  )
  else `uvm_error("AHB_LEN", $sformatf("[%0t] More than 2 address phases detected", $time));

  // ------------------------------------------------------------
  // 5. Control signals must remain stable when HREADY = 0
  // ------------------------------------------------------------
  a_ctrl_stable:
  assert property (@(posedge clk) disable iff (!rst_n)
    !hready |=> $stable({haddr, hwrite, htrans, hsize})
  )
  else `uvm_error("AHB_STABLE", $sformatf("[%0t] Control changed while HREADY=0", $time));


  // ------------------------------------------------------------
  // 6. Write data must be valid in DATA phase (next cycle)
  // ------------------------------------------------------------
  a_write_pipeline:
  assert property (@(posedge clk) disable iff (!rst_n)
    (hready && hwrite && (htrans inside {2'b10,2'b11})) |=> !$isunknown(hwdata)
  )
  else `uvm_error("AHB_WDATA", $sformatf("[%0t] Write data not valid in data phase", $time));

  // ------------------------------------------------------------
  // 7. Read data must be valid in DATA phase (next cycle)
  // ------------------------------------------------------------
  a_read_pipeline:
  assert property (@(posedge clk) disable iff (!rst_n)
    (hready && !hwrite && (htrans inside {2'b10,2'b11})) |=> !$isunknown(hrdata)
  )
  else `uvm_error("AHB_RDATA", $sformatf("[%0t] Read data not valid in data phase", $time));

  // ------------------------------------------------------------
  // 8. No X/Z on key signals during operation
  // ------------------------------------------------------------
  a_no_x:
  assert property (@(posedge clk) disable iff (!rst_n)
    !$isunknown({
      haddr, hwrite, htrans, hsize,
      hwdata, hrdata, hready, hresp
    })
  )
  else `uvm_error("AHB_X", $sformatf("[%0t] X/Z detected on AHB signals", $time));


endinterface