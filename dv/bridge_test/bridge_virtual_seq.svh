class bridge_base_vsequence extends uvm_sequence#(uvm_sequence_item);

  `uvm_object_utils(bridge_base_vsequence)

  `uvm_declare_p_sequencer(bridge_virtual_sequencer)

  function new(string name = "bridge_base_vsequence");
    super.new(name);
  endfunction : new

endclass : bridge_base_vsequence

class first_success_axi_vseq extends bridge_base_vsequence;

  `uvm_object_utils(first_success_axi_vseq)

  axi_master_sequence                wr_vseq;
  axi_read_sequence                  rd_vseq;
  ahb_first_success_slave_sequence   ahb_vseq;

  function new(string name = "first_success_axi_vseq");
    super.new(name);
  endfunction : new

  task body();
    wr_vseq = axi_master_sequence::type_id::create("wr_vseq", null);
    rd_vseq    = axi_read_sequence::type_id::create("rd_vseq", null);
    // ahb_vseq    = ahb_first_success_slave_sequence::type_id::create("ahb_vseq", null);

    begin
      first_vseq.start(p_sequencer.m_axi_seqr);
      rd_vseq.start(p_sequencer.m_axi_seqr);
      // ahb_vseq.start(p_sequencer.m_ahb_seqr);
    end
  endtask : body

endclass : first_success_axi_vseq