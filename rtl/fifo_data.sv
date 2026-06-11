// ============================================================================
// Data FIFO - Dual Clock CDC with Valid/Ready Interface
// ============================================================================
// Specification: Section 3.1.3 - Data FIFO (Dual-Clock)
// Write side (aclk, 800 MHz): wdata[63:0], wvalid, wready
// Read side (hclk, 400 MHz): rdata[63:0], rvalid, rready
// Flags: full (write domain), empty (read domain)
// ============================================================================

module fifo_data #(
  parameter int DATA_WIDTH = 64,
  parameter int DEPTH = 16,
  parameter int PTR_WIDTH = $clog2(DEPTH)
) (
  // Write side (aclk, 800 MHz)
  input  logic                  wclk,                   // Write-side clock from AXI domain
  input  logic                  wresetn,                // Write-side active-low reset
  input  logic [DATA_WIDTH-1:0] wdata,                  // 64-bit write data input from AXI master
  input  logic                  wvalid,                 // Write valid signal indicating data is available
  output logic                  wready,                 // Write ready signal indicating FIFO can accept data
  output logic                  fifo_data_full,         // Full flag for the write domain

  // Read side (hclk, 400 MHz)
  input  logic                  rclk,                   // Read-side clock from AHB domain
  input  logic                  rresetn,                // Read-side active-low reset
  output logic [DATA_WIDTH-1:0] fifo_data_output_data,  // 64-bit data output to AHB bridge logic
  output logic                  fifo_data_output_valid, // Valid signal indicating data is available to read
  input  logic                  valid_ready_data_ready, // Ready signal from consumer to pop data
  output logic                  fifo_data_pop,          // Pop signal from FIFO when handshaking completes
  output logic                  fifo_data_empty         // Empty flag for the read domain
);

  // Data memory
  logic [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];            // Memory array to store 64-bit AXI data entries

  // Write-domain pointers
  logic [PTR_WIDTH:0]    write_ptr;                       // Binary write pointer in the write clock domain
  logic [PTR_WIDTH:0]    write_ptr_gray;                  // Gray-coded write pointer for safe clock domain crossing
  logic [PTR_WIDTH:0]    read_ptr_gray_sync1;             // Stage 1 synchronizer for the Gray read pointer in write domain
  logic [PTR_WIDTH:0]    read_ptr_gray_sync2;             // Stage 2 synchronizer for the Gray read pointer in write domain

  // Read-domain pointers
  logic [PTR_WIDTH:0]    read_ptr;                        // Binary read pointer in the read clock domain
  logic [PTR_WIDTH:0]    read_ptr_gray;                   // Gray-coded read pointer for safe clock domain crossing
  logic [PTR_WIDTH:0]    write_ptr_gray_sync1;            // Stage 1 synchronizer for the Gray write pointer in read domain
  logic [PTR_WIDTH:0]    write_ptr_gray_sync2;            // Stage 2 synchronizer for the Gray write pointer in read domain

  // Internal control signals
  logic [PTR_WIDTH:0]    read_ptr_plus1;                  // Next read pointer for pop
  logic [PTR_WIDTH:0]    read_ptr_plus1_gray;             // Gray-coded next read pointer

  // ========================================================================
  // WRITE DOMAIN - WRITE OPERATION (Sequential)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       write_ptr <= '0;                                                else // Reset write pointer to 0
    if (wvalid && wready)                               write_ptr <= write_ptr + 1'b1;                                  // Increment write pointer on successful data handshake
  end

  // ========================================================================
  // WRITE DATA TO MEMORY (Sequential)
  // ========================================================================

  always_ff @(posedge wclk) begin
    if (wvalid && wready)                               data_mem[write_ptr[PTR_WIDTH-1:0]] <= wdata;                    // Store AXI write data into memory array
  end

  // ========================================================================
  // WRITE POINTER TO GRAY (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       write_ptr_gray = '0;                                            else // Default Gray pointer to 0
                                                        write_ptr_gray = write_ptr ^ (write_ptr >> 1);                  // Convert binary pointer to Gray code
  end

  // ========================================================================
  // READ POINTER SYNC - STAGE 1 (Sequential - Write Domain)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync1 <= '0;                                      else // Reset stage 1 synchronizer
                                                        read_ptr_gray_sync1 <= read_ptr_gray;                           // Capture Gray read pointer
  end

  // ========================================================================
  // READ POINTER SYNC - STAGE 2 (Sequential - Write Domain)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync2 <= '0;                                      else // Reset stage 2 synchronizer
                                                        read_ptr_gray_sync2 <= read_ptr_gray_sync1;                     // Clean meta-stability
  end

  // ========================================================================
  // WRITE FULL FLAG (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       fifo_data_full = 1'b0;                                          else // Default full flag to 0
                                                        fifo_data_full = (write_ptr_gray == {~read_ptr_gray_sync2[PTR_WIDTH:PTR_WIDTH-1], read_ptr_gray_sync2[PTR_WIDTH-2:0]}); // Assert full when FIFO capacity is reached
  end

  // ========================================================================
  // WRITE READY (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       wready = 1'b0;                                                  else // Default write ready to 0
                                                        wready = ~fifo_data_full;                                       // Ready to accept data when FIFO is not full
  end

  // ========================================================================
  // POP SIGNAL (Combinational)
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_data_pop = 1'b0;                                           else // Default pop flag to 0
                                                        fifo_data_pop = fifo_data_output_valid && valid_ready_data_ready; // Assert pop when data is valid and consumer is ready
  end

  // ========================================================================
  // READ DOMAIN - READ OPERATION (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       read_ptr <= '0;                                                 else // Reset read pointer
    if (fifo_data_pop)                                  read_ptr <= read_ptr + 1'b1;                                    // Increment pointer upon pop
  end

  // ========================================================================
  // READ POINTER TO GRAY (Combinational)
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       read_ptr_gray = '0;                                             else // Default Gray pointer to 0
                                                        read_ptr_gray = read_ptr ^ (read_ptr >> 1);                     // Convert binary read pointer to Gray code
  end

  // ========================================================================
  // NEXT READ POINTER (Combinational)
  // ========================================================================

  always_comb begin
    read_ptr_plus1 = read_ptr + 1'b1;                                                                             // Compute next read pointer for pop
  end

  // ========================================================================
  // NEXT READ POINTER GRAY (Combinational)
  // ========================================================================

  always_comb begin
    read_ptr_plus1_gray = read_ptr_plus1 ^ (read_ptr_plus1 >> 1);                                                  // Convert next read pointer to Gray code
  end

  // ========================================================================
  // WRITE POINTER SYNC - STAGE 1 (Sequential - Read Domain)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync1 <= '0;                                    else // Reset stage 1 synchronizer
                                                        write_ptr_gray_sync1 <= write_ptr_gray;                        // Capture Gray write pointer
  end

  // ========================================================================
  // WRITE POINTER SYNC - STAGE 2 (Sequential - Read Domain)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync2 <= '0;                                    else // Reset stage 2 synchronizer
                                                        write_ptr_gray_sync2 <= write_ptr_gray_sync1;                  // Clean meta-stability
  end

  // ========================================================================
  // READ VALID REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_data_output_valid <= 1'b0;                                else // Reset output valid
    if (!fifo_data_output_valid && (read_ptr_gray != write_ptr_gray_sync2))
                                                        fifo_data_output_valid <= 1'b1;                                else // Assert valid when FIFO has data
    if (fifo_data_pop)                                  fifo_data_output_valid <= (read_ptr_plus1_gray != write_ptr_gray_sync2); // Update valid after pop
  end

  // ========================================================================
  // READ DATA REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_data_output_data <= '0;                                   else // Reset output data
    if (!fifo_data_output_valid && (read_ptr_gray != write_ptr_gray_sync2))
                                                        fifo_data_output_data <= data_mem[read_ptr[PTR_WIDTH-1:0]];    else // Load current data
    if (fifo_data_pop) begin
      if (read_ptr_plus1_gray == write_ptr_gray_sync2)  fifo_data_output_data <= '0;                                   else // Clear data when FIFO becomes empty
                                                        fifo_data_output_data <= data_mem[read_ptr_plus1[PTR_WIDTH-1:0]]; // Load next data
    end
  end

  // ========================================================================
  // READ EMPTY FLAG (Combinational)
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_data_empty = 1'b1;                                        else // Default empty to 1
                                                        fifo_data_empty = (read_ptr_gray == write_ptr_gray_sync2);      // Assert empty when read pointer equals write pointer
  end

endmodule : fifo_data