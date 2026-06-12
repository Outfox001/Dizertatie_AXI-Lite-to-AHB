//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_proj_config.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the bridge_proj_config class, which contains the configuration for the AHB to AXI bridge testbench.
//  ======================================================================================================

class bridge_proj_config extends uvm_object;

  axi_lite_config  m_axi_cfg;

  ahb_config       m_ahb_cfg;


  uvm_active_passive_enum is_active    = UVM_ACTIVE;
  bit                     has_checks   = 1;
  bit                     has_coverage = 1;

  `uvm_object_utils_begin(bridge_proj_config)
    `uvm_field_int(                          has_checks,   UVM_DEFAULT)
    `uvm_field_int(                          has_coverage, UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active,    UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "bridge_proj_config");
    super.new(name);
  endfunction : new

  function void build();
    m_axi_cfg    = new("m_axi_cfg");
    m_ahb_cfg = new("m_ahb_cfg");

    if(is_active == UVM_ACTIVE) begin
      //AXI_Lite Write
      m_axi_cfg.is_active  = UVM_ACTIVE;
      m_axi_cfg.agent_type = axi_lite_pkg::MASTER;
      //AXI_Lite Read
      m_ahb_cfg.is_active  = UVM_ACTIVE;
      m_ahb_cfg.agent_type = ahb_pkg::MASTER;
    end
    else begin
      m_axi_cfg.is_active = UVM_PASSIVE;
      m_ahb_cfg.is_active = UVM_PASSIVE;
    end
  endfunction : build

endclass : bridge_proj_config