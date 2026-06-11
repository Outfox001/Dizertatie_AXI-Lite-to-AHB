// ============================================================================
// AHB Interface Module
// Description: Defines the AHB port interface with all required signals
//              for the bridge slave side
// ============================================================================

interface ahb_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  // ==========================================================================
  // ADDRESS/CONTROL PHASE SIGNALS
  // ==========================================================================
  logic [ADDR_WIDTH-1:0]  haddr;      // Address bus
  logic                   hwrite;     // Write enable (1=write, 0=read)
  logic [2:0]             hsize;      // Transfer size (000=8b, 001=16b, 010=32b, etc.)
  logic [1:0]             htrans;     // Transfer type (00=IDLE, 01=BUSY, 10=NONSEQ, 11=SEQ)
  logic [2:0]             hburst;     // Burst type (000=SINGLE, 001=INCR, etc.)

  // ==========================================================================
  // WRITE DATA PHASE SIGNALS
  // ==========================================================================
  logic [DATA_WIDTH-1:0]  hwdata;     // Write data bus

  // ==========================================================================
  // READ DATA PHASE SIGNALS
  // ==========================================================================
  logic [DATA_WIDTH-1:0]  hrdata;     // Read data bus
  logic                   hresp;      // Transfer response (0=OKAY, 1=ERROR)
  logic                   hready;     // Transfer ready/done

  // ==========================================================================
  // MODPORT: Master (Bridge is AHB master, initiates transactions)
  // ==========================================================================
  modport master (
    output haddr, hwrite, hsize, htrans, hburst, hwdata,
    input  hrdata, hresp, hready
  );

  // ==========================================================================
  // MODPORT: Slave (For AHB slave/memory subsystem)
  // ==========================================================================
  modport slave (
    input  haddr, hwrite, hsize, htrans, hburst, hwdata,
    output hrdata, hresp, hready
  );

  // ==========================================================================
  // MODPORT: Monitor (For DV)
  // ==========================================================================
  modport monitor (
    input haddr, hwrite, hsize, htrans, hwdata,
          hrdata, hresp, hready
  );

endinterface : ahb_if
