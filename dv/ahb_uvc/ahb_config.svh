class ahb_config extends uvm_object;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  agent_type_t agent_type = MASTER;

  virtual ahb_if vif;

  `uvm_object_utils_begin(ahb_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active,    UVM_DEFAULT)
    `uvm_field_enum(agent_type_t,            agent_type,   UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "ahb_config");
    super.new(name);
    //Create the virtual interface
  endfunction : new

endclass : ahb_config