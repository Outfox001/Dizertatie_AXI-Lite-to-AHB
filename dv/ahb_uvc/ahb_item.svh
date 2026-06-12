//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_item.svh
//  Last modified+updates: 12/06/2026 (BTS)
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb transaction item,
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class ahb_item extends uvm_sequence_item;

  rand bit          [             31:0] hrdata;
  bit               [             31:0] hwdata;
  rand bit          [             31:0] hrdata_array[];
  bit                                   hresp;
  rand bit unsigned [              3:0] delay;
  bit                                   hwrite;
  bit                                   hready;
  bit               [              2:0] hsize;
  rand int                              burst_len;
  ahb_trans_e                           htrans;
  bit               [            31: 0] haddr;


  // Tie burst_len to hburst
  constraint c_burst_size {
    burst_len == 2;
  }

  // Arrays sized to burst_len
  constraint c_data_size {
    hrdata_array.size() == 2;
  }

  constraint c_hrdata_unique {

    foreach (hrdata_array[i]) foreach (hrdata_array[j]) if (i < j)
      hrdata_array[i] != hrdata_array[j];

  }

  function void update_burst_from_hburst();
    // burst_len = get_burst_length(hburst);

    // Resize and refill arrays
    hrdata_array = new[2];

    foreach(hrdata_array[i]) hrdata_array[i] = $urandom_range(1, 32'hFFFFFFFF);
  endfunction

  `uvm_object_utils_begin(ahb_item)
    `uvm_field_enum(ahb_trans_e, htrans, UVM_DEFAULT)
    `uvm_field_int(haddr               , UVM_DEFAULT)
    `uvm_field_int(hrdata               , UVM_DEFAULT)
    `uvm_field_int(hwdata               , UVM_DEFAULT)
    `uvm_field_int(hresp               , UVM_DEFAULT)
    `uvm_field_array_int(hrdata_array  , UVM_DEFAULT)
    `uvm_field_int(delay               , UVM_DEFAULT)
    `uvm_field_int(burst_len           , UVM_DEFAULT)
    `uvm_field_int(hwrite              , UVM_DEFAULT)
    `uvm_field_int(hready              , UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "ahb_item");
    super.new(name);
  endfunction

endclass