//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_item.svh
//  Last modified+updates: 02/03/2026 (BTS) - Initial Version
//
//  Project              : ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb transaction item,
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================
package ahb_pkg;
  import uvm_pkg::*;
  import ahb_parameter_pkg::*;

  `include "uvm_macros.svh"
  `include "ahb_type_def.svh"
  `include "ahb_item.svh"
  `include "ahb_config.svh"
  `include "ahb_driver.svh"
  `include "ahb_monitor.svh"
  `include "ahb_seqr.svh"
  `include "ahb_agent.svh"
  `include "ahb_seq.svh"
//   `include "ahb_coverage.svh"
endpackage