// ============================================================================
// AHB RAM Slave - Simple Memory Model for FPGA Bring-up
// ============================================================================
// This module implements:
// - AHB-Lite slave memory
// - 32-bit word storage
// - Always-ready response
// - Optional address alignment error through HRESP
// ============================================================================

module ahb_ram_slave #(
  parameter int MEM_WORDS = 4096
) (
  // Clock and Reset
  input  logic          hclk,                // AHB clock domain
  input  logic          hresetn,             // AHB active-low reset

  // AHB Slave Ports
  input  logic [31:0]   haddr,               // AHB address
  input  logic          hwrite,              // AHB write control
  input  logic [2:0]    hsize,               // AHB transfer size
  input  logic [1:0]    htrans,              // AHB transfer type
  input  logic [2:0]    hburst,              // AHB burst type
  input  logic [31:0]   hwdata,              // AHB write data
  output logic [31:0]   hrdata,              // AHB read data
  output logic          hresp,               // AHB response
  output logic          hready               // AHB ready
);

  import axi_ahb_pkg::*;

  // ========================================================================
  // INTERNAL SIGNALS
  // ========================================================================

  logic [31:0]          mem [0:MEM_WORDS-1]; // Internal word-addressed memory
  logic [31:0]          haddr_d;             // Delayed AHB address phase
  logic                 hwrite_d;            // Delayed AHB write control
  logic [1:0]           htrans_d;            // Delayed AHB transfer type
  logic                 hresp_d;             // Registered AHB response
  logic [31:0]          hrdata_reg;          // Registered AHB read data

  // ========================================================================
  // AHB ADDRESS ERROR FUNCTION
  // ========================================================================

  function automatic logic ahb_addr_error(
    input logic [31:0] addr,
    input logic [1:0]  trans
  );
    if (trans == HTRANS_NONSEQ)                    ahb_addr_error = (addr[2:0] != 3'b000);            else // First beat must be 8-byte aligned
    if (trans == HTRANS_SEQ)                       ahb_addr_error = (addr[1:0] != 2'b00);             else // Second beat must be 32-bit aligned
                                                    ahb_addr_error = 1'b0;                                  // IDLE/BUSY are not errors
  endfunction

  // ========================================================================
  // AHB ADDRESS PHASE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                       haddr_d <= '0;                                else // Reset delayed address
    if (hready)                                         haddr_d <= haddr;                             // Capture AHB address phase
  end

  // ========================================================================
  // AHB WRITE CONTROL REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                       hwrite_d <= 1'b0;                              else // Reset delayed write control
    if (hready)                                         hwrite_d <= hwrite;                            // Capture AHB write control
  end

  // ========================================================================
  // AHB TRANSFER TYPE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                       htrans_d <= HTRANS_IDLE;                       else // Reset delayed transfer type
    if (hready)                                         htrans_d <= htrans;                            // Capture AHB transfer type
  end

  // ========================================================================
  // AHB RESPONSE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                       hresp_d <= 1'b0;                               else // Reset AHB response
    if (hready && htrans[1])                            hresp_d <= ahb_addr_error(haddr, htrans);      else // Generate response from address phase
                                                        hresp_d <= 1'b0;                               // Clear response for IDLE/BUSY
  end

  // ========================================================================
  // AHB READ DATA REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                       hrdata_reg <= '0;                              else // Reset read data
    if (!hwrite && hready && htrans[1])                 hrdata_reg <= mem[haddr[13:2]];                // Prepare read data for next data phase
  end

  // ========================================================================
  // AHB MEMORY WRITE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk) begin
    if (hwrite_d && hready && htrans_d[1] && !hresp_d)   mem[haddr_d[13:2]] <= hwdata;                  // Store write data during AHB data phase
  end

  // ========================================================================
  // AHB READ DATA OUTPUT ASSIGNMENT
  // ========================================================================

  assign hrdata = hrdata_reg;                                                                           // Drive registered read data

  // ========================================================================
  // AHB RESPONSE OUTPUT ASSIGNMENT
  // ========================================================================

  assign hresp = hresp_d;                                                                                // Drive registered AHB response

  // ========================================================================
  // AHB READY OUTPUT ASSIGNMENT
  // ========================================================================

  assign hready = 1'b1;                                                                                  // Always-ready AHB slave

endmodule : ahb_ram_slave