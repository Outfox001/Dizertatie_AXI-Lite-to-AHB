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


class ahb_sequencer extends uvm_sequencer #(ahb_item, ahb_item);
    `uvm_component_utils (ahb_sequencer)

    function new (string name="ahb_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass :ahb_sequencer