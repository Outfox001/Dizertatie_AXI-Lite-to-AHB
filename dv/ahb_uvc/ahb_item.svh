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


class ahb_item extends uvm_sequence_item;


  rand bit          [             31:0] hrdata;
  rand bit          [             31:0] hrdata_array[];
  bit                                   hresp;
  rand ahb_burst_e                      hburst;
  rand bit unsigned [              3:0] delay;
  bit                                   hwrite;
  bit               [              2:0] hsize;
  bit               [              2:0] hwstrb;
  rand int                              burst_len;
  bit               [            1 :0 ] htrans;
  bit               [            31: 0] haddr;

  // Solve order to avoid circular dependency
  constraint c_solve_order {
    solve hburst before burst_len;
    solve burst_len before hrdata_array;
  }

  // Tie burst_len to hburst
  constraint c_burst_size {
    burst_len == get_burst_length(hburst);
  }

  // Arrays sized to burst_len
  constraint c_data_size {
    hrdata_array.size() == burst_len;
  }

  constraint c_hrdata_unique {

    foreach (hrdata_array[i]) foreach (hrdata_array[j]) if (i < j)
      hrdata_array[i] != hrdata_array[j];

  }

  function void update_burst_from_hburst();
    burst_len = get_burst_length(hburst);

    // Resize and refill arrays
    hrdata_array = new[burst_len];

    foreach(hrdata_array[i]) hrdata_array[i] = $urandom_range(1, 32'hFFFFFFFF);
  endfunction

  `uvm_object_utils_begin(ahb_item)
    `uvm_field_enum(ahb_trans_e, htrans, UVM_DEFAULT)
    `uvm_field_enum(ahb_burst_e, hburst, UVM_DEFAULT)
    `uvm_field_int(haddr               , UVM_DEFAULT)
    `uvm_field_array_int(hrdata_array  , UVM_DEFAULT)
    `uvm_field_int(delay               , UVM_DEFAULT)
    `uvm_field_int(burst_len           , UVM_DEFAULT)
    `uvm_field_int(hwrite              , UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "ahb_item");
    super.new(name);
  endfunction

  static function int get_burst_length(ahb_burst_e burst);
    case (burst)
      SINGLE:   return 1;
      INCR4,
      WRAP4:    return 4;
      INCR8,
      WRAP8:    return 8;
      INCR16,
      WRAP16:   return 16;
      default:  return 1;
    endcase
  endfunction
endclass