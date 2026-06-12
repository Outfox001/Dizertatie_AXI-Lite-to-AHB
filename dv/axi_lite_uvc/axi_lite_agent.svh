//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_agent.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite agent class, which is a UVM component responsible for generating and driving AXI Lite transactions,
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class axi_lite_agent extends uvm_agent;

  `uvm_component_utils (axi_lite_agent)

  // interfaces declaration (items)
  axi_lite_sequencer   m_sequencer;
  axi_lite_driver      m_drv;
  axi_lite_monitor     m_monitor;
  axi_lite_config      m_axi_cfg;

  function new (string name = "axi_lite_agent" , uvm_component parent = null); //agent constructor
    super.new (name, parent);
  endfunction: new

  //If Agent Is Active, create Driver and Sequencer, else skip
  //Always create Monitor regardless of Agent's nature

  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    if(!uvm_config_db#(axi_lite_config)::get(this, "", "m_axi_cfg", m_axi_cfg))
      `uvm_fatal("NOCONFIG", {"Config object not set for: %s", get_full_name()})

    m_monitor = axi_lite_monitor::type_id::create("m_monitor",this); // creating the monitor

    if(m_axi_cfg.is_active == UVM_ACTIVE) begin
        m_sequencer  =  axi_lite_sequencer::type_id::create("m_sequencer",this);
        m_drv        =  axi_lite_driver::type_id::create("m_drv",this);
    end

  endfunction: build_phase

  //Connecting components
  virtual function void connect_phase (uvm_phase phase);
    if(m_axi_cfg.is_active == UVM_ACTIVE)
        m_drv.seq_item_port.connect(m_sequencer.seq_item_export); //Connecting sequencer export port with the master driver port
  endfunction: connect_phase

endclass: axi_lite_agent
