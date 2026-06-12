//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_pkg.sv
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite package,
//                        encapsulating all components, items, sequences, and configurations related to the AXI-Lite UVC.
//  ======================================================================================================

package axi_lite_pkg;
  import uvm_pkg::*;
  //compiled in order
  `include "uvm_macros.svh"
  `include "axi_lite_type_def.svh"
  `include "axi_lite_item.svh"
  `include "axi_lite_config.svh"
  `include "axi_lite_driver.svh"
  `include "axi_lite_monitor.svh"
  `include "axi_lite_seqr.svh"
  `include "axi_lite_agent.svh"
  `include "axi_lite_seq.svh"
  `include "axi_lite_coverage.svh"

endpackage: axi_lite_pkg
