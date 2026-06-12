///  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_type_def.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb type definitions.
//  ======================================================================================================

typedef enum logic [1:0] {
  NONSEQ  = 2'b10,
  SEQ     = 2'b11
} ahb_trans_e;

