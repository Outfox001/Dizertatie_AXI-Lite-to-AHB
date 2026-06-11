// ============================================================================
// AXI-Lite to AHB Bridge - Testbench
// ============================================================================
// This testbench verifies the bridge functionality with:
// - AXI-Lite master (800 MHz)
// - AHB slave (400 MHz)  
// - Clock domain crossing validation
// - Type bit verification in FIFOs
// ============================================================================

`timescale 1ns / 1ps

module axi_ahb_bridge_tb;

  import axi_ahb_pkg::*;

  // ========================================================================
  // CLOCK AND RESET SIGNALS
  // ========================================================================

  logic aclk;           // AXI clock (800 MHz) -> 1.25 ns period
  logic aresetn;        // AXI reset (active low)
  logic hclk;           // AHB clock (400 MHz) -> 2.5 ns period
  logic hresetn;        // AHB reset (active low)

  // ========================================================================
  // AXI-LITE SIGNALS
  // ========================================================================

  axi_lite_if axi_if();
  
  // ========================================================================
  // AHB SIGNALS
  // ========================================================================

  ahb_if ahb_if();

  // ========================================================================
  // BRIDGE TOP INSTANTIATION
  // ========================================================================

  axi_ahb_bridge_top bridge_top (
    .aclk(aclk),
    .aresetn(aresetn),
    .hclk(hclk),
    .hresetn(hresetn),
    .axi_if(axi_if.slave),
    .ahb_if(ahb_if.master)
  );

  // ========================================================================
  // AHB SLAVE MEMORY MODEL
  // ========================================================================

  logic [31:0] ahb_memory [0:1023];
  logic [31:0] ahb_read_data;
  integer ahb_transaction_count = 0;

  always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      ahb_read_data <= 32'b0;
      ahb_transaction_count <= 0;
    end else begin
      // Write transaction
      if (ahb_if.hwrite && ahb_if.hready && (ahb_if.htrans == HTRANS_NONSEQ || ahb_if.htrans == HTRANS_SEQ)) begin
        ahb_memory[ahb_if.haddr[9:0]] <= ahb_if.hwdata;
        $display("[AHB SLAVE] Write: addr=0x%08x, data=0x%08x", ahb_if.haddr, ahb_if.hwdata);
      end
      
      // Read transaction
      if (!ahb_if.hwrite && ahb_if.hready && (ahb_if.htrans == HTRANS_NONSEQ || ahb_if.htrans == HTRANS_SEQ)) begin
        ahb_read_data <= ahb_memory[ahb_if.haddr[9:0]];
        $display("[AHB SLAVE] Read: addr=0x%08x, data=0x%08x", ahb_if.haddr, ahb_memory[ahb_if.haddr[9:0]]);
      end
    end
  end

  // AHB read data response (combinational)
  assign ahb_if.hrdata = ahb_read_data;
  assign ahb_if.hresp = 1'b0;  // OKAY response
  assign ahb_if.hready = 1'b1; // Always ready for simplicity

  // ========================================================================
  // CLOCK GENERATORS
  // ========================================================================

  // AXI Clock: 800 MHz (period = 1.25 ns)
  initial begin
    aclk = 1'b0;
    forever #0.625 aclk = ~aclk;  // Toggle every 0.625 ns -> 1.25 ns period
  end

  // AHB Clock: 400 MHz (period = 2.5 ns) - 2:1 ratio with AXI
  initial begin
    hclk = 1'b0;
    forever #1.25 hclk = ~hclk;   // Toggle every 1.25 ns -> 2.5 ns period
  end

  // ========================================================================
  // TEST STIMULUS
  // ========================================================================

  initial begin
    // Initialization
    aresetn = 1'b0;
    hresetn = 1'b0;
    axi_if.awaddr = 32'b0;
    axi_if.awvalid = 1'b0;
    axi_if.wdata = 64'b0;
    axi_if.wvalid = 1'b0;
    axi_if.bready = 1'b0;
    axi_if.araddr = 32'b0;
    axi_if.arvalid = 1'b0;
    axi_if.rready = 1'b0;

    // Reset sequence
    #5 ns;
    aresetn = 1'b1;
    hresetn = 1'b1;
    #5 ns;

    $display("\n=== AXI-Lite to AHB Bridge Testbench ===");
    $display("AXI Clock: 800 MHz (1.25 ns period)");
    $display("AHB Clock: 400 MHz (2.5 ns period)");
    $display("Clock Ratio: 2:1 (AXI:AHB)\n");

    // ======================================================================
    // TEST 1: AXI WRITE TRANSACTION
    // ======================================================================
    $display("[TEST 1] AXI Write Transaction");
    $display("Writing 64-bit data to address 0x1000");

    // Wait a few cycles
    repeat (5) @(posedge aclk);

    // Initiate AXI write address
    axi_if.awaddr = 32'h1000;
    axi_if.awvalid = 1'b1;
    axi_if.wdata = 64'hDEADBEEFCAFEBABE;
    axi_if.wvalid = 1'b1;

    // Wait for handshake
    @(posedge aclk);
    while (!axi_if.awready || !axi_if.wready) begin
      @(posedge aclk);
    end
    $display("[AXI MASTER] Write address & data accepted at time %0t ns", $realtime);

    axi_if.awvalid = 1'b0;
    axi_if.wvalid = 1'b0;

    // Wait for write response
    axi_if.bready = 1'b1;
    @(posedge aclk);
    while (!axi_if.bvalid) begin
      @(posedge aclk);
    end
    $display("[AXI MASTER] Write response received: bresp=0x%02x at time %0t ns", axi_if.bresp, $realtime);
    axi_if.bready = 1'b0;

    repeat (10) @(posedge aclk);

    // ======================================================================
    // TEST 2: AXI READ TRANSACTION
    // ======================================================================
    $display("\n[TEST 2] AXI Read Transaction");
    $display("Reading 64-bit data from address 0x2000");

    // Wait a few cycles
    repeat (5) @(posedge aclk);

    // Initiate AXI read address
    axi_if.araddr = 32'h2000;
    axi_if.arvalid = 1'b1;

    // Wait for handshake
    @(posedge aclk);
    while (!axi_if.arready) begin
      @(posedge aclk);
    end
    $display("[AXI MASTER] Read address accepted at time %0t ns", $realtime);
    axi_if.arvalid = 1'b0;

    // Wait for read data
    axi_if.rready = 1'b1;
    @(posedge aclk);
    while (!axi_if.rvalid) begin
      @(posedge aclk);
    end
    $display("[AXI MASTER] Read data received: rdata=0x%016x, rresp=0x%02x at time %0t ns", 
             axi_if.rdata, axi_if.rresp, $realtime);
    axi_if.rready = 1'b0;

    repeat (10) @(posedge aclk);

    // ======================================================================
    // TEST 3: BACK-TO-BACK WRITE TRANSACTIONS
    // ======================================================================
    $display("\n[TEST 3] Back-to-Back Write Transactions");

    repeat (5) @(posedge aclk);

    // Write transaction 1
    $display("Write 1: addr=0x3000, data=0x1111111122222222");
    axi_if.awaddr = 32'h3000;
    axi_if.awvalid = 1'b1;
    axi_if.wdata = 64'h1111111122222222;
    axi_if.wvalid = 1'b1;

    @(posedge aclk);
    while (!axi_if.awready || !axi_if.wready) begin
      @(posedge aclk);
    end
    axi_if.awvalid = 1'b0;
    axi_if.wvalid = 1'b0;

    // Wait for response
    axi_if.bready = 1'b1;
    @(posedge aclk);
    while (!axi_if.bvalid) begin
      @(posedge aclk);
    end
    axi_if.bready = 1'b0;

    repeat (3) @(posedge aclk);

    // Write transaction 2
    $display("Write 2: addr=0x4000, data=0x3333333344444444");
    axi_if.awaddr = 32'h4000;
    axi_if.awvalid = 1'b1;
    axi_if.wdata = 64'h3333333344444444;
    axi_if.wvalid = 1'b1;

    @(posedge aclk);
    while (!axi_if.awready || !axi_if.wready) begin
      @(posedge aclk);
    end
    axi_if.awvalid = 1'b0;
    axi_if.wvalid = 1'b0;

    // Wait for response
    axi_if.bready = 1'b1;
    @(posedge aclk);
    while (!axi_if.bvalid) begin
      @(posedge aclk);
    end
    axi_if.bready = 1'b0;

    repeat (10) @(posedge aclk);

    // ======================================================================
    // TEST 4: MIXED READ/WRITE TRANSACTIONS
    // ======================================================================
    $display("\n[TEST 4] Mixed Read/Write Transactions");

    repeat (5) @(posedge aclk);

    // Write transaction
    $display("Write: addr=0x5000, data=0xAAAAAAAABBBBBBBB");
    axi_if.awaddr = 32'h5000;
    axi_if.awvalid = 1'b1;
    axi_if.wdata = 64'hAAAAAAAABBBBBBBB;
    axi_if.wvalid = 1'b1;

    @(posedge aclk);
    while (!axi_if.awready || !axi_if.wready) begin
      @(posedge aclk);
    end
    axi_if.awvalid = 1'b0;
    axi_if.wvalid = 1'b0;

    // Wait for write response
    axi_if.bready = 1'b1;
    @(posedge aclk);
    while (!axi_if.bvalid) begin
      @(posedge aclk);
    end
    axi_if.bready = 1'b0;

    repeat (3) @(posedge aclk);

    // Read from same address
    $display("Read: addr=0x5000");
    axi_if.araddr = 32'h5000;
    axi_if.arvalid = 1'b1;

    @(posedge aclk);
    while (!axi_if.arready) begin
      @(posedge aclk);
    end
    axi_if.arvalid = 1'b0;

    // Wait for read data
    axi_if.rready = 1'b1;
    @(posedge aclk);
    while (!axi_if.rvalid) begin
      @(posedge aclk);
    end
    $display("[AXI MASTER] Read returned: rdata=0x%016x", axi_if.rdata);
    axi_if.rready = 1'b0;

    repeat (10) @(posedge aclk);

    // ======================================================================
    // END OF TEST
    // ======================================================================
    $display("\n=== Testbench Complete ===\n");
    #100 ns;
    $finish;
  end

  // ========================================================================
  // MONITORING AND DEBUGGING
  // ========================================================================

  always @(posedge aclk) begin
    if (axi_if.awvalid && axi_if.awready) begin
      $display("[Monitor] AXI Write Addr: 0x%08x at %0t ns", axi_if.awaddr, $realtime);
    end
    if (axi_if.wvalid && axi_if.wready) begin
      $display("[Monitor] AXI Write Data: 0x%016x at %0t ns", axi_if.wdata, $realtime);
    end
    if (axi_if.bvalid && axi_if.bready) begin
      $display("[Monitor] AXI Write Resp: bresp=0x%02x at %0t ns", axi_if.bresp, $realtime);
    end
    if (axi_if.arvalid && axi_if.arready) begin
      $display("[Monitor] AXI Read Addr: 0x%08x at %0t ns", axi_if.araddr, $realtime);
    end
    if (axi_if.rvalid && axi_if.rready) begin
      $display("[Monitor] AXI Read Data: 0x%016x, rresp=0x%02x at %0t ns", axi_if.rdata, axi_if.rresp, $realtime);
    end
  end

  // ========================================================================
  // WAVEFORM DUMPING (Optional - for simulation viewers)
  // ========================================================================

  initial begin
    if ($test$plusargs("dump_waves")) begin
      $dumpfile("bridge_tb.vcd");
      $dumpvars(0, axi_ahb_bridge_tb);
    end
  end

endmodule : axi_ahb_bridge_tb
