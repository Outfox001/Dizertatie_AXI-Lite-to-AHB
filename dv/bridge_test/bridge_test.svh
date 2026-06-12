//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_base_test.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the bridge base test class, which serves as the foundation for all bridge tests.
//  ======================================================================================================

class bridge_base_test extends uvm_test;

  `uvm_component_utils(bridge_base_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  bridge_env env;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = bridge_env::type_id::create("env", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

endclass : bridge_base_test

class first_success_write_test extends bridge_base_test;

  `uvm_component_utils(first_success_write_test)

  first_write_axi_vseq wr_vseq;

  function new(string name = "first_success_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_vseq = first_write_axi_vseq::type_id::create("wr_vseq", null);

    begin
      phase.raise_objection(this);
      wr_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : first_success_write_test


class first_success_read_test extends bridge_base_test;

  `uvm_component_utils(first_success_read_test)

  first_read_axi_vseq rd_vseq;

  function new(string name = "first_success_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    rd_vseq = first_read_axi_vseq::type_id::create("rd_vseq", null);

    begin
      phase.raise_objection(this);
      rd_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : first_success_read_test

class read_write_test extends bridge_base_test;

  `uvm_component_utils(read_write_test)

  first_read_axi_vseq  read_vseq;
  first_write_axi_vseq write_vseq;

  function new(string name = "read_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    read_vseq  = first_read_axi_vseq::type_id::create("read_vseq", null);
    write_vseq = first_write_axi_vseq::type_id::create("write_vseq", null);

    begin
      phase.raise_objection(this);
      write_vseq.start(env.m_vseqr);
      read_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 400);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : read_write_test

class wr_err_test extends bridge_base_test;

  `uvm_component_utils(wr_err_test)

  wr_err_vsequence       wr_err_vseq;

  function new(string name = "wr_err_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_err_vseq  = wr_err_vsequence::type_id::create("wr_err_vseq", null);

    begin
      phase.raise_objection(this);
      wr_err_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_err_test

class rd_err_test extends bridge_base_test;

  `uvm_component_utils(rd_err_test)

  rd_err_vsequence       rd_err_vseq;

  function new(string name = "rd_err_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    rd_err_vseq  = rd_err_vsequence::type_id::create("rd_err_vseq", null);

    begin
      phase.raise_objection(this);
      rd_err_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 1000);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : rd_err_test


class wr_rd_wlk_test extends bridge_base_test;

  `uvm_component_utils(wr_rd_wlk_test)

  wr_rd_wlk_vsequence       wr_rd_wlk_vseq;

  function new(string name = "wr_rd_wlk_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_rd_wlk_vseq  = wr_rd_wlk_vsequence::type_id::create("wr_rd_wlk_vseq", null);

    begin
      phase.raise_objection(this);
      wr_rd_wlk_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_rd_wlk_test

class rd_diff_flv_test extends bridge_base_test;

  `uvm_component_utils(rd_diff_flv_test)

  rd_diff_flv_vsequence       rd_diff_flv_vseq;

  function new(string name = "rd_diff_flv_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    rd_diff_flv_vseq  = rd_diff_flv_vsequence::type_id::create("rd_diff_flv_vseq", null);

    begin
      phase.raise_objection(this);
      rd_diff_flv_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : rd_diff_flv_test

class wr_diff_flv_test extends bridge_base_test;

  `uvm_component_utils(wr_diff_flv_test)

  wr_diff_flv_vsequence       wr_diff_flv_vseq;

  function new(string name = "wr_diff_flv_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_diff_flv_vseq  = wr_diff_flv_vsequence::type_id::create("wr_diff_flv_vseq", null);

    begin
      phase.raise_objection(this);
      wr_diff_flv_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_diff_flv_test

class wr_rd_diff_flv_test extends bridge_base_test;

  `uvm_component_utils(wr_rd_diff_flv_test)

  wr_diff_flv_vsequence       wr_diff_flv_vseq;
  rd_diff_flv_vsequence       rd_diff_flv_vseq;

  function new(string name = "wr_rd_diff_flv_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    rd_diff_flv_vseq  = rd_diff_flv_vsequence::type_id::create("rd_diff_flv_vseq", null);
    wr_diff_flv_vseq  = wr_diff_flv_vsequence::type_id::create("wr_diff_flv_vseq", null);

    begin
      phase.raise_objection(this);
      wr_diff_flv_vseq.start(env.m_vseqr);
      rd_diff_flv_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_rd_diff_flv_test

class wr_rd_0_test extends bridge_base_test;

  `uvm_component_utils(wr_rd_0_test)

  wr_rd_0_vsequence       wr_rd_0_vseq;

  function new(string name = "wr_rd_0_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_rd_0_vseq  = wr_rd_0_vsequence::type_id::create("wr_rd_0_vseq", null);

    begin
      phase.raise_objection(this);
      wr_rd_0_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_rd_0_test

class wr_rd_max_test extends bridge_base_test;

  `uvm_component_utils(wr_rd_max_test)

  wr_rd_max_vsequence       wr_rd_max_vseq;

  function new(string name = "wr_rd_max_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    wr_rd_max_vseq  = wr_rd_max_vsequence::type_id::create("wr_rd_max_vseq", null);

    begin
      phase.raise_objection(this);
      wr_rd_max_vseq.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 5500);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : wr_rd_max_test
