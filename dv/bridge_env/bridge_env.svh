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

class bridge_env extends uvm_env;

  `uvm_component_utils(bridge_env)

  axi_lite_agent            m_axi_agent;
  ahb_agent                 m_ahb_agent;

  bridge_virtual_sequencer  m_vseqr;

  axi_lite_config           m_axi_config;
  ahb_config                m_ahb_cfg;

  bridge_proj_config        m_bridge_cfg;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_bridge_cfg = new("m_bridge_cfg");
    m_bridge_cfg.is_active = UVM_ACTIVE;
    m_bridge_cfg.build();

    //AXI Lite ----------
    uvm_config_db#(axi_lite_config)::set(this, "m_axi_agent*", "m_axi_cfg", m_bridge_cfg.m_axi_cfg);
    m_axi_agent = axi_lite_agent::type_id::create("m_axi_agent", this);

    //AHB ---------------
    uvm_config_db#(ahb_config)::set(this, "m_ahb_agent*", "m_ahb_cfg", m_bridge_cfg.m_ahb_cfg);
    m_ahb_agent = ahb_agent::type_id::create("m_ahb_agent", this);

    m_vseqr = bridge_virtual_sequencer::type_id::create("m_vseqr", this);
    // m_ahb_vseqr = bridge_virtual_sequencer::type_id::create("m_ahb_vseqr", this);

    //m_axi4wr_sb    = axi4wr_scoreboard::type_id::create("m_axi4wr_sb", this);
    //m_axi4wr_sb.m_wr_config = m_axi4_cfg;

  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //AXI Lite Seqr
    m_vseqr.m_axi_seqr = m_axi_agent.m_sequencer;
    //AHB Seqr
    m_vseqr.m_ahb_seqr = m_ahb_agent.m_sequencer;
  endfunction : connect_phase

endclass : bridge_env
