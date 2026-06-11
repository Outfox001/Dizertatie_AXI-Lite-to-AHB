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

class ahb_base_sequence extends uvm_sequence;

  `uvm_object_utils(ahb_base_sequence)
  `uvm_declare_p_sequencer(ahb_sequencer)

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
    start_item(ahb_item_s);
    if (!(ahb_item_s.randomize() with {
          delay inside {[0 : 5]};
        }))
      `uvm_error(get_type_name(), "Rand error!")
    finish_item(ahb_item_s);
    start_item(ahb_item_s);
    if (!(ahb_item_s.randomize() with {
          delay inside {[0 : 5]};
        }))
      `uvm_error(get_type_name(), "Rand error!")
    finish_item(ahb_item_s);

    start_item(ahb_item_s);
    if (!(ahb_item_s.randomize() with {
          delay inside {[0 : 5]};
        }))
      `uvm_error(get_type_name(), "Rand error!")
    finish_item(ahb_item_s);
  endtask
endclass : ahb_first_success_slave_sequence

class ahb_slave_incremental_write_sequence extends ahb_base_sequence;

  `uvm_object_utils(ahb_slave_incremental_write_sequence)

  function new(string name = "ahb_slave_incremental_write_sequence");
    super.new(name);
  endfunction
  int tr_len;
  virtual task body();
    ahb_item ahb_item_s;
    ahb_item_s = ahb_item::type_id::create("ahb_item_s");

    `uvm_info(get_type_name(), "AHB slave sequence Start", UVM_LOW)

    for (int i = 0; i < tr_len; i++) begin
      start_item(ahb_item_s);

      if (!(ahb_item_s.randomize() with {
        delay inside {[0:1]};
      }))
        `uvm_error(get_type_name(), "Rand error!")
      finish_item(ahb_item_s);
      // get_response(ahb_item_s);
    `uvm_info("AHB slave sequence :", $sformatf(
              "SPRINT [%t] --------------->%s", $realtime, ahb_item_s.sprint()), UVM_NONE);
    end

  endtask
endclass : ahb_slave_incremental_write_sequence

