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

class axi_lite_base_sequence extends uvm_sequence;

  `uvm_object_utils (axi_lite_base_sequence)

  `uvm_declare_p_sequencer(axi_lite_sequencer)

  int trans_no = 2;

  function new (string name = "axi_lite_base_sequence");
    super.new(name);
  endfunction: new
endclass: axi_lite_base_sequence

class axi_master_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_master_sequence)

  function new (string name= "axi_master_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 1;
                                   //Addr channel
                                  //  awaddr inside {['h0 : 'hFF]};//32'd0;
                                   awaddr inside {['h0 : 'hFF]};//32'd0;
                                   //Channels handshakes between valid and ready
                                   addr_hsk_type == VAL_BFR_RDY;
                                   data_hsk_type == VAL_BFR_RDY;
                                   resp_hsk_type == RDY_BFR_VAL;
                                   //Channels delay
                                   trans_delay_type == B2B;
                                   addr_delay_type  == B2B;
                                   data_delay_type  == B2B;
                                   resp_delay_type  == B2B;
                                  })) //giving values to axiwr signals
         `uvm_error(get_type_name(), "Rand error!")
        `uvm_info ("SEQ",$sformatf("rsp.row : %h ",t_item.row), UVM_LOW)
       finish_item(t_item); //all data is on transaction item
    end
  endtask: body

endclass: axi_master_sequence

class axi_read_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_read_sequence)

  function new (string name= "axi_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 0;
                                   //Addr channel
                                  //  awaddr inside {['h0 : 'hFF]};//32'd0;
                                   araddr inside {['h0 : 'hFF]};//32'd0;
                                   //Channels handshakes between valid and ready
                                   addr_hsk_type == VAL_BFR_RDY;
                                   data_hsk_type == VAL_BFR_RDY;
                                   resp_hsk_type == RDY_BFR_VAL;
                                   //Channels delay
                                   trans_delay_type == B2B;
                                   addr_delay_type  == B2B;
                                   data_delay_type  == B2B;
                                   resp_delay_type  == B2B;
                                  })) //giving values to axiwr signals
         `uvm_error(get_type_name(), "Rand error!")
        `uvm_info ("SEQ",$sformatf("rsp.row : %h ",t_item.row), UVM_LOW)
       finish_item(t_item); //all data is on transaction item
    end
  endtask: body

endclass: axi_read_sequence
