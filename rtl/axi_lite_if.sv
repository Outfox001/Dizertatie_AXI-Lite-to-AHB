// ============================================================================
// AXI-Lite Interface Module
// Description: Defines the AXI-Lite port interface with all required signals
//              for the bridge master side
// ============================================================================

interface axi_lite_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 64
);

  // ==========================================================================
  // WRITE ADDRESS CHANNEL
  // ==========================================================================
  logic [ADDR_WIDTH-1:0]  awaddr;    // Write address
  logic                   awvalid;   // Write address valid
  logic                   awready;   // Write address ready

  // ==========================================================================
  // WRITE DATA CHANNEL
  // ==========================================================================
  logic [DATA_WIDTH-1:0]  wdata;     // Write data
  logic                   wvalid;    // Write data valid
  logic                   wready;    // Write data ready

  // ==========================================================================
  // WRITE RESPONSE CHANNEL
  // ==========================================================================
  logic [1:0]             bresp;     // Write response (2'b00 = OKAY)
  logic                   bvalid;    // Write response valid
  logic                   bready;    // Write response ready

  // ==========================================================================
  // READ ADDRESS CHANNEL
  // ==========================================================================
  logic [ADDR_WIDTH-1:0]  araddr;    // Read address
  logic                   arvalid;   // Read address valid
  logic                   arready;   // Read address ready

  // ==========================================================================
  // READ DATA CHANNEL
  // ==========================================================================
  logic [DATA_WIDTH-1:0]  rdata;     // Read data
  logic [1:0]             rresp;     // Read response (2'b00 = OKAY)
  logic                   rvalid;    // Read data valid
  logic                   rready;    // Read data ready

  // ==========================================================================
  // MODPORT: Slave (Bridge receives from master)
  // ==========================================================================
  modport slave (
    input  awaddr, awvalid, wdata, wvalid, bready, araddr, arvalid, rready,
    output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );

  // ==========================================================================
  // MODPORT: Master (For testbench, not used in bridge)
  // ==========================================================================
  modport master (
    output awaddr, awvalid, wdata, wvalid, bready, araddr, arvalid, rready,
    input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );

  // ==========================================================================
  // MODPORT: Monitor (For DV)
  // ==========================================================================
  modport monitor (
    input awaddr, awvalid, awready, wdata, wvalid, wready,
          bresp, bvalid, bready, araddr, arvalid, arready,
          rdata, rresp, rvalid, rready
  );

endinterface : axi_lite_if
