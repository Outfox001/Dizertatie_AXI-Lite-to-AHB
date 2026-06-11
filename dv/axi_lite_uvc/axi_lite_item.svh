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

class axi_lite_item extends uvm_sequence_item;

  //Write address
  rand bit [32 -1:0]    awaddr;

  //Transaction Write data
  rand bit [64 -1:0]    wdata;

  //Transaction write resp
  rand bit [    1:0]    bresp;

  //Read address
  rand bit [32 -1:0]    araddr;

  //Transaction read data
  rand bit [64 -1:0]    rdata;
  rand bit [    1:0]    rresp;

  bit      [4-1  :0]    id;

  rand bit              row;

  rand bit [9:0]        trans_delay;

  rand bit [9:0]        addr_val_rdy_dly;
  rand bit [9:0]        addr_rdy_val_dly;

  rand bit [9:0]        data_val_rdy_dly;
  rand bit [9:0]        data_rdy_val_dly;

  rand bit [9:0]        resp_rdy_val_dly;
  rand bit [9:0]        resp_val_rdy_dly;
  //delay types declaration
  rand delay_type       trans_delay_type;
  rand delay_type       addr_delay_type ;
  rand delay_type       data_delay_type ;
  rand delay_type       resp_delay_type ;

  rand hsk_type         addr_hsk_type;
  rand hsk_type         data_hsk_type;
  rand hsk_type         resp_hsk_type;


  constraint c_addr_size{
    awaddr%8 == 0;
    araddr%8 == 0;
  };

//Constraint for transaction delay
  constraint c_trans_delay {
    solve trans_delay_type before trans_delay;
    (trans_delay_type == B2B)    -> trans_delay == 0;
    (trans_delay_type == SHORT)  -> trans_delay inside {[1: 10]};
    (trans_delay_type == MEDIUM) -> trans_delay inside {[10: 100]};
    (trans_delay_type == LONG)   -> trans_delay inside {[100: 1000]};
  };

//Constraint for address channel transactions delay
  constraint c_addr_trans_delay {
    solve addr_delay_type before addr_val_rdy_dly,addr_rdy_val_dly;
    (addr_delay_type == B2B)    -> addr_val_rdy_dly == 0 &&
                              addr_rdy_val_dly == 0;
    (addr_delay_type == SHORT)  -> addr_val_rdy_dly inside {[1: 10]} &&
                              addr_rdy_val_dly inside {[1: 10]};
    (addr_delay_type == MEDIUM) -> addr_val_rdy_dly inside {[10: 100]} &&
                              addr_rdy_val_dly inside {[10: 100]};
    (addr_delay_type == LONG)   -> addr_val_rdy_dly inside {[100: 1000]} &&
                              addr_rdy_val_dly inside {[100: 1000]};
  };
//Constraint for data channel transactions delay
  constraint c_data_trans_delay {
    solve data_delay_type before data_val_rdy_dly,data_rdy_val_dly;
    (data_delay_type == B2B)    -> data_val_rdy_dly == 0 &&
                              data_rdy_val_dly == 0;
    (data_delay_type == SHORT)  -> data_val_rdy_dly inside {[1: 10]} &&
                              data_rdy_val_dly inside {[1: 10]};
    (data_delay_type == MEDIUM) -> data_val_rdy_dly inside {[10: 100]} &&
                              data_rdy_val_dly inside {[10: 100]};
    (data_delay_type == LONG)   -> data_val_rdy_dly inside {[100: 1000]} &&
                              data_rdy_val_dly inside {[100: 1000]};
  };
//Constraint for response channel transactions delay
  constraint c_resp_trans_delay {
    solve resp_delay_type before resp_val_rdy_dly,resp_rdy_val_dly;
    (resp_delay_type == B2B)    -> resp_val_rdy_dly == 0 &&
                              resp_rdy_val_dly == 0;
    (resp_delay_type == SHORT)  -> resp_val_rdy_dly inside {[1: 10]} &&
                              resp_rdy_val_dly inside {[1: 10]};
    (resp_delay_type == MEDIUM) -> resp_val_rdy_dly inside {[10: 100]} &&
                              resp_rdy_val_dly inside {[10: 100]};
    (resp_delay_type == LONG)   -> resp_val_rdy_dly inside {[100: 1000]} &&
                              resp_rdy_val_dly inside {[100: 1000]};
  };

  `uvm_object_utils_begin(axi_lite_item)
  //Address channel
    `uvm_field_int (awaddr,   UVM_DEFAULT)
    `uvm_field_int (araddr,   UVM_DEFAULT)
  //Data channel
    `uvm_field_int (wdata, UVM_DEFAULT)
    `uvm_field_int (rdata, UVM_DEFAULT)

    `uvm_field_int (bresp, UVM_DEFAULT)
    `uvm_field_int (rresp, UVM_DEFAULT)
    `uvm_field_int (row, UVM_DEFAULT)
  //Delay
    `uvm_field_enum (delay_type, trans_delay_type, UVM_DEFAULT)
    `uvm_field_int  (trans_delay, UVM_DEFAULT)
    `uvm_field_enum (delay_type, addr_delay_type, UVM_DEFAULT)
    `uvm_field_int  (addr_rdy_val_dly, UVM_DEFAULT)
    `uvm_field_int  (addr_val_rdy_dly, UVM_DEFAULT)
    `uvm_field_enum (delay_type, data_delay_type, UVM_DEFAULT)
    `uvm_field_int  (data_rdy_val_dly, UVM_DEFAULT)
    `uvm_field_int  (data_val_rdy_dly, UVM_DEFAULT)
    `uvm_field_enum (delay_type, resp_delay_type, UVM_DEFAULT)
    `uvm_field_int  (resp_rdy_val_dly, UVM_DEFAULT)
    `uvm_field_int  (resp_val_rdy_dly, UVM_DEFAULT)
  //Handshake type
    `uvm_field_enum (hsk_type, addr_hsk_type, UVM_DEFAULT)
    `uvm_field_enum (hsk_type, data_hsk_type, UVM_DEFAULT)
    `uvm_field_enum (hsk_type, resp_hsk_type, UVM_DEFAULT)
  //Configuration signals
  `uvm_object_utils_end

  //Constructor
  function new(string name = "axi_lite_item");
    super.new(name);
  endfunction: new

endclass: axi_lite_item

