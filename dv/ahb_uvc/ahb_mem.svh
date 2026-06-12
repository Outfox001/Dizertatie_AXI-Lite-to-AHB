//  ======================================================================================================
//  Project Information:
//
//  Designer             : Balga Teodora-Stefania (BTS)
//  Date                 : 02/03/2026
//  File name            : ahb_mem.svh
//  Last modified+updates: 12/06/2026 (BTS)
//  Project              : axi_to_ahb_bridge - Disertatie
//
//  ------------------------------------------------------------------------------------------------------
//  Description          : This file defines the ahb memory class, which simulates a simple memory model for AHB transactions,
//                        allowing the driver to store written data and the monitor to retrieve it for verification.
//  ======================================================================================================

class ahb_memory extends uvm_component;

  `uvm_component_utils(ahb_memory)

  typedef bit [ADDR_WIDTH-1:0] addr_t;
  typedef bit [DATA_WIDTH-1:0] data_t;

  data_t mem [addr_t];

  mailbox #(data_t) read_data_mbox;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    read_data_mbox = new();
  endfunction

  function void store(addr_t addr, data_t data);
    mem[addr] = data;
    `uvm_info(get_type_name(),$sformatf("MEM STORE: addr=0x%0h data=0x%0h", addr, data),UVM_HIGH)
  endfunction


  task prepare_read(addr_t addr);
    data_t rdata;
    `uvm_info(get_type_name(),$sformatf("prepare_read"),UVM_HIGH)
    if (mem.exists(addr)) begin
      rdata = mem[addr];
      `uvm_info(get_type_name(),$sformatf("MEM READ HIT: addr=0x%0h data=0x%0h", addr, rdata),UVM_HIGH)
    end
    else begin
      rdata = 0;
      `uvm_info(get_type_name(),$sformatf("MEM READ MISS: addr=0x%0h returning 0", addr),UVM_HIGH)
    end
    read_data_mbox.put(rdata);
  endtask: prepare_read

  function data_t load(addr_t addr, output bit hit);
    hit = mem.exists(addr);
    if (hit) begin
      load = mem[addr];
      `uvm_info(get_type_name(),$sformatf("MEM LOAD HIT: addr=0x%0h data=0x%0h", addr, load),UVM_HIGH)
    end
    else begin
      load = 0;
      `uvm_info(get_type_name(),$sformatf("MEM LOAD MISS: addr=0x%0h returning 0", addr),UVM_HIGH)
    end
  endfunction

  function void clear();
    mem.delete();
  endfunction

endclass : ahb_memory