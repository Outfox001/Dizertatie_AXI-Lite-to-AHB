// ============================================================================
// AXI-Lite to AHB Bridge - Package Definition
// ============================================================================

package axi_ahb_pkg;

  // Clock and data parameters
  localparam int ADDR_WIDTH     = 32;                    // Address width
  localparam int AXI_DATA_WIDTH = 64;                    // AXI data width
  localparam int AHB_DATA_WIDTH = 32;                    // AHB data width
  localparam int FIFO_DEPTH     = 16;                    // FIFO depth
  localparam int PTR_WIDTH      = $clog2(FIFO_DEPTH);    // FIFO pointer width

  // Response codes
  localparam logic [1:0] RESP_OKAY   = 2'b00;            // OKAY response
  localparam logic [1:0] RESP_EXOKAY = 2'b01;            // EXOKAY response
  localparam logic [1:0] RESP_SLVERR = 2'b10;            // Slave error response
  localparam logic [1:0] RESP_DECERR = 2'b11;            // Decode error response

  // AHB Transfer types
  localparam logic [1:0] HTRANS_IDLE   = 2'b00;          // IDLE transfer
  localparam logic [1:0] HTRANS_BUSY   = 2'b01;          // BUSY transfer
  localparam logic [1:0] HTRANS_NONSEQ = 2'b10;          // NONSEQ transfer
  localparam logic [1:0] HTRANS_SEQ    = 2'b11;          // SEQ transfer

  // AHB Size
  localparam logic [2:0] HSIZE_32 = 3'b010;              // 32-bit transfer size

  // Gray code conversion
  function logic [PTR_WIDTH-1:0] binary_to_gray(logic [PTR_WIDTH-1:0] binary);
    return binary ^ (binary >> 1);                       // Convert binary to Gray
  endfunction

  function logic [PTR_WIDTH-1:0] gray_to_binary(logic [PTR_WIDTH-1:0] gray);
    logic [PTR_WIDTH-1:0] binary;                         // Binary conversion result

    binary[PTR_WIDTH-1] = gray[PTR_WIDTH-1];              // Copy MSB

    for (int i = PTR_WIDTH-2; i >= 0; i--) begin
      binary[i] = binary[i+1] ^ gray[i];                  // Convert Gray bit to binary bit
    end

    return binary;                                        // Return binary result
  endfunction

endpackage : axi_ahb_pkg