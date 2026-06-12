//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : bridge_scoreboard.svh
//  Last modified+updates: 12/06/2026 (BTS)
//
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the bridge scoreboard, which compares AXI transactions with corresponding AHB transactions and maintains a reference memory for data verification.
//  ======================================================================================================

`uvm_analysis_imp_decl(_axi_wr_req)
`uvm_analysis_imp_decl(_axi_wr_rsp)
`uvm_analysis_imp_decl(_axi_rd_req)
`uvm_analysis_imp_decl(_axi_rd_rsp)

`uvm_analysis_imp_decl(_ahb)


class bridge_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(bridge_scoreboard)

  uvm_analysis_imp_axi_wr_req #(axi_lite_item, bridge_scoreboard) axi_wr_req_export;
  uvm_analysis_imp_axi_wr_rsp #(axi_lite_item, bridge_scoreboard) axi_wr_rsp_export;
  uvm_analysis_imp_axi_rd_req #(axi_lite_item, bridge_scoreboard) axi_rd_req_export;
  uvm_analysis_imp_axi_rd_rsp #(axi_lite_item, bridge_scoreboard) axi_rd_rsp_export;

  uvm_analysis_imp_ahb #(ahb_item, bridge_scoreboard) ahb_export;
  // --------------------------------------------------------------------------
  // Queues
  // --------------------------------------------------------------------------
  axi_lite_item axi_wr_req_addr_queue[$];
  axi_lite_item axi_wr_req_data_queue[$];
  axi_lite_item axi_wr_rsp_queue[$];

  axi_lite_item axi_rd_req_addr_queue[$];
  axi_lite_item axi_rd_rsp_data_queue[$];

  ahb_item ahb_wr_addr_queue[$];
  ahb_item ahb_wr_data_queue[$];
  ahb_item ahb_wr_rsp_queue[$];

  ahb_item ahb_rd_addr_queue[$];
  ahb_item ahb_rd_data_queue[$];

  // --------------------------------------------------------------------------
  // Scoreboard reference memory
  // One AXI 64-bit access maps to two AHB 32-bit accesses:
  //   AXI addr     -> AHB addr     -> data[31:0]
  //   AXI addr + 4 -> AHB addr + 4 -> data[63:32]
  // --------------------------------------------------------------------------

  typedef bit [31:0] sb_addr_t;
  typedef bit [31:0] sb_data_t;

  sb_data_t ref_mem [sb_addr_t];
  // --------------------------------------------------------------------------
  // Events
  // --------------------------------------------------------------------------

  event axi_wr_req_addr_item_ev;
  event axi_wr_req_data_item_ev;
  event axi_wr_rsp_item_ev;

  event axi_rd_req_addr_item_ev;
  event axi_rd_rsp_data_item_ev;

  event ahb_wr_addr_item_ev;
  event ahb_wr_data_item_ev;
  event ahb_wr_rsp_item_ev;

  event ahb_rd_addr_item_ev;
  event ahb_rd_data_item_ev;


  function new(string name = "bridge_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    axi_wr_req_export = new("axi_wr_req_export", this);
    axi_wr_rsp_export = new("axi_wr_rsp_export", this);
    axi_rd_req_export = new("axi_rd_req_export", this);
    axi_rd_rsp_export = new("axi_rd_rsp_export", this);

    ahb_export = new("ahb_export", this);
  endfunction : build_phase


  // --------------------------------------------------------------------------
  // AXI write request received
  // --------------------------------------------------------------------------

  virtual function void write_axi_wr_req(axi_lite_item t);

    axi_lite_item addr_clone;
    axi_lite_item data_clone;

    if (!$cast(addr_clone, t.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AXI WRITE REQ addr item")
    end

    if (!$cast(data_clone, t.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AXI WRITE REQ data item")
    end

    axi_wr_req_addr_queue.push_back(addr_clone);
    axi_wr_req_data_queue.push_back(data_clone);

    `uvm_info("SCOREBOARD",$sformatf("Received AXI WRITE REQ: item=%s WrReqAddrQ=%0d WrReqDataQ=%0d", t.sprint(),axi_wr_req_addr_queue.size(),axi_wr_req_data_queue.size()),UVM_LOW)

    -> axi_wr_req_addr_item_ev;
    -> axi_wr_req_data_item_ev;

  endfunction : write_axi_wr_req


  // --------------------------------------------------------------------------
  // AXI write response received
  // --------------------------------------------------------------------------

  virtual function void write_axi_wr_rsp(axi_lite_item t);
    axi_lite_item rsp_clone;
    if (!$cast(rsp_clone, t.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AXI WRITE RSP item")
    end
    axi_wr_rsp_queue.push_back(rsp_clone);
    `uvm_info("SCOREBOARD",$sformatf("Received AXI WRITE RSP: item=%s WrRspQ=%0d",t.sprint(),axi_wr_rsp_queue.size()),UVM_LOW)

    -> axi_wr_rsp_item_ev;

  endfunction : write_axi_wr_rsp


  // --------------------------------------------------------------------------
  // AXI read request received
  // --------------------------------------------------------------------------

  virtual function void write_axi_rd_req(axi_lite_item t);
    axi_lite_item addr_clone;
    if (!$cast(addr_clone, t.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AXI READ REQ item")
    end
    axi_rd_req_addr_queue.push_back(addr_clone);
    `uvm_info("SCOREBOARD",$sformatf("Received AXI READ REQ: item=%s RdReqAddrQ=%0d",t.sprint(),axi_rd_req_addr_queue.size()),UVM_LOW)
    -> axi_rd_req_addr_item_ev;

  endfunction : write_axi_rd_req


  // --------------------------------------------------------------------------
  // AXI read response received
  // --------------------------------------------------------------------------

  virtual function void write_axi_rd_rsp(axi_lite_item t);
    axi_lite_item data_clone;

    if (!$cast(data_clone, t.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AXI READ RSP item")
    end

    axi_rd_rsp_data_queue.push_back(data_clone);

    `uvm_info("SCOREBOARD", $sformatf("Received AXI READ RSP: item=%s RdRspDataQ=%0d",t.sprint(),axi_rd_rsp_data_queue.size()),UVM_LOW)

    -> axi_rd_rsp_data_item_ev;

  endfunction : write_axi_rd_rsp


  // --------------------------------------------------------------------------
  // AHB transaction received
  // --------------------------------------------------------------------------

  function void write_ahb(ahb_item item);

    ahb_item addr_clone;
    ahb_item data_clone;
    ahb_item rsp_clone;

    if (!$cast(addr_clone, item.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AHB addr item")
    end

    if (!$cast(data_clone, item.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AHB data item")
    end

    if (!$cast(rsp_clone, item.clone())) begin
      `uvm_fatal("SCOREBOARD", "Failed to clone AHB rsp item")
    end

    if (item.hwrite) begin
      ahb_wr_addr_queue.push_back(addr_clone);
      ahb_wr_data_queue.push_back(data_clone);
      ahb_wr_rsp_queue.push_back(rsp_clone);

      `uvm_info("SCOREBOARD",$sformatf("Received AHB WRITE item. WrAddrQ=%0d WrDataQ=%0d WrRspQ=%0d item=%s",ahb_wr_addr_queue.size(),ahb_wr_data_queue.size(),ahb_wr_rsp_queue.size(),item.sprint()),UVM_LOW)

      -> ahb_wr_addr_item_ev;
      -> ahb_wr_data_item_ev;
      -> ahb_wr_rsp_item_ev;

    end
    else begin
      ahb_rd_addr_queue.push_back(addr_clone);
      ahb_rd_data_queue.push_back(data_clone);

      `uvm_info("SCOREBOARD",$sformatf("Received AHB READ item. RdAddrQ=%0d RdDataQ=%0d item=%s",ahb_rd_addr_queue.size(),ahb_rd_data_queue.size(),item.sprint()), UVM_LOW)

      -> ahb_rd_addr_item_ev;
      -> ahb_rd_data_item_ev;

    end

  endfunction : write_ahb


  // --------------------------------------------------------------------------
  // Run phase
  // --------------------------------------------------------------------------

  virtual task run_phase(uvm_phase phase);

    fork
      compare_write_addr_path();
      compare_write_data_path();
      check_write_response();
      compare_read_addr_path();
      compare_read_data_path();
    join_none

  endtask : run_phase


  // --------------------------------------------------------------------------
  // Compare AXI write address with AHB write addresses
  // --------------------------------------------------------------------------

  task compare_write_addr_path();

    axi_lite_item axi_wr_tx;
    ahb_item      ahb_addr_tx_1;
    ahb_item      ahb_addr_tx_2;

    forever begin
      while (!(axi_wr_req_addr_queue.size() >= 1 && ahb_wr_addr_queue.size() >= 2)) begin
        `uvm_info("SCOREBOARD_WR_ADDR",$sformatf("Waiting WRITE ADDR... AXI WrReqAddrQ=%0d AHB WrAddrQ=%0d",axi_wr_req_addr_queue.size(),ahb_wr_addr_queue.size()),UVM_LOW)
        fork
          @axi_wr_req_addr_item_ev;
          @ahb_wr_addr_item_ev;
        join_any
        disable fork;
      end

      axi_wr_tx     = axi_wr_req_addr_queue.pop_front();
      ahb_addr_tx_1 = ahb_wr_addr_queue.pop_front();
      ahb_addr_tx_2 = ahb_wr_addr_queue.pop_front();

      `uvm_info("SCOREBOARD_WR_ADDR",$sformatf("Comparing WRITE ADDR: AXI awaddr=0x%h AHB addr1=0x%h AHB addr2=0x%h",axi_wr_tx.awaddr,ahb_addr_tx_1.haddr,ahb_addr_tx_2.haddr),UVM_LOW)

      check_addr_pair("WRITE ADDR",axi_wr_tx.awaddr,ahb_addr_tx_1.haddr,ahb_addr_tx_2.haddr);

    end

  endtask : compare_write_addr_path


  // --------------------------------------------------------------------------
  // Compare AXI write data with AHB write data and update reference memory
  // --------------------------------------------------------------------------

  task compare_write_data_path();
    axi_lite_item axi_wr_tx;
    ahb_item      ahb_data_tx_1;
    ahb_item      ahb_data_tx_2;

    logic [63:0] axi_data;
    logic [31:0] ahb_data_1;
    logic [31:0] ahb_data_2;

    forever begin
      while (!(axi_wr_req_data_queue.size() >= 1 && ahb_wr_data_queue.size() >= 2)) begin
        `uvm_info("SCOREBOARD_WR_DATA",$sformatf("Waiting WRITE DATA... AXI WrReqDataQ=%0d AHB WrDataQ=%0d",axi_wr_req_data_queue.size(),ahb_wr_data_queue.size()),UVM_LOW)

        fork
          @axi_wr_req_data_item_ev;
          @ahb_wr_data_item_ev;
        join_any
        disable fork;

      end

      axi_wr_tx     = axi_wr_req_data_queue.pop_front();
      ahb_data_tx_1 = ahb_wr_data_queue.pop_front();
      ahb_data_tx_2 = ahb_wr_data_queue.pop_front();

      axi_data   = axi_wr_tx.wdata;
      ahb_data_1 = ahb_data_tx_1.hwdata;
      ahb_data_2 = ahb_data_tx_2.hwdata;

      `uvm_info("SCOREBOARD_WR_DATA",$sformatf("Comparing WRITE DATA: AXI wdata=0x%h AHB addr1=0x%h data1=0x%h AHB addr2=0x%h data2=0x%h",axi_data,ahb_data_tx_1.haddr,ahb_data_1,ahb_data_tx_2.haddr,ahb_data_2), UVM_LOW)
      check_data_pair("WRITE DATA", axi_data, ahb_data_1, ahb_data_2);

      store_ref_data(ahb_data_tx_1.haddr, ahb_data_1);
      store_ref_data(ahb_data_tx_2.haddr, ahb_data_2);

    end

  endtask : compare_write_data_path


  // --------------------------------------------------------------------------
  // Check AXI write response against combined AHB responses
  // --------------------------------------------------------------------------

  task check_write_response();
    axi_lite_item axi_wr_rsp_tx;
    ahb_item      ahb_wr_rsp_tx_1;
    ahb_item      ahb_wr_rsp_tx_2;
    bit [1:0] expected_bresp;

    forever begin
      while (axi_wr_rsp_queue.size() < 1 || ahb_wr_rsp_queue.size() < 2) begin
        `uvm_info("SCOREBOARD_WR_RSP",$sformatf("Waiting WRITE RSP... AXI WrRspQ=%0d AHB WrRspQ=%0d",axi_wr_rsp_queue.size(),ahb_wr_rsp_queue.size()),UVM_LOW)
        fork
          @axi_wr_rsp_item_ev;
          @ahb_wr_rsp_item_ev;
        join_any
        disable fork;

      end

      axi_wr_rsp_tx   = axi_wr_rsp_queue.pop_front();
      ahb_wr_rsp_tx_1 = ahb_wr_rsp_queue.pop_front();
      ahb_wr_rsp_tx_2 = ahb_wr_rsp_queue.pop_front();

      expected_bresp = map_ahb_pair_to_axi_resp(ahb_wr_rsp_tx_1.hresp,ahb_wr_rsp_tx_2.hresp);

      if (axi_wr_rsp_tx.bresp !== expected_bresp) begin
        `uvm_error("SCOREBOARD_WR_RSP",$sformatf("WRITE response mismatch: AHB hresp1=%0b hresp2=%0b expected AXI bresp=0x%0h actual AXI bresp=0x%0h", ahb_wr_rsp_tx_1.hresp, ahb_wr_rsp_tx_2.hresp, expected_bresp, axi_wr_rsp_tx.bresp))
      end
      else begin
        `uvm_info("SCOREBOARD_WR_RSP",$sformatf("WRITE response matched: AHB hresp1=%0b hresp2=%0b AXI bresp=0x%0h",ahb_wr_rsp_tx_1.hresp, ahb_wr_rsp_tx_2.hresp, axi_wr_rsp_tx.bresp),UVM_LOW)
      end

    end

  endtask : check_write_response


  // --------------------------------------------------------------------------
  // Compare AXI read address with AHB read addresses
  // --------------------------------------------------------------------------

  task compare_read_addr_path();
    axi_lite_item axi_rd_tx;
    ahb_item      ahb_addr_tx_1;
    ahb_item      ahb_addr_tx_2;

    forever begin
      while (!(axi_rd_req_addr_queue.size() >= 1 && ahb_rd_addr_queue.size() >= 2)) begin
        `uvm_info("SCOREBOARD_RD_ADDR",$sformatf("Waiting READ ADDR... AXI RdReqAddrQ=%0d AHB RdAddrQ=%0d",axi_rd_req_addr_queue.size(),ahb_rd_addr_queue.size()), UVM_LOW)
        fork
          @axi_rd_req_addr_item_ev;
          @ahb_rd_addr_item_ev;
        join_any
        disable fork;

      end
      axi_rd_tx     = axi_rd_req_addr_queue.pop_front();
      ahb_addr_tx_1 = ahb_rd_addr_queue.pop_front();
      ahb_addr_tx_2 = ahb_rd_addr_queue.pop_front();
      `uvm_info("SCOREBOARD_RD_ADDR",$sformatf("Comparing READ ADDR: AXI araddr=0x%h AHB addr1=0x%h AHB addr2=0x%h",axi_rd_tx.araddr,ahb_addr_tx_1.haddr,ahb_addr_tx_2.haddr),UVM_LOW)
      check_addr_pair("READ ADDR",axi_rd_tx.araddr,ahb_addr_tx_1.haddr,ahb_addr_tx_2.haddr);

    end

  endtask : compare_read_addr_path


  // --------------------------------------------------------------------------
  // Compare read data using scoreboard reference memory
  // --------------------------------------------------------------------------

  task compare_read_data_path();

    axi_lite_item axi_rd_rsp_tx;
    ahb_item      ahb_data_tx_1;
    ahb_item      ahb_data_tx_2;

    logic [63:0] axi_data;
    logic [63:0] expected_axi_data;

    logic [31:0] ahb_data_1;
    logic [31:0] ahb_data_2;

    logic [31:0] expected_ahb_data_1;
    logic [31:0] expected_ahb_data_2;

    bit hit_1;
    bit hit_2;

    bit [1:0] expected_rresp;

    forever begin

      while (!(axi_rd_rsp_data_queue.size() >= 1 && ahb_rd_data_queue.size() >= 2)) begin
        `uvm_info("SCOREBOARD_RD_DATA",$sformatf("Waiting READ DATA... AXI RdRspDataQ=%0d AHB RdDataQ=%0d",axi_rd_rsp_data_queue.size(),ahb_rd_data_queue.size()),UVM_LOW)
        fork
          @axi_rd_rsp_data_item_ev;
          @ahb_rd_data_item_ev;
        join_any
        disable fork;
      end

      axi_rd_rsp_tx = axi_rd_rsp_data_queue.pop_front();
      ahb_data_tx_1 = ahb_rd_data_queue.pop_front();
      ahb_data_tx_2 = ahb_rd_data_queue.pop_front();

      axi_data   = axi_rd_rsp_tx.rdata;
      ahb_data_1 = ahb_data_tx_1.hrdata;
      ahb_data_2 = ahb_data_tx_2.hrdata;

      expected_rresp = map_ahb_pair_to_axi_resp(ahb_data_tx_1.hresp, ahb_data_tx_2.hresp);
      // Check read response
      if (axi_rd_rsp_tx.rresp !== expected_rresp) begin
        `uvm_error("SCOREBOARD_RD_DATA",$sformatf("READ response mismatch: AHB hresp1=%0b hresp2=%0b expected AXI rresp=0x%0h actual AXI rresp=0x%0h",ahb_data_tx_1.hresp,ahb_data_tx_2.hresp,expected_rresp,axi_rd_rsp_tx.rresp))
      end
      else begin
        `uvm_info("SCOREBOARD_RD_DATA",$sformatf("READ response matched: AHB hresp1=%0b hresp2=%0b AXI rresp=0x%0h",ahb_data_tx_1.hresp,ahb_data_tx_2.hresp,axi_rd_rsp_tx.rresp),UVM_LOW)
      end

      // Get expected data from scoreboard reference memory
      expected_ahb_data_1 = get_ref_data(ahb_data_tx_1.haddr, hit_1);
      expected_ahb_data_2 = get_ref_data(ahb_data_tx_2.haddr, hit_2);
      expected_axi_data = {expected_ahb_data_2, expected_ahb_data_1};
      `uvm_info("SCOREBOARD_RD_DATA",$sformatf("Comparing READ DATA: AXI rdata=0x%h AHB addr1=0x%h hrdata1=0x%h AHB addr2=0x%h hrdata2=0x%h", axi_data,ahb_data_tx_1.haddr,ahb_data_1,ahb_data_tx_2.haddr,ahb_data_2,),UVM_LOW)

      // Check AHB read data word 1
      if (ahb_data_1 !== expected_ahb_data_1) begin
        `uvm_error("SCOREBOARD_RD_DATA",$sformatf("AHB READ DATA 1 mismatch: addr=0x%0h expected=0x%0h actual=0x%0h",ahb_data_tx_1.haddr,expected_ahb_data_1,ahb_data_1))
      end
      else begin
        `uvm_info("SCOREBOARD_RD_DATA",$sformatf("AHB READ DATA 1 matched: addr=0x%0h data=0x%0h",ahb_data_tx_1.haddr,ahb_data_1),UVM_LOW)
      end
      // Check AHB read data word 2
      if (ahb_data_2 !== expected_ahb_data_2) begin
        `uvm_error("SCOREBOARD_RD_DATA",$sformatf("AHB READ DATA 2 mismatch: addr=0x%0h expected=0x%0h actual=0x%0h",ahb_data_tx_2.haddr,expected_ahb_data_2,ahb_data_2))
      end
      else begin
        `uvm_info("SCOREBOARD_RD_DATA",$sformatf("AHB READ DATA 2 matched: addr=0x%0h data=0x%0h",ahb_data_tx_2.haddr,ahb_data_2),UVM_LOW)
      end
      // Check AXI read data
      if (axi_data !== expected_axi_data) begin
        `uvm_error("SCOREBOARD_RD_DATA",$sformatf("AXI READ DATA mismatch: expected=0x%0h actual=0x%0h",expected_axi_data, axi_data))
      end
      else begin
        `uvm_info("SCOREBOARD_RD_DATA",$sformatf("AXI READ DATA matched: data=0x%0h", axi_data),UVM_LOW)
      end
    end
  endtask : compare_read_data_path

  // --------------------------------------------------------------------------
  // Response mapping
  // --------------------------------------------------------------------------

  function bit [1:0] map_ahb_to_axi_resp(bit hresp);
    if (hresp == 1'b0)
      return 2'b00; // OKAY
    else
      return 2'b10; // SLVERR
  endfunction : map_ahb_to_axi_resp


  function bit [1:0] map_ahb_pair_to_axi_resp(bit hresp_1, bit hresp_2);
    if (hresp_1 == 1'b0 && hresp_2 == 1'b0)
      return 2'b00; // OKAY
    else
      return 2'b10; // SLVERR
  endfunction : map_ahb_pair_to_axi_resp


  // --------------------------------------------------------------------------
  // Reference memory helper functions
  // --------------------------------------------------------------------------
  function void store_ref_data(sb_addr_t addr, sb_data_t data);
    ref_mem[addr] = data;
    `uvm_info("SCOREBOARD_MEM",$sformatf("REF MEM STORE: addr=0x%0h data=0x%0h",addr,data),UVM_LOW)
  endfunction : store_ref_data


  function sb_data_t get_ref_data(sb_addr_t addr, output bit hit);
    hit = ref_mem.exists(addr);
    if (hit) begin
      get_ref_data = ref_mem[addr];
      `uvm_info("SCOREBOARD_MEM",$sformatf("REF MEM READ HIT: addr=0x%0h data=0x%0h", addr, get_ref_data),UVM_LOW)
    end
    else begin
      get_ref_data = 0;
      `uvm_info("SCOREBOARD_MEM",$sformatf("REF MEM READ MISS: addr=0x%0h returning 0", addr), UVM_LOW)
    end
  endfunction : get_ref_data


  // --------------------------------------------------------------------------
  // Address check helper
  // --------------------------------------------------------------------------
  function void check_addr_pair(
    string       tag,
    logic [31:0] axi_addr,
    logic [31:0] ahb_addr_1,
    logic [31:0] ahb_addr_2
  );
    if (axi_addr === ahb_addr_1) begin
      `uvm_info("SCOREBOARD_ADDR",$sformatf("%s Transfer 1 - Address match: AXI=0x%h AHB=0x%h", tag, axi_addr, ahb_addr_1),UVM_LOW)
    end
    else begin
      `uvm_error("SCOREBOARD_ADDR",$sformatf("%s Transfer 1 - Address mismatch: Expected AXI=0x%h Got AHB=0x%h", tag, axi_addr, ahb_addr_1))
    end
    if ((axi_addr + 4) === ahb_addr_2) begin
      `uvm_info("SCOREBOARD_ADDR",$sformatf("%s Transfer 2 - Address match: AXI+4=0x%h AHB=0x%h",tag,axi_addr + 4,ahb_addr_2),UVM_LOW)
    end
    else begin
      `uvm_error("SCOREBOARD_ADDR",$sformatf("%s Transfer 2 - Address mismatch: Expected AXI+4=0x%h Got AHB=0x%h",tag,axi_addr + 4,ahb_addr_2))
    end
  endfunction : check_addr_pair
  // --------------------------------------------------------------------------
  // Data check helper
  // --------------------------------------------------------------------------

  function void check_data_pair(
    string       tag,
    logic [63:0] axi_data,
    logic [31:0] ahb_data_1,
    logic [31:0] ahb_data_2
  );
    if (axi_data[31:0] === ahb_data_1) begin
      `uvm_info("SCOREBOARD_DATA",$sformatf("%s Transfer 1 - Data match: AXI[31:0]=0x%h AHB=0x%h",tag,axi_data[31:0],ahb_data_1),UVM_LOW)
    end
    else begin
      `uvm_error("SCOREBOARD_DATA",$sformatf("%s Transfer 1 - Data mismatch: Expected AXI[31:0]=0x%h Got AHB=0x%h",tag,axi_data[31:0],ahb_data_1))
    end
    if (axi_data[63:32] === ahb_data_2) begin
      `uvm_info("SCOREBOARD_DATA",$sformatf("%s Transfer 2 - Data match: AXI[63:32]=0x%h AHB=0x%h",tag,axi_data[63:32],ahb_data_2),UVM_LOW)
    end
    else begin
      `uvm_error("SCOREBOARD_DATA",$sformatf("%s Transfer 2 - Data mismatch: Expected AXI[63:32]=0x%h Got AHB=0x%h",tag,axi_data[63:32],ahb_data_2))
    end

  endfunction : check_data_pair


endclass : bridge_scoreboard