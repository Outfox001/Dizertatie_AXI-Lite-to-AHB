// ============================================================================
// AXI-Lite to AHB Bridge Top Module
// ============================================================================
// Description: Top-level wrapper for the complete bridge with interfaces
// ============================================================================

module axi_ahb_bridge_top #(
  parameter int ADDR_WIDTH     = 32,
  parameter int AXI_DATA_WIDTH = 64,
  parameter int AHB_DATA_WIDTH = 32,
  parameter int FIFO_DEPTH     = 16
) (
  // Clock and Reset
  input  logic                    aclk,           // AXI clock domain
  input  logic                    aresetn,        // AXI active-low reset
  input  logic                    hclk,           // AHB clock domain
  input  logic                    hresetn,        // AHB active-low reset

  // AXI-Lite Slave Interface
  axi_lite_if.slave               axi_if,         // AXI-Lite slave interface

  // AHB Master Interface
  ahb_if.master                   ahb_if          // AHB master interface
);

  import axi_ahb_pkg::*;

  // ========================================================================
  // INSTANTIATE BRIDGE CORE
  // ========================================================================

  axi_ahb_bridge_core #(
    .FIFO_DEPTH(FIFO_DEPTH)
  ) bridge_core_inst (
    // Clock and Reset
    .aclk(aclk),
    .aresetn(aresetn),
    .hclk(hclk),
    .hresetn(hresetn),

    // AXI-Lite Write Address Channel
    .awaddr(axi_if.awaddr),
    .awvalid(axi_if.awvalid),
    .awready(axi_if.awready),

    // AXI-Lite Write Data Channel
    .wdata(axi_if.wdata),
    .wvalid(axi_if.wvalid),
    .wready(axi_if.wready),

    // AXI-Lite Write Response Channel
    .bresp(axi_if.bresp),
    .bvalid(axi_if.bvalid),
    .bready(axi_if.bready),

    // AXI-Lite Read Address Channel
    .araddr(axi_if.araddr),
    .arvalid(axi_if.arvalid),
    .arready(axi_if.arready),

    // AXI-Lite Read Data Channel
    .rdata(axi_if.rdata),
    .rresp(axi_if.rresp),
    .rvalid(axi_if.rvalid),
    .rready(axi_if.rready),

    // AHB Address/Control Phase
    .haddr(ahb_if.haddr),
    .hwrite(ahb_if.hwrite),
    .hsize(ahb_if.hsize),
    .htrans(ahb_if.htrans),
    .hburst(ahb_if.hburst),

    // AHB Write Data Phase
    .hwdata(ahb_if.hwdata),

    // AHB Read Data Phase
    .hrdata(ahb_if.hrdata),
    .hresp(ahb_if.hresp),
    .hready(ahb_if.hready)
  );

endmodule : axi_ahb_bridge_top