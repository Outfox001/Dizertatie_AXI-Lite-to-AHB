//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_seq.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb sequence classes, which are responsible for generating and managing AHB transactions.
//  ======================================================================================================

class ahb_base_sequence extends uvm_sequence;

  `uvm_object_utils(ahb_base_sequence)
  `uvm_declare_p_sequencer(ahb_sequencer)

  int trans_no = 1;

  function new(string name = "ahb_base_sequence");
    super.new(name);
  endfunction : new

  virtual task body();

  endtask : body
endclass : ahb_base_sequence

// -------------------------------------------------------------------------------------------------------------------------------------------

class ahb_first_success_slave_sequence extends ahb_base_sequence;

  `uvm_object_utils(ahb_first_success_slave_sequence)

  function new(string name = "ahb_first_success_slave_sequence");
    super.new(name);
  endfunction
  virtual task body();
    ahb_item ahb_item_s;
    ahb_item_s = ahb_item::type_id::create("ahb_item_s");

    `uvm_info(get_type_name(), "AHB slave sequence Start", UVM_LOW)
    // repeat(trans_no) begin
    forever begin
      start_item(ahb_item_s);
      if (!(ahb_item_s.randomize() with {
            delay inside {[5 : 10]};
            // hrdata inside {[0 : 5]};
          }))
        `uvm_error(get_type_name(), "Rand error!")
      finish_item(ahb_item_s);
    end
  endtask
endclass : ahb_first_success_slave_sequence


