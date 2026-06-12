//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_config.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite config class, which holds configuration parameters for the AXI Lite agent.
//  ======================================================================================================

class axi_lite_config extends uvm_object;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  agent_type_t agent_type = MASTER;

  virtual axi_lite_tb_if vif;

  `uvm_object_utils_begin(axi_lite_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active,    UVM_DEFAULT)
    `uvm_field_enum(agent_type_t,            agent_type,   UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "axi_lite_config");
    super.new(name);
    //Create the virtual interface
  endfunction : new

endclass : axi_lite_config