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

class ahb_monitor extends uvm_monitor;
  // Register the monitor with the UVM factory
  `uvm_component_utils(ahb_monitor)

  // Virtual interface to connect to the DUT
  virtual ahb_if vif;
  ahb_item ahb_item_s;

  // Analysis port to send transactions to subscribers (e.g., scoreboard)
  uvm_analysis_port #(ahb_item) analysis_port;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase: retrieve interface and create analysis port
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "No handle received for ahb_if");
    end
    analysis_port = new("analysis_port", this);
    // Get the virtual interface from the config DB
    ahb_item_s  = ahb_item::type_id::create("ahb_item_s", this);
  endfunction
  // Helper function to determine burst length based on HBURST value
  function int get_burst_length(ahb_burst_e hburst);
    case (hburst)
      SINGLE:         return 1;
      INCR4, WRAP4:   return 4;
      INCR8, WRAP8:   return 8;
      INCR16, WRAP16: return 16;
      INCR:           return 4;  // Default INCR treated as 4-beat burst
      default:        return 1;
    endcase
  endfunction

  // Run phase: monitor AHB transactions and send them via analysis port
  virtual task run_phase(uvm_phase phase);
    // ahb_item             ahb_item_s;
    int                  burst_len ;
    bit [ADDR_WIDTH-1:0] addr      ;

    forever begin
      // Wait for a valid NONSEQ transaction and HREADY signal
      @(vif.cb_mon iff ((vif.cb_mon.htrans == NONSEQ && vif.cb_mon.hready) || !vif.reset));

      // Capture control signals from the interface
      ahb_item_s.haddr        = vif.cb_mon.haddr;
      ahb_item_s.hwrite       = vif.cb_mon.hwrite;
      ahb_item_s.htrans       = vif.cb_mon.htrans;
      // ahb_item_s.hburst       = vif.cb_mon.hburst;
      ahb_item_s.hsize        = vif.cb_mon.hsize;

      // Determine burst length and initialize address
      burst_len               = get_burst_length(ahb_burst_e'(vif.cb_mon.hburst));
      addr                    = vif.cb_mon.haddr;

      // Allocate memory for data arrays based on burst length
      ahb_item_s.hrdata_array = new[burst_len];

      // Loop through each beat in the burst
      for (int i = 0; i < burst_len; i++) begin
        // Wait for HREADY before capturing data
        @(vif.cb_mon iff (vif.cb_mon.hready));

        if (vif.cb_mon.hwrite) begin
          // Capture write data
          // `uvm_info("Monitor", $sformatf("WRITE[%0d]: addr=%h data=%h", i, addr, vif.cb_mon.hwdata), UVM_LOW)
        end else begin
          // Capture read data
          ahb_item_s.hrdata_array[i] = vif.cb_mon.hrdata;
          // `uvm_info("Monitor", $sformatf("READ[%0d]: addr=%h data=%h", i, addr, vif.cb_mon.hrdata), UVM_LOW)
        end
        ahb_item_s.haddr = vif.cb_mon.haddr;
      end

      // Send the captured transaction to the analysis port
      analysis_port.write(ahb_item_s);
      // `uvm_info("Monitor", $sformatf("Captured transaction:\n%s", ahb_item_s.sprint()), UVM_LOW)
    end
  endtask
endclass : ahb_monitor
