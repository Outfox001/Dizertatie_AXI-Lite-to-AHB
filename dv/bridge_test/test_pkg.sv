//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : test_pkg.sv
//  Last modified+updates: 02/03/2026 (BTS) - Initial Version
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file includes the test package for the AHB to AXI bridge testbench, which contains all necessary imports and includes for the test sequences and environment.
//  ======================================================================================================

package test_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import axi_lite_pkg::*;
  import ahb_pkg::*;
  import bridge_pkg::*;
  `include "bridge_virtual_seq.svh"
  `include "bridge_test.svh"
endpackage
