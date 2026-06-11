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

class axi_lite_driver extends uvm_driver#(axi_lite_item);

  `uvm_component_utils (axi_lite_driver)

  virtual axi_lite_if vif_axi;

  //Mailbox to store transaction data for multiple addresses
  mailbox #(axi_lite_item) awaddr_mbox;
  mailbox #(axi_lite_item) araddr_mbox;
  mailbox #(axi_lite_item) wdata_mbox;
  mailbox #(axi_lite_item) resp_mbox;
  mailbox #(axi_lite_item) rdata_mbox;

  //class constructor
  function new (string name = "axi_lite_driver" , uvm_component parent = null);
    super.new (name, parent);
    awaddr_mbox = new();
    araddr_mbox = new();
    wdata_mbox  = new();
    resp_mbox   = new();
    rdata_mbox  = new();
  endfunction: new


  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif_axi", vif_axi)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_if");
     end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    init();
    @(posedge vif_axi.reset);
    //ask if read/write
    get_and_drive();

  endtask: run_phase

  task get_and_drive();
    forever begin
      seq_item_port.get_next_item(req); //getting transaction data from TLM sequencer port
        `uvm_info ("Getting next item...",$sformatf("rsp.row : %h ",req.row), UVM_LOW)
      `uvm_info ("Getting next item...",$sformatf("get_next_item fn calling rsp"), UVM_LOW)
      $cast(rsp, req.clone()); // casting the transaction data into a clone transaction data item
      rsp.set_id_info(req); //setting the transaction/sequence id for future response compatibility
      `uvm_info ("Getting next item...",$sformatf("rsp.row : %h , req.row : %h ",rsp.row ,req.row), UVM_LOW) //intra pe 0 nu pe 1
      `uvm_info(get_type_name(),$sformatf("TRANSACTION %s", rsp.sprint()), UVM_NONE)
      mailbox_item(rsp);   //put the item in the mailbox after address
      if(req.row) begin //if read or write
        `uvm_info ("Getting next item...",$sformatf("rsp.row : %h ",rsp.row), UVM_LOW)
        fork
          wr_addr_handshake();  // write addr channel
          wr_data_handshake();  // write data channel
          wr_resp_handshake();  // write response channel
        join
      end else begin
        fork
          rd_addr_handshake();  // read addr channel
          rd_data_handshake();  // read data channel
        join
      end
      seq_item_port.item_done(); //all requested transaction data was successfully drived to the virtual interface that
                                 //communicates with the DUT
    end
  endtask: get_and_drive


  task init();
    @(posedge vif_axi.clk);
    vif_axi.cb_drv.awvalid <= 'd0;
    vif_axi.cb_drv.wvalid  <= 'd0;
    vif_axi.cb_drv.bready  <= 'd0;
    vif_axi.cb_drv.arvalid <= 'd0;
    vif_axi.cb_drv.rready  <= 'd0;
  endtask : init

  task mailbox_item(axi_lite_item item);
    awaddr_mbox.put(item);
    araddr_mbox.put(item);
    wdata_mbox.put(item);
    rdata_mbox.put(item);
    resp_mbox.put(item);
  endtask : mailbox_item
//---------------------AXI Write----------------------------------------------------------------------------

  task wr_addr_handshake();
    axi_lite_item item;
    @(posedge vif_axi.clk);
    //Choosing of addr channel hsk type
    awaddr_mbox.get(item);
    //if ID < 16
    case(item.addr_hsk_type)
      VAL_BFR_RDY: begin
        //Assert valid
        repeat(item.addr_val_rdy_dly) @(posedge vif_axi.clk);
        vif_axi.cb_drv.awvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        //Wait for the ready signal assertion
        // repeat(item.addr_val_rdy_dly) @(posedge vif_axi.clk);
        `uvm_info(get_type_name(),$sformatf("Transaction write before awready %h :" ,vif_axi.awready),UVM_LOW)
        @(posedge vif_axi.clk iff vif_axi.awready); //todo
        `uvm_info(get_type_name(),$sformatf("Transaction write after awready %h :" ,vif_axi.awready),UVM_LOW)
        //Deassert valid if it remains asserted
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
      RDY_BFR_VAL: begin
        //Wait for the ready signal assertion
        repeat(item.addr_rdy_val_dly) @(posedge vif_axi.clk);
        //Optional delay between rdy and val
        //Assert valid
        vif_axi.cb_drv.awvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        repeat(item.addr_val_rdy_dly) @(posedge vif_axi.clk);
        @(posedge vif_axi.clk iff vif_axi.awready); //todo
        //Deasserting valid
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
      VAL_AND_RDY: begin
        //Wait for the assertion of ready signal
        @(posedge vif_axi.clk iff vif_axi.awready);
        //Assert valid
        vif_axi.cb_drv.awvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.awaddr  <= item.awaddr;
        //In case ready drops bfr valid is asserted
        repeat(item.addr_val_rdy_dly) @(posedge vif_axi.clk);
        @(posedge vif_axi.clk iff vif_axi.awready); //todo
        vif_axi.cb_drv.awvalid <= 1'b0;
      end
    endcase
  endtask: wr_addr_handshake

  task wr_data_handshake();
     axi_lite_item item;
    @(posedge vif_axi.clk);
    // forever begin
      wdata_mbox.get(item);
        //Choosing of data channel hsk type
        case(item.data_hsk_type)
          VAL_BFR_RDY: begin
            //Assert valid
            repeat(item.data_val_rdy_dly) @(posedge vif_axi.clk);
            vif_axi.cb_drv.wvalid <= 1'b1;
            //Put data channel items/information on interface bus
            vif_axi.cb_drv.wdata  <= item.wdata;
            //Wait for the ready signal assertion
            @(posedge vif_axi.clk iff vif_axi.wready);
            //Deassert valid if it remains asserted
            vif_axi.cb_drv.wvalid <= 1'b0;
          end
          RDY_BFR_VAL: begin
            //Wait for the ready signal assertion
            @(posedge vif_axi.clk iff vif_axi.wready);
            //Optional delay between rdy and val
            repeat(item.data_rdy_val_dly) @(posedge vif_axi.clk);
            //Assert valid
            vif_axi.cb_drv.wvalid <= 1'b1;
            //Put data channel items/information on interface bus
            vif_axi.cb_drv.wdata  <= item.wdata;
            //In case ready drops bfr valid is asserted
            @(posedge vif_axi.clk iff vif_axi.wready);
            //Deasserting valid
            vif_axi.cb_drv.wvalid <= 1'b0;
          end
          VAL_AND_RDY: begin
            //Wait for the assertion of ready signal
            @(posedge vif_axi.clk iff vif_axi.wready);
            //Assert valid
            vif_axi.cb_drv.wvalid <= 1'b1;
            //Put data channel items/information on interface bus
            vif_axi.cb_drv.wdata  <= item.wdata;
            //In case ready drops bfr valid is asserted
            @(posedge vif_axi.clk iff vif_axi.wready);
            vif_axi.cb_drv.wvalid <= 1'b0;
          end
        endcase
      // end
  endtask : wr_data_handshake

  task wr_resp_handshake();
    axi_lite_item item;
    @(posedge vif_axi.clk);
    // forever begin
      resp_mbox.get(item);
      case(item.resp_hsk_type)
        VAL_BFR_RDY: begin
          //Wait for valid signal
          @(posedge vif_axi.clk iff vif_axi.bvalid);
          //Assert bready after valid is asserted
          vif_axi.cb_drv.bready <= 1'b1;
          repeat(item.resp_val_rdy_dly) @(posedge vif_axi.clk);
          //Deassert ready after receiving the response
          vif_axi.bready <= 1'b0;
        end
        RDY_BFR_VAL: begin
          //Assert ready signal
          vif_axi.cb_drv.bready <= 1'b1;
          //Wait for valid signal assertion
          @(posedge vif_axi.clk iff vif_axi.bvalid);
          repeat(item.resp_rdy_val_dly) @(posedge vif_axi.clk);
          //Deassert ready after receiving the response
          vif_axi.cb_drv.bready <= 1'b0;
        end
        VAL_AND_RDY: begin
          //Assert ready signal
          vif_axi.cb_drv.bready <= 1'b1;
          //Wait for valid signal assertion
          @(posedge vif_axi.clk iff vif_axi.bvalid);
          //Deassert ready after receiving the response
          vif_axi.cb_drv.bready <= 1'b0;
        end
      endcase
    // end
  endtask : wr_resp_handshake


//---------------------AXI READ--------------------------------------------------------------------------

  task rd_addr_handshake();
    axi_lite_item item;
    @(posedge vif_axi.clk);
    araddr_mbox.get(item);
    //Choosing of addr channel hsk type
    case(item.addr_hsk_type)
      VAL_BFR_RDY: begin
        //Assert valid
        repeat(item.addr_val_rdy_dly) @(posedge vif_axi.clk);
        vif_axi.cb_drv.arvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.araddr  <= item.araddr;
        //Wait for the ready signal assertion
        @(posedge vif_axi.clk iff vif_axi.arready);
        //Deassert valid if it remains asserted
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
      RDY_BFR_VAL: begin //todo
        //Wait for the ready signal assertion
        // @(posedge vif_axi.clk iff vif_axi.arready);
        repeat(item.addr_rdy_val_dly) @(posedge vif_axi.clk);
        //Optional delay between rdy and val
        //Assert valid
        vif_axi.cb_drv.arvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.araddr  <= item.araddr;
        @(posedge vif_axi.clk iff vif_axi.arready);
        //Deasserting valid
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
      VAL_AND_RDY: begin
        //Wait for the assertion of ready signal
        @(posedge vif_axi.clk iff vif_axi.arready);
        //Assert valid
        vif_axi.cb_drv.arvalid <= 1'b1;
        //Put address channel items/information on interface bus
        vif_axi.cb_drv.araddr  <= item.araddr;
        //In case ready drops bfr valid is asserted
        @(posedge vif_axi.clk iff vif_axi.arready);
        vif_axi.cb_drv.arvalid <= 1'b0;
      end
    endcase
  endtask: rd_addr_handshake

  task rd_data_handshake();
    axi_lite_item item;
    @(posedge vif_axi.clk);
    // forever begin
      rdata_mbox.get(item);
        //Choosing of data channel hsk type
        case(item.data_hsk_type)
          VAL_BFR_RDY: begin
            //Wait for the ready signal
            @(posedge vif_axi.clk iff vif_axi.rvalid);
            //Delay between val and rdy
            repeat(item.data_val_rdy_dly) @(posedge vif_axi.clk);
            //Assert ready
            vif_axi.cb_drv.rready <= 1'b1; //todo add delay instead of clk
            @(posedge vif_axi.clk);
            //Deassert ready
            vif_axi.cb_drv.rready <= 1'b0;
          end
          RDY_BFR_VAL: begin
            //Assert ready signal
            vif_axi.cb_drv.rready <= 1'b1;
            //Delay
            //Assert valid signal
            @(posedge vif_axi.clk iff vif_axi.rvalid);
            repeat(item.data_rdy_val_dly) @(posedge vif_axi.clk);
            //Deassert ready
            vif_axi.cb_drv.rready <= 1'b0;
          end
          VAL_AND_RDY: begin
            //Wait for valid signal
            @(posedge vif_axi.clk iff vif_axi.rvalid);
            //Assert ready
            vif_axi.cb_drv.rready <= 1'b1;
            @(posedge vif_axi.clk);
            //Deassert ready
            vif_axi.cb_drv.rready <= 1'b0;
          end
        endcase
      // end
  endtask : rd_data_handshake

endclass: axi_lite_driver


