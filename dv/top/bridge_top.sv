//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_top.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite_to_ahb top module,
//                         encapsulating the integration of AXI Lite and AHB interfaces.
//  ======================================================================================================

module axi_to_ahb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi_lite_pkg::*;
  import ahb_pkg::*;
  import bridge_pkg::*;
  import test_pkg::*;
  import axi_lite_parameter_pkg::*;
  import ahb_parameter_pkg::*;


  bit axi_clk;
  bit ahb_clk;
  bit rst_n;


axi_lite_tb_if #(
  .ADDR_WIDTH(32),
  .DATA_WIDTH(64)
) i_axi_lite_if (
  .clk    (axi_clk),
  .rst_n (rst_n)
);

ahb_tb_if #(
  .ADDR_WIDTH(32),
  .DATA_WIDTH(32)
) i_ahb_if (
  .clk    (ahb_clk),
  .rst_n (rst_n)
);


  // ========================================================================
  // RTL MODULE INSTANTIATION (NO modports)
  // ========================================================================

axi_ahb_bridge_top rtl_inst (
  .aclk    (axi_clk),
  .aresetn (rst_n),
  .hclk    (ahb_clk),
  .hresetn (rst_n),
  .axi_if  (i_axi_lite_if),
  .ahb_if  (i_ahb_if)
);



// AXI clock: 800 MHz
  initial begin
    axi_clk = 1'b0;
    forever #0.625ns axi_clk = ~axi_clk;
  end

  // AHB clock: 400 MHz
  initial begin
    ahb_clk = 1'b0;
    forever #1.25ns ahb_clk = ~ahb_clk;
  end

  initial begin
      rst_n = 0;
      #50ns;
      rst_n = 1;
      #200ns;
      rst_n = 0;
      #50ns;
      rst_n = 1;
  end

  // UVM configuration and test launch
  initial begin
    // Configure interfaces using agent instance names
    // Pattern: "uvm_test_top.env.<agent_instance_name>.*"
    uvm_config_db#(virtual ahb_tb_if)::set(uvm_root::get(), "*.m_ahb_agent.*","vif", i_ahb_if);
    uvm_config_db#(virtual axi_lite_tb_if)::set(uvm_root::get(), "*.m_axi_agent.*", "vif_axi", i_axi_lite_if);
    // Start test
    run_test("first_success_read_test");
    // run_test("first_success_write_test");
    // run_test("read_write_test");
    // run_test("wr_err_test");
    // run_test("rd_err_test");
    // run_test("wr_wlk_test");
    // run_test("wr_rd_wlk_test");
    // run_test("wr_rd_max_test");
    // run_test("wr_rd_0_test");
    // run_test("wr_rd_diff_flv_test");
    // run_test("wr_diff_flv_test");
    // run_test("rd_diff_flv_test");
  end

endmodule
