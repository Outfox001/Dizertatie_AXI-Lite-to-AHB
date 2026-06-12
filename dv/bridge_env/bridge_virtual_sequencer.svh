//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_virtual_sequencer.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the bridge virtual sequencer class, which coordinates the execution of sequences for the AHB to AXI bridge testbench.
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