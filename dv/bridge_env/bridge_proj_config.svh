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
      //AXI4 Write
      m_axi_cfg.is_active  = UVM_ACTIVE;
      m_axi_cfg.agent_type = axi_lite_pkg::MASTER;
      //AXI4 Read
      m_ahb_cfg.is_active  = UVM_ACTIVE;
      m_ahb_cfg.agent_type = ahb_pkg::MASTER;
    end
    else begin
      m_axi_cfg.is_active    = UVM_PASSIVE;
      m_ahb_cfg.is_active = UVM_PASSIVE;
    end
  endfunction : build

endclass : bridge_proj_config