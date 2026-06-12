//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_parameter_pkg.sv
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file includes all components of the AHB UVC, such as the agent, driver, monitor, memory model, and coverage collector.
//  ======================================================================================================

package ahb_pkg;
  import uvm_pkg::*;
  import ahb_parameter_pkg::*;

  `include "uvm_macros.svh"
  `include "ahb_type_def.svh"
  `include "ahb_item.svh"
  `include "ahb_config.svh"
  `include "ahb_mem.svh"
  `include "ahb_driver.svh"
  `include "ahb_monitor.svh"
  `include "ahb_seqr.svh"
  `include "ahb_agent.svh"
  `include "ahb_seq.svh"
  `include "ahb_coverage.svh"
endpackage