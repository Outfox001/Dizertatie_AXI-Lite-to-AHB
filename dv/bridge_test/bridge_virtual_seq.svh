//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_virtual_seq.svh
//  Last modified+updates: 02/03/2026 (BTS) - Initial Version
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite_to_ahb virtual sequence,
//                         which coordinates the execution of AXI Lite and AHB sequences for the bridge testbench.
//  ======================================================================================================

class bridge_base_vsequence extends uvm_sequence#(uvm_sequence_item);

  `uvm_object_utils(bridge_base_vsequence)

  `uvm_declare_p_sequencer(bridge_virtual_sequencer)

  function new(string name = "bridge_base_vsequence");
    super.new(name);
  endfunction : new

endclass : bridge_base_vsequence

class first_write_axi_vseq extends bridge_base_vsequence;

  `uvm_object_utils(first_write_axi_vseq)

  axi_write_sequence                wr_vseq;
  ahb_first_success_slave_sequence   ahb_vseq;

  function new(string name = "first_write_axi_vseq");
    super.new(name);
  endfunction : new

  task body();
    wr_vseq   =  axi_write_sequence::type_id::create("wr_vseq", null);
    ahb_vseq  = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);

    begin
      fork
        wr_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_any
      disable fork;
    end
  endtask : body

endclass : first_write_axi_vseq

class first_read_axi_vseq extends bridge_base_vsequence;

  `uvm_object_utils(first_read_axi_vseq)

  axi_read_sequence                  rd_vseq;
  ahb_first_success_slave_sequence   ahb_vseq;

  function new(string name = "first_read_axi_vseq");
    super.new(name);
  endfunction : new

  task body();
    rd_vseq   = axi_read_sequence::type_id::create("rd_vseq", null);
    ahb_vseq  = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    begin
      fork
        rd_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_any
      disable fork;
    end
  endtask : body

endclass : first_read_axi_vseq

class wr_err_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(wr_err_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_write_err_sequence            wr_err_vseq;

  function new(string name = "wr_err_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    wr_err_vseq  = axi_write_err_sequence::type_id::create("wr_err_vseq", null);

    begin
      fork
        wr_err_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_none
    end
  endtask : body

endclass : wr_err_vsequence

class rd_err_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(rd_err_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_rd_err_sequence               rd_err_vseq;

  function new(string name = "rd_err_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    rd_err_vseq  = axi_rd_err_sequence::type_id::create("rd_err_vseq", null);

    begin
      fork
        rd_err_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_none
    end
  endtask : body

endclass : rd_err_vsequence

class wr_rd_wlk_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(wr_rd_wlk_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_wr_rd_wlk_sequence            wr_rd_wlk_vseq;

  function new(string name = "wr_rd_wlk_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    wr_rd_wlk_vseq  = axi_wr_rd_wlk_sequence::type_id::create("wr_rd_wlk_vseq", null);

    begin
      fork
        wr_rd_wlk_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_none
    end
  endtask : body

endclass : wr_rd_wlk_vsequence

class rd_diff_flv_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(rd_diff_flv_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_read_diff_flv_sequence        rd_diff_flv_vseq;

  function new(string name = "rd_diff_flv_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    rd_diff_flv_vseq  = axi_read_diff_flv_sequence::type_id::create("rd_diff_flv_vseq", null);

    begin
      fork
        rd_diff_flv_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_any
      disable fork;
    end
  endtask : body

endclass : rd_diff_flv_vsequence

class wr_diff_flv_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(wr_diff_flv_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_write_diff_flv_sequence        wr_diff_flv_vseq;

  function new(string name = "wr_diff_flv_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    wr_diff_flv_vseq  = axi_write_diff_flv_sequence::type_id::create("wr_diff_flv_vseq", null);

    begin
      fork
        wr_diff_flv_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_any
      disable fork;
    end
  endtask : body

endclass : wr_diff_flv_vsequence

class wr_rd_0_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(wr_rd_0_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_wr_rd_0_sequence              wr_rd_0_vseq;

  function new(string name = "wr_rd_0_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    wr_rd_0_vseq  = axi_wr_rd_0_sequence::type_id::create("wr_rd_0_vseq", null);

    begin
      fork
        wr_rd_0_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_any
      disable fork;
    end
  endtask : body

endclass : wr_rd_0_vsequence

class wr_rd_max_vsequence extends bridge_base_vsequence;

  `uvm_object_utils(wr_rd_max_vsequence)

  ahb_first_success_slave_sequence  ahb_vseq;
  axi_wr_rd_max_sequence            wr_rd_max_vseq;

  function new(string name = "wr_rd_max_vsequence");
    super.new(name);
  endfunction : new

  task body();
    ahb_vseq     = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);
    wr_rd_max_vseq  = axi_wr_rd_max_sequence::type_id::create("wr_rd_max_vseq", null);

    begin
      fork
        wr_rd_max_vseq.start(p_sequencer.m_axi_seqr);
        ahb_vseq.start(p_sequencer.m_ahb_seqr);
      join_none
      // disable fork;
    end
  endtask : body

endclass : wr_rd_max_vsequence
