// ============================================================================
// Response FIFO - Dual Clock CDC with Valid/Ready Interface
// ============================================================================
// Specification: Section 3.1.4 - Response FIFO (Dual-Clock)
// Write side (hclk, 400 MHz): wtype[0:0], wresp[1:0], wrdata[63:0], wvalid, wready
// Read side (aclk, 800 MHz): rtype[0:0], rresp[1:0], rrdata[63:0], rvalid, rready
// Flags: full (write domain), empty (read domain)
// Type: 1 = Write response (BRESP), 0 = Read response (RRESP)
// FIFO internally pops data into output registers, then AXI consumes it
// ============================================================================

module fifo_response #(
  parameter int TYPE_WIDTH = 1,
  parameter int RESP_WIDTH = 2,
  parameter int DATA_WIDTH = 64,
  parameter int UNIFIED_WIDTH = TYPE_WIDTH + RESP_WIDTH + DATA_WIDTH,
  parameter int DEPTH = 16,
  parameter int PTR_WIDTH = $clog2(DEPTH)
) (
  input  logic                      wclk,                       // Write-side clock
  input  logic                      wresetn,                    // Write-side reset
  input  logic [TYPE_WIDTH-1:0]     wtype,                      // Response type
  input  logic [RESP_WIDTH-1:0]     wresp,                      // Response code
  input  logic [DATA_WIDTH-1:0]     wrdata,                     // Response data
  input  logic                      core_resp_valid,            // Response valid from core
  output logic                      core_resp_ready,            // Response ready to core
  output logic                      fifo_response_full,         // Full flag

  input  logic                      rclk,                       // Read-side clock
  input  logic                      rresetn,                    // Read-side reset
  output logic [TYPE_WIDTH-1:0]     fifo_response_output_type,  // Output response type
  output logic [RESP_WIDTH-1:0]     fifo_response_output_resp,  // Output response code
  output logic [DATA_WIDTH-1:0]     fifo_response_output_data,  // Output response data
  output logic                      fifo_response_output_valid, // Output response valid
  input  logic                      axi_resp_ready,             // AXI response ready
  output logic                      fifo_response_empty         // Empty flag
);

  logic [UNIFIED_WIDTH-1:0] resp_mem [0:DEPTH-1];               // Response memory

  logic [PTR_WIDTH:0]       write_ptr;                          // Write pointer
  logic [PTR_WIDTH:0]       write_ptr_gray;                     // Write pointer Gray
  logic [PTR_WIDTH:0]       read_ptr_gray_sync1;                // Read pointer sync stage 1
  logic [PTR_WIDTH:0]       read_ptr_gray_sync2;                // Read pointer sync stage 2

  logic [PTR_WIDTH:0]       read_ptr;                           // Read pointer
  logic [PTR_WIDTH:0]       read_ptr_gray;                      // Read pointer Gray
  logic [PTR_WIDTH:0]       write_ptr_gray_sync1;               // Write pointer sync stage 1
  logic [PTR_WIDTH:0]       write_ptr_gray_sync2;               // Write pointer sync stage 2

  logic                     fifo_pop;                           // Internal FIFO pop
  logic                     axi_pop;                            // AXI output consume
  logic                     fifo_empty;                         // Internal empty flag

  // ========================================================================
  // WRITE POINTER REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       write_ptr <= '0;                                               // Reset write pointer
    else if (core_resp_valid && core_resp_ready)        write_ptr <= write_ptr + 1'b1;                                 // Increment write pointer
  end

  // ========================================================================
  // RESPONSE MEMORY WRITE
  // ========================================================================

  always_ff @(posedge wclk) begin
    if (core_resp_valid && core_resp_ready)             resp_mem[write_ptr[PTR_WIDTH-1:0]] <= {wtype, wrdata, wresp};  // Store response entry
  end

  // ========================================================================
  // WRITE POINTER GRAY CONTROL
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       write_ptr_gray = '0;                                           // Default Gray pointer
    else                                                write_ptr_gray = write_ptr ^ (write_ptr >> 1);                 // Convert write pointer to Gray
  end

  // ========================================================================
  // READ POINTER SYNC STAGE 1 REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync1 <= '0;                                     // Reset sync stage 1
    else                                                read_ptr_gray_sync1 <= read_ptr_gray;                          // Capture read pointer Gray
  end

  // ========================================================================
  // READ POINTER SYNC STAGE 2 REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync2 <= '0;                                     // Reset sync stage 2
    else                                                read_ptr_gray_sync2 <= read_ptr_gray_sync1;                    // Synchronize read pointer Gray
  end

  // ========================================================================
  // RESPONSE FIFO FULL CONTROL
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       fifo_response_full = 1'b0;                                     // Default full flag
    else                                                fifo_response_full = (write_ptr_gray == {~read_ptr_gray_sync2[PTR_WIDTH:PTR_WIDTH-1], read_ptr_gray_sync2[PTR_WIDTH-2:0]}); // Full condition
  end

  // ========================================================================
  // CORE RESPONSE READY CONTROL
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       core_resp_ready = 1'b0;                                        // Default ready
    else                                                core_resp_ready = ~fifo_response_full;                         // Ready when not full
  end

  // ========================================================================
  // INTERNAL EMPTY FLAG CONTROL
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_empty = 1'b1;                                             // Default empty flag
    else                                                fifo_empty = (read_ptr_gray == write_ptr_gray_sync2);          // FIFO memory empty
  end

  // ========================================================================
  // INTERNAL FIFO POP CONTROL
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_pop = 1'b0;                                               // Default internal pop
    else                                                fifo_pop = !fifo_response_output_valid && !fifo_empty;         // Load output stage when empty
  end

  // ========================================================================
  // AXI POP CONTROL
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       axi_pop = 1'b0;                                                // Default AXI pop
    else                                                axi_pop = fifo_response_output_valid && axi_resp_ready;        // AXI consumes output response
  end

  // ========================================================================
  // READ POINTER REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       read_ptr <= '0;                                                // Reset read pointer
    else if (fifo_pop)                                  read_ptr <= read_ptr + 1'b1;                                   // Increment read pointer on internal pop
  end

  // ========================================================================
  // READ POINTER GRAY CONTROL
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       read_ptr_gray = '0;                                            // Default read pointer Gray
    else                                                read_ptr_gray = read_ptr ^ (read_ptr >> 1);                    // Convert read pointer to Gray
  end

  // ========================================================================
  // WRITE POINTER SYNC STAGE 1 REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync1 <= '0;                                    // Reset sync stage 1
    else                                                write_ptr_gray_sync1 <= write_ptr_gray;                        // Capture write pointer Gray
  end

  // ========================================================================
  // WRITE POINTER SYNC STAGE 2 REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync2 <= '0;                                    // Reset sync stage 2
    else                                                write_ptr_gray_sync2 <= write_ptr_gray_sync1;                  // Synchronize write pointer Gray
  end

  // ========================================================================
  // RESPONSE OUTPUT VALID REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_response_output_valid <= 1'b0;                           // Reset output valid
    else if (fifo_pop)                                  fifo_response_output_valid <= 1'b1;                           // Set output valid after internal pop
    else if (axi_pop)                                   fifo_response_output_valid <= 1'b0;                           // Clear output valid after AXI consume
  end

  // ========================================================================
  // RESPONSE OUTPUT TYPE REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_response_output_type <= '0;                              // Reset output type
    else if (fifo_pop)                                  fifo_response_output_type <= resp_mem[read_ptr[PTR_WIDTH-1:0]][UNIFIED_WIDTH-1]; // Load output type
  end

  // ========================================================================
  // RESPONSE OUTPUT DATA REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_response_output_data <= '0;                              // Reset output data
    else if (fifo_pop)                                  fifo_response_output_data <= resp_mem[read_ptr[PTR_WIDTH-1:0]][UNIFIED_WIDTH-1-TYPE_WIDTH:RESP_WIDTH]; // Load output data
  end

  // ========================================================================
  // RESPONSE OUTPUT CODE REGISTER UPDATE
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_response_output_resp <= '0;                              // Reset output response code
    else if (fifo_pop)                                  fifo_response_output_resp <= resp_mem[read_ptr[PTR_WIDTH-1:0]][RESP_WIDTH-1:0]; // Load output response code
  end

  // ========================================================================
  // RESPONSE FIFO EMPTY CONTROL
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_response_empty = 1'b1;                                    // Default empty flag
    else                                                fifo_response_empty = fifo_empty && !fifo_response_output_valid; // Empty memory and output stage
  end

endmodule : fifo_response