//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_config.svh
//  Last modified+updates: 12/06/2026 (BTS)
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb config class, which holds the configuration parameters for the AHB agent.
//  ======================================================================================================
class ahb_config extends uvm_object;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  virtual ahb_tb_if vif;

  `uvm_object_utils_begin(ahb_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active,    UVM_DEFAULT)
    `uvm_field_enum(agent_type_t,            agent_type,   UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "ahb_config");
    super.new(name);
    //Create the virtual interface
  endfunction : new

endclass : ahb_config