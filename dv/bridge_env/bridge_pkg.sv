//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_pkg.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file includes all the necessary components for the AHB to AXI bridge testbench.
//  ======================================================================================================

package bridge_pkg;

  import uvm_pkg::*;
  import axi_lite_pkg::*;
  import ahb_pkg::*;
  `include "uvm_macros.svh"
  `include "bridge_proj_config.svh"
  `include "bridge_virtual_sequencer.svh"
  `include "bridge_scoreboard.svh"
  `include "bridge_env.svh"

endpackage : bridge_pkg
