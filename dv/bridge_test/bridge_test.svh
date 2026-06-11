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

class first_success_test extends bridge_base_test;

  `uvm_component_utils(first_success_test)

  first_success_axi_vseq first_test;

  function new(string name = "first_success_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    first_test = first_success_axi_vseq::type_id::create("first_test", null);

    begin
      phase.raise_objection(this);
      first_test.start(env.m_vseqr);
      phase.phase_done.set_drain_time(this, 100);
      phase.drop_objection(this);
    end
  endtask : run_phase
endclass : first_success_test
