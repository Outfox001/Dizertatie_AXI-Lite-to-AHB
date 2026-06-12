//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_type_def.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite types for the testbench, including enumerations for handshakes and delay types.
//  ======================================================================================================

typedef enum {
  VAL_BFR_RDY,
  RDY_BFR_VAL,
  VAL_AND_RDY
} hsk_type;

typedef enum {B2B, SHORT, MEDIUM, LONG } delay_type;