//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : axi_lite_seq.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_lite_to_ahb - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the axi_lite sequences, encapsulating all fields required for read/write operations.
//                         encapsulating all fields required for read/write operations.
//  ======================================================================================================

class axi_lite_base_sequence extends uvm_sequence;

  `uvm_object_utils (axi_lite_base_sequence)

  `uvm_declare_p_sequencer(axi_lite_sequencer)

  int trans_no = 200;

  function new (string name = "axi_lite_base_sequence");
    super.new(name);
  endfunction: new
endclass: axi_lite_base_sequence

class axi_write_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_write_sequence)

  function new (string name= "axi_write_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_write_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 1;
                                   awaddr inside {['h0 : 'hFFFF_FFFF]};
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
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_write_sequence

class axi_read_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_read_sequence)

  function new (string name= "axi_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_read_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 0;
                                   //Addr channel
                                   araddr inside {['h0 : 'hFFFF_FFFF]};//32'd0;
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
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_read_sequence

class axi_read_diff_flv_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_read_diff_flv_sequence)

  function new (string name= "axi_read_diff_flv_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item");
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_read_diff_flv_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 0;
                                   //Addr channel
                                   araddr inside {['h0 : 'hFFFF_FFFF]};//32'd0;
                                   //Channels handshakes between valid and ready
                                   addr_hsk_type inside {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   data_hsk_type inside {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   resp_hsk_type inside  {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   //Channels delay
                                   trans_delay_type == SHORT;
                                   addr_delay_type  == B2B;
                                   data_delay_type  == SHORT;
                                   resp_delay_type  == B2B;
                                  })) //giving values to axiwr signals
         `uvm_error(get_type_name(), "Rand error!")
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_read_diff_flv_sequence

class axi_write_diff_flv_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_write_diff_flv_sequence)

  function new (string name= "axi_write_diff_flv_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item");
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_write_diff_flv_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row == 1;
                                   //Addr channel
                                   awaddr inside {['h0 : 'hFFFF_FFFF]};//32'd0;
                                   //Channels handshakes between valid and ready
                                   addr_hsk_type inside {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   data_hsk_type inside {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   resp_hsk_type inside  {VAL_BFR_RDY, RDY_BFR_VAL, VAL_AND_RDY};
                                   //Channels delay
                                   trans_delay_type == SHORT;
                                   addr_delay_type  == B2B;
                                   data_delay_type  == SHORT;
                                   resp_delay_type  == B2B;
                                  })) //giving values to axiwr signals
         `uvm_error(get_type_name(), "Rand error!")
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_write_diff_flv_sequence

class axi_rd_err_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_rd_err_sequence)

  function new (string name= "axi_rd_err_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_rd_err_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row    == 0;
                                   araddr == 'h3;
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
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_rd_err_sequence

class axi_write_err_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_write_err_sequence)

  function new (string name= "axi_write_err_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create("t_item"); //creating AXI4WR item for signals
    repeat(trans_no) begin
      `uvm_info(get_type_name(), "Start axi_write_err_sequence", UVM_LOW)
      start_item(t_item); //starting getting the data for item
       if(!(t_item.randomize() with {
                                   row    == 1;
                                   awaddr == 'h3;
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
       finish_item(t_item); //all data is on transaction item
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)
    end
  endtask: body

endclass: axi_write_err_sequence

class axi_wr_rd_0_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_wr_rd_0_sequence)

  function new (string name= "axi_wr_rd_0_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create($sformatf("t_item"));
    start_item(t_item);
      if(!(t_item.randomize() with {
            row    == 1;
            awaddr == 'h10;
            // FIXED data 0
            wdata  == 'h0000_0000_0000_0000;
            // handshake
            addr_hsk_type == VAL_BFR_RDY;
            data_hsk_type == VAL_BFR_RDY;
            resp_hsk_type == RDY_BFR_VAL;

            // delays
            trans_delay_type == B2B;
            addr_delay_type  == B2B;
            data_delay_type  == B2B;
            resp_delay_type  == B2B;
      }))
        `uvm_error(get_type_name(), "Rand error!")

    finish_item(t_item);
    start_item(t_item);
      if(!(t_item.randomize() with {
            row    == 0;
            araddr == 'h10;
            // handshake
            addr_hsk_type == VAL_BFR_RDY;
            data_hsk_type == VAL_BFR_RDY;
            resp_hsk_type == RDY_BFR_VAL;

            // delays
            trans_delay_type == B2B;
            addr_delay_type  == B2B;
            data_delay_type  == B2B;
            resp_delay_type  == B2B;
      }))
        `uvm_error(get_type_name(), "Rand error!")

      finish_item(t_item);
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)

  endtask

endclass: axi_wr_rd_0_sequence

class axi_wr_rd_max_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_wr_rd_max_sequence)

  function new (string name= "axi_wr_rd_max_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_item t_item;
    t_item = axi_lite_item::type_id::create($sformatf("t_item"));
    start_item(t_item);
      if(!(t_item.randomize() with {
            row    == 1;
            awaddr == 'h10;
            // FIXED data 0
            wdata  == 'hFFFF_FFFF_FFFF_FFFF;
            // handshake
            addr_hsk_type == VAL_BFR_RDY;
            data_hsk_type == VAL_BFR_RDY;
            resp_hsk_type == RDY_BFR_VAL;

            // delays
            trans_delay_type == B2B;
            addr_delay_type  == B2B;
            data_delay_type  == B2B;
            resp_delay_type  == B2B;
      }))
        `uvm_error(get_type_name(), "Rand error!")

    finish_item(t_item);
    start_item(t_item);
      if(!(t_item.randomize() with {
            row    == 0;
            araddr == 'h10;
            // handshake
            addr_hsk_type == VAL_BFR_RDY;
            data_hsk_type == VAL_BFR_RDY;
            resp_hsk_type == RDY_BFR_VAL;

            // delays
            trans_delay_type == B2B;
            addr_delay_type  == B2B;
            data_delay_type  == B2B;
            resp_delay_type  == B2B;
      }))
        `uvm_error(get_type_name(), "Rand error!")

      finish_item(t_item);
      `uvm_info ("SEQ",$sformatf("item : %s ",t_item.sprint()), UVM_LOW)

  endtask

endclass: axi_wr_rd_max_sequence

class axi_wr_rd_wlk_sequence extends axi_lite_base_sequence;

  `uvm_object_utils(axi_wr_rd_wlk_sequence)

  function new(string name = "axi_wr_rd_wlk_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_item wr_item;
    axi_lite_item rd_item;
    bit [31:0] addr_q[$];
    bit [31:0] base_addr;
    bit [63:0] walking_1[64];
    // ------------------------------------------------------------
    // WRITE phase
    // ------------------------------------------------------------
    foreach (walking_1[i]) begin
      walking_1[i] = 64'(1) << i;
      wr_item = axi_lite_item::type_id::create($sformatf("wr_item_%0d", i));
      base_addr = 32'h0000_1000 + i * 8;

      start_item(wr_item);
        if (!(wr_item.randomize() with {
              row == 1;
              awaddr == base_addr;
              wdata == walking_1[i];
              addr_hsk_type == VAL_BFR_RDY;
              data_hsk_type == VAL_BFR_RDY;
              resp_hsk_type == RDY_BFR_VAL;
              trans_delay_type == B2B;
              addr_delay_type  == B2B;
              data_delay_type  == B2B;
              resp_delay_type  == B2B;
        })) begin
          `uvm_error(get_type_name(), "WRITE randomization error!")
      end
      finish_item(wr_item);
      addr_q.push_back(base_addr);
      `uvm_info("SEQ",$sformatf("WRITE item[%0d]: addr=0x%0h data=0x%0h",i,base_addr,walking_1[i]),UVM_LOW)
    end
    // ------------------------------------------------------------
    // READ phase
    // ------------------------------------------------------------
    foreach (addr_q[i]) begin
      rd_item = axi_lite_item::type_id::create($sformatf("rd_item_%0d", i));
      start_item(rd_item);
        if (!(rd_item.randomize() with {
              row == 0;
              araddr == addr_q[i];
              addr_hsk_type == VAL_BFR_RDY;
              data_hsk_type == VAL_BFR_RDY;
              trans_delay_type == B2B;
              addr_delay_type  == B2B;
              data_delay_type  == B2B;
        })) begin
          `uvm_error(get_type_name(), "READ randomization error!")
        end
      finish_item(rd_item);
      `uvm_info("SEQ",$sformatf("READ item[%0d]: addr=0x%0h expected_data=0x%0h",i,addr_q[i],walking_1[i]),UVM_LOW)
    end
  endtask

endclass : axi_wr_rd_wlk_sequence




