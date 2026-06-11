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


class ahb_agent extends uvm_agent;
   `uvm_component_utils(ahb_agent)

   function new(string name = "ahb_agent", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   ahb_driver      drv;
   ahb_monitor     mon;
   ahb_sequencer   m_sequencer;
   ahb_config      m_ahb_cfg;

   virtual function void build_phase(uvm_phase phase);
       super.build_phase (phase);
      if (!uvm_config_db#(ahb_config)::get(this, "", "m_ahb_cfg", m_ahb_cfg))
         `uvm_fatal("NOCONFIG", {"Config object not set for: %s", get_full_name()})

      if (m_ahb_cfg.is_active == UVM_ACTIVE) begin
         m_sequencer    = ahb_sequencer::type_id::create("m_sequencer", this);
         drv     = ahb_driver::type_id::create("drv", this);
         end
         mon = ahb_monitor::type_id::create("mon", this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      if (m_ahb_cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(m_sequencer.seq_item_export);
      end
   endfunction
endclass : ahb_agent