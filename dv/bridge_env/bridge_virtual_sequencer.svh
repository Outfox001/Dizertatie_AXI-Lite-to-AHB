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

class bridge_virtual_sequencer extends uvm_sequencer;

  `uvm_component_utils(bridge_virtual_sequencer)

  axi_lite_config m_axi_config;
  ahb_config      m_ahb_config;

  //AXI Lite
  axi_lite_sequencer   m_axi_seqr;
  //AHB
  ahb_sequencer        m_ahb_seqr;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

endclass : bridge_virtual_sequencer