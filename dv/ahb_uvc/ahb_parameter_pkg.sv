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
//  Description          : This file defines the ahb parameter values for the AHB interface.
//  ======================================================================================================

package ahb_parameter_pkg;

  parameter ADDR_WIDTH    = 32; // Addr width
  parameter DATA_WIDTH    = 32; // Data width
  parameter HBURST_WIDTH  = 3; // Hburst width

endpackage : ahb_parameter_pkg
