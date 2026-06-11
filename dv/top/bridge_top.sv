module axi_to_ahb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi_lite_pkg::*;
  import ahb_pkg::*;
  import bridge_pkg::*;
  // import reset_pkg::*;
  import test_pkg::*;
  import axi_lite_parameter_pkg::*;
  import ahb_parameter_pkg::*;

  logic clk;
  logic reset;

  logic [   32-1:0]         araddr;
  logic                     arvalid;
  logic                     arready;
  logic [   64-1:0]         rdata;
  logic                     rvalid;
  logic                     rready;
  logic [   1   :0]         rresp;

  // axi write signals
  logic [32-1:0]            awaddr;
  logic                     awvalid;
  logic                     awready;
  logic [64-1:0]            wdata;
  logic                     wvalid;
  logic                     wready;
  logic [1   :0]            bresp;
  logic                     bvalid;
  logic                     bready;

  logic [32-1:0]  haddr;
  logic           hwrite;
  logic [1:0]     htrans;
  logic [2:0]     hburst;
  logic [2:0]     hsize;
  logic [32-1:0]  hwdata;
  logic           hwstrb;

  // Reset interface
  // reset_interface #(.AGENT_NAME("reset_agent")) i_reset_if (.clk(clk));

  // Single shared ready-valid interface
  ahb_if #(
  ) i_ahb_if (
      .clk  (clk),
      .reset(reset)
  );

  axi_lite_if #(
  ) i_axi_lite_if (
      .clk  (clk),
      .reset(reset)
  );


  // Clock generation
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  initial begin
    reset = 1'b1;
    #20
    reset = 1'b0;
    #10
    reset = 1'b1;
  end


initial begin
  // Wait for reset deassertion
  @(negedge reset);
  @(posedge clk);

  // -------------------------------------------------------
  // WRITE ADDRESS CHANNEL (AW)
  // -------------------------------------------------------
  i_axi_lite_if.awready = 1'b1;   // Always ready for address

  // -------------------------------------------------------
  // WRITE DATA CHANNEL (W)
  // -------------------------------------------------------
  i_axi_lite_if.wready = 1'b1;

  // -------------------------------------------------------
  // WRITE RESPONSE (B)
  // -------------------------------------------------------
  // Generate BVALID after some delay when AW/W complete
  forever begin
    @(posedge clk);
    if (i_axi_lite_if.awvalid && i_axi_lite_if.wvalid) begin
      // After handshake, respond with OKAY
      repeat (2) @(posedge clk);
      i_axi_lite_if.bvalid = 1'b1;
      i_axi_lite_if.bresp  = 2'b00;  // OKAY response

      // Wait for BREADY
      wait (i_axi_lite_if.bready);
      @(posedge clk);
      i_axi_lite_if.bvalid = 1'b0;
    end
  end
end


// -------------------------------------------------------
// READ CHANNEL STIMULUS
// -------------------------------------------------------
initial begin
  i_axi_lite_if.arready = 1'b1; // Always ready to accept a read address
  i_axi_lite_if.rvalid  = 1'b0;
  i_axi_lite_if.rdata   = '0;
  i_axi_lite_if.rresp   = 2'b00; // OKAY

  forever begin
    @(posedge clk);

    // When a read address arrives
    if (i_axi_lite_if.arvalid && i_axi_lite_if.arready) begin
      // Return data after 2 cycles
      repeat (2) @(posedge clk);

      i_axi_lite_if.rvalid = 1'b1;
      i_axi_lite_if.rdata  = $random(); // Example data pattern

      // Wait for handshake
      wait (i_axi_lite_if.rready);
      @(posedge clk);
      i_axi_lite_if.rvalid = 1'b0;
    end
  end
end


//-------------------------------------------------------------
// AHB MASTER STIMULUS (inside top module)
//-------------------------------------------------------------

initial begin
  // reset defaults
  i_ahb_if.haddr  = '0;
  i_ahb_if.htrans = 2'b00;   // IDLE
  i_ahb_if.hwrite = 1'b0;
  i_ahb_if.hsize  = 3'b010;  // 32-bit
  i_ahb_if.hburst = 3'b000;  // SINGLE
  // i_ahb_if.hprot  = 4'b0011; // data, non-cacheable
  i_ahb_if.hwdata = '0;

  @(negedge reset);
  @(posedge clk);

  // ---------------------------------------------------------
  // WRITE TRANSFER
  // ---------------------------------------------------------
  $display("[%0t] Starting AHB WRITE", $time);

  // Address phase
  i_ahb_if.haddr  <= 32'h0000_0100;
  i_ahb_if.hwrite <= 1;
  i_ahb_if.htrans <= 2'b10; // NONSEQ
  i_ahb_if.hwdata <= 32'hABCD;

  // Wait for slave ready
  @(posedge clk);
  wait (i_ahb_if.hready);

  // Return to IDLE
  i_ahb_if.htrans <= 2'b00;

  // ---------------------------------------------------------
  // READ TRANSFER
  // ---------------------------------------------------------
  repeat (5) @(posedge clk);

  $display("[%0t] Starting AHB READ", $time);

  // Address phase
  i_ahb_if.haddr  <= 32'h0000_0200;
  i_ahb_if.hwrite <= 0;
  i_ahb_if.htrans <= 2'b10; // NONSEQ

  // Wait for data phase
  @(posedge clk);
  wait (i_ahb_if.hready);

  $display("[%0t] AHB READ DATA = 0x%08h", $time, i_ahb_if.hrdata);

  // Return to idle
  i_ahb_if.htrans <= 2'b00;

  //----------------------------------------------------------
  // ADD MORE TRANSACTIONS IF NEEDED
  //----------------------------------------------------------
  repeat (20) @(posedge clk);
  $display("[%0t] AHB stimulus finished", $time);

end



  // UVM configuration and test launch
  initial begin
    // Configure interfaces using agent instance names
    // Pattern: "uvm_test_top.env.<agent_instance_name>.*"
    uvm_config_db#(virtual ahb_if)::set(uvm_root::get(), "*.m_ahb_agent.*","vif", i_ahb_if);
    uvm_config_db#(virtual axi_lite_if)::set(uvm_root::get(), "*.m_axi_agent.*", "vif_axi", i_axi_lite_if);
    // Start test
    run_test("first_success_test");
  end



endmodule
