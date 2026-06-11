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

class axi_lite_sequencer extends uvm_sequencer#(axi_lite_item);

  `uvm_component_utils(axi_lite_sequencer)

  axi_lite_config m_axi_cfg;
  // uvm_analysis_export #(axi_lite_item) request_export;
  uvm_tlm_analysis_fifo #(axi_lite_item) request_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // request_export = new("request_export" , this);
    request_fifo   = new("request_fifo" , this);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(axi_lite_config)::get(this, "", "m_axi_cfg", m_axi_cfg))
      `uvm_fatal("NOCONFIG", {"Config object not set for: %s", get_full_name()})
  endfunction : build_phase



endclass : axi_lite_sequencer
