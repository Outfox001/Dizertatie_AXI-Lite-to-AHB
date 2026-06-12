//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_tb_if.sv
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite interface for the testbench, including signal declarations and protocol assertions.
//  ======================================================================================================

import axi_lite_parameter_pkg::*;
`include "uvm_macros.svh"

interface axi_lite_tb_if #(
    parameter ADDR_WIDTH    = 32, // Addr width
    parameter DATA_WIDTH    = 64 // Data width
) (
    input clk,
    input rst_n
);

  import uvm_pkg::*;

  // axi read signals
  bit [   ADDR_WIDTH-1:0] araddr;
  bit                     arvalid;
  bit                     arready;
  bit [   DATA_WIDTH-1:0] rdata;
  bit                     rvalid;
  bit                     rready;
  bit [   1           :0] rresp;

  // axi write signals
  bit [   ADDR_WIDTH-1:0] awaddr;
  bit                     awvalid;
  bit                     awready;
  bit [   DATA_WIDTH-1:0] wdata;
  bit                     wvalid;
  bit                     wready;
  bit [   1           :0] bresp;
  bit                     bvalid;
  bit                     bready;


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
    input araddr;
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

// ------------------------------------------------------------
// AXI4-Lite Protocol Assertions (ACTIVE-LOW rst_n)
// ------------------------------------------------------------

// Handshake helpers
wire ar_hs = arvalid && arready;
wire r_hs  = rvalid  && rready;

wire aw_hs = awvalid && awready;
wire w_hs  = wvalid  && wready;
wire b_hs  = bvalid  && bready;


// ------------------------------------------------------------
// VALID must stay high until READY, payload stable
// ------------------------------------------------------------
property p_hold_until_ready(valid, ready, payload);
  @(posedge clk) disable iff (!rst_n)
    (valid && !ready) |=> (valid && $stable(payload)) until_with (valid && ready);
endproperty

// Apply to all channels
a_ar_hold: assert property (p_hold_until_ready(arvalid, arready, araddr)) else `uvm_error("[%0t] AR channel violation", $time);

a_aw_hold: assert property (p_hold_until_ready(awvalid, awready, awaddr)) else `uvm_error("[%0t] AW channel violation", $time);

a_w_hold : assert property (p_hold_until_ready(wvalid, wready, wdata)) else `uvm_error("[%0t] W channel violation", $time);

a_r_hold : assert property (p_hold_until_ready(rvalid, rready, {rdata, rresp})) else `uvm_error("[%0t] R channel violation", $time);

a_b_hold : assert property (p_hold_until_ready(bvalid, bready, bresp)) else `uvm_error("[%0t] B channel violation", $time);


// ------------------------------------------------------------
// VALID must be LOW during rst_n (active-low)
// ------------------------------------------------------------
a_valid_rst_n:
  assert property (@(posedge clk)
    !rst_n |-> (!arvalid && !awvalid && !wvalid && !rvalid && !bvalid)
  )
  else `uvm_error("[%0t] VALID high during rst_n", $time);

// ------------------------------------------------------------
// No X/Z on control signals
// ------------------------------------------------------------
a_no_x_ctrl:
  assert property (@(posedge clk) disable iff (!rst_n)
    !$isunknown({
      arvalid, arready,
      rvalid,  rready,
      awvalid, awready,
      wvalid,  wready,
      bvalid,  bready
    })
  )
  else `uvm_error("[%0t] X/Z on control signals", $time);


// ------------------------------------------------------------
// Payload must be known when VALID is high
// ------------------------------------------------------------
a_araddr_known:
  assert property (@(posedge clk) disable iff (!rst_n)
    arvalid |-> !$isunknown(araddr)
  );

a_awaddr_known:
  assert property (@(posedge clk) disable iff (!rst_n)
    awvalid |-> !$isunknown(awaddr)
  );

a_wdata_known:
  assert property (@(posedge clk) disable iff (!rst_n)
    wvalid |-> !$isunknown(wdata)
  );

a_r_known:
  assert property (@(posedge clk) disable iff (!rst_n)
    rvalid |-> !$isunknown({rdata, rresp})
  );

a_b_known:
  assert property (@(posedge clk) disable iff (!rst_n)
    bvalid |-> !$isunknown(bresp)
  );


// ------------------------------------------------------------
// Response legality (AXI4-Lite forbids EXOKAY = 2'b01)
// ------------------------------------------------------------
a_rresp_legal:
  assert property (@(posedge clk) disable iff (!rst_n)
    rvalid |-> (rresp inside {2'b00, 2'b10, 2'b11})
  )
  else `uvm_error("[%0t] Illegal RRESP", $time);

a_bresp_legal:
  assert property (@(posedge clk) disable iff (!rst_n)
    bvalid |-> (bresp inside {2'b00, 2'b10, 2'b11})
  )
  else `uvm_error("[%0t] Illegal BRESP", $time);


// ------------------------------------------------------------
// Outstanding transaction tracking (AXI-Lite = single)
// ------------------------------------------------------------
logic [4:0] rd_outstanding; // can count up to 16 rd_pending;
logic [4:0] aw_outstanding;
logic [4:0] w_outstanding;

logic [4:0] rd_next;
logic [4:0] aw_next;
logic [4:0] w_next;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rd_outstanding <= 0;
    aw_outstanding <= 0;
    w_outstanding  <= 0;
  end
  else begin

    // ---------------------------------------------------------
    // GLOBAL X-GUARD (applies to ALL channels)
    // ---------------------------------------------------------
    if (!$isunknown({
        arvalid, arready, rvalid, rready,
        awvalid, awready, wvalid, wready,
        bvalid,  bready
    })) begin

      // =========================================================
      // READ CHANNEL
      // =========================================================
      rd_next = rd_outstanding + (arvalid && arready)
                               - (rvalid  && rready);

      assert (rd_next <= 16)
        else `uvm_error("AXI_RD_OUT",$sformatf("[%0t] AXI violation: read outstanding > 16 (next = %0d)",$time, rd_next));

      assert (!(rvalid && (rd_outstanding == 0)))
        else `uvm_error("AXI_RD_ORDER", $sformatf("[%0t] AXI violation: RVALID without AR", $time));
      rd_outstanding <= rd_next;

      // =========================================================
      // WRITE ADDRESS CHANNEL
      // =========================================================
      aw_next = aw_outstanding + (awvalid && awready)
                               - (bvalid  && bready);

      assert (aw_next <= 16)
        else `uvm_error("AXI_AW_OUT",$sformatf("[%0t] AXI violation: AW outstanding > 16 (next=%0d)",$time, aw_next));
      aw_outstanding <= aw_next;

      // =========================================================
      // WRITE DATA CHANNEL
      // =========================================================
      w_next = w_outstanding + (wvalid && wready)
                             - (bvalid && bready);

      assert (w_next <= 16)
        else `uvm_error("AXI_W_OUT",$sformatf("[%0t] AXI violation: W outstanding > 16 (next=%0d)",$time, w_next));
      w_outstanding <= w_next;

      // =========================================================
      // WRITE RESPONSE ORDERING
      // =========================================================
      assert (!(bvalid && (aw_outstanding == 0 || w_outstanding == 0)))
        else `uvm_error("AXI_B_ORDER",$sformatf("[%0t] AXI violation: BVALID without AW+W", $time));
    end
  end
end

endinterface : axi_lite_tb_if