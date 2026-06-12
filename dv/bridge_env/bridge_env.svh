//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_env.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the bridge environment class, which contains all the components for the AHB to AXI bridge testbench.
//  ======================================================================================================

class bridge_env extends uvm_env;

  `uvm_component_utils(bridge_env)

  axi_lite_agent            m_axi_agent;
  ahb_agent                 m_ahb_agent;

  bridge_virtual_sequencer  m_vseqr;

  axi_lite_config           m_axi_config;
  ahb_config                m_ahb_cfg;

  ahb_coverage              m_ahb_cov;
  axi_lite_coverage         m_axi_lite_cov;

  bridge_scoreboard         m_bridge_sb;
  ahb_memory                m_mem;

  bridge_proj_config        m_bridge_cfg;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_bridge_cfg = new("m_bridge_cfg");
    m_bridge_cfg.is_active = UVM_ACTIVE;
    m_bridge_cfg.build();
    m_mem = ahb_memory::type_id::create("m_mem", this);

    //AXI Lite ----------
    uvm_config_db#(axi_lite_config)::set(this, "m_axi_agent*", "m_axi_cfg", m_bridge_cfg.m_axi_cfg);
    m_axi_agent = axi_lite_agent::type_id::create("m_axi_agent", this);

    //AHB ---------------
    uvm_config_db#(ahb_config)::set(this, "m_ahb_agent*", "m_ahb_cfg", m_bridge_cfg.m_ahb_cfg);
    m_ahb_agent = ahb_agent::type_id::create("m_ahb_agent", this);


    uvm_config_db#(ahb_memory)::set(this, "m_ahb_agent*", "mem", m_mem);

    uvm_config_db#(ahb_memory)::set(this, "m_ahb_agent*", "mem", m_mem);

    m_vseqr        = bridge_virtual_sequencer::type_id::create("m_vseqr", this);
    m_bridge_sb    = bridge_scoreboard::type_id::create("m_bridge_sb", this);
    m_ahb_cov      = ahb_coverage::type_id::create("m_ahb_cov", this);
    m_axi_lite_cov = axi_lite_coverage::type_id::create("m_axi_lite_cov", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //AXI Lite Seqr
    m_vseqr.m_axi_seqr = m_axi_agent.m_sequencer;
    //AHB Seqr
    m_vseqr.m_ahb_seqr = m_ahb_agent.m_sequencer;

    // Connect AXI monitor to scoreboard
      m_axi_agent.m_monitor.wr_req_port.connect(m_bridge_sb.axi_wr_req_export);
      m_axi_agent.m_monitor.wr_rsp_port.connect(m_bridge_sb.axi_wr_rsp_export);
      m_axi_agent.m_monitor.rd_req_port.connect(m_bridge_sb.axi_rd_req_export);
      m_axi_agent.m_monitor.rd_rsp_port.connect(m_bridge_sb.axi_rd_rsp_export);
    // Connect AXI monitor to coverage
      m_axi_agent.m_monitor.wr_req_port.connect(m_axi_lite_cov.wr_req);
      m_axi_agent.m_monitor.wr_rsp_port.connect(m_axi_lite_cov.wr_rsp);
      m_axi_agent.m_monitor.rd_req_port.connect(m_axi_lite_cov.rd_req);
      m_axi_agent.m_monitor.rd_rsp_port.connect(m_axi_lite_cov.rd_rsp);
    // Connect AHB monitor to scoreboard
      m_ahb_agent.mon.analysis_port.connect(m_bridge_sb.ahb_export);
      // Connect AHB monitor to coverage
      m_ahb_agent.mon.analysis_port.connect(m_ahb_cov.analysis_export);

  endfunction : connect_phase

endclass : bridge_env
