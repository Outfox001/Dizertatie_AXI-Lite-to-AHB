//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_sequencer.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb sequencer class, which is responsible for managing the flow of AHB transactions.
//  ======================================================================================================

class ahb_sequencer extends uvm_sequencer #(ahb_item, ahb_item);
    `uvm_component_utils (ahb_sequencer)

    function new (string name="ahb_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass :ahb_sequencer