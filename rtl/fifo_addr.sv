// ============================================================================
// Address FIFO - Dual Clock CDC with Valid/Ready Interface
// ============================================================================
// Specification: Section 3.1.2 - Address FIFO (Dual-Clock)
// Write side (aclk, 800 MHz): waddr[31:0], wvalid, wready
// Read side (hclk, 400 MHz): raddr[31:0], rvalid, rready
// Flags: full (write domain), empty (read domain)
// ============================================================================

module fifo_addr #(
  parameter int ADDR_WIDTH = 32,
  parameter int DEPTH = 16,
  parameter int PTR_WIDTH = $clog2(DEPTH)
) (
  // Write side (aclk, 800 MHz)
  input  logic                  wclk,                   // Write-side clock from AXI domain
  input  logic                  wresetn,                // Write-side active-low reset
  input  logic [ADDR_WIDTH-1:0] awaddr,                 // AXI Write Address input
  input  logic                  awvalid,                // AXI Write Address valid signal
  output logic                  awready,                // AXI Write Address ready signal
  input  logic [ADDR_WIDTH-1:0] araddr,                 // AXI Read Address input
  input  logic                  arvalid,                // AXI Read Address valid signal
  output logic                  arready,                // AXI Read Address ready signal
  output logic                  fifo_addr_full,         // Full flag for the write domain

  // Read side (hclk, 400 MHz)
  input  logic                  rclk,                   // Read-side clock from AHB domain
  input  logic                  rresetn,                // Read-side active-low reset
  output logic [ADDR_WIDTH-1:0] fifo_addr_output_addr,  // Address output to AHB bridge logic
  output logic                  fifo_addr_output_type,  // Transaction type output (1 = Write, 0 = Read)
  output logic                  fifo_addr_output_valid, // Valid signal indicating address is available
  input  logic                  valid_ready_addr_ready, // Ready signal from consumer to pop address
  output logic                  fifo_addr_pop,          // Pop signal from FIFO when handshaking completes
  output logic                  fifo_addr_empty         // Empty flag for the read domain
);

  // Address memory
  logic [ADDR_WIDTH-1:0] addr_mem [0:DEPTH-1]; // Memory array to store AXI addresses
  
  // Type memory (1 = Write, 0 = Read)
  logic                  type_mem [0:DEPTH-1]; // Memory array to store transaction type (1 = Write, 0 = Read)
  
  // Write-domain pointers
  logic [PTR_WIDTH:0] write_ptr;               // Binary write pointer in write clock domain
  logic [PTR_WIDTH:0] write_ptr_gray;          // Gray-coded write pointer in write clock domain
  logic [PTR_WIDTH:0] read_ptr_gray_sync1;     // Stage 1 synchronizer for read pointer in write domain
  logic [PTR_WIDTH:0] read_ptr_gray_sync2;     // Stage 2 synchronizer for read pointer in write domain
  
  // Read-domain pointers
  logic [PTR_WIDTH:0] read_ptr;                // Binary read pointer in read clock domain
  logic [PTR_WIDTH:0] read_ptr_gray;           // Gray-coded read pointer in read clock domain
  logic [PTR_WIDTH:0] write_ptr_gray_sync1;    // Stage 1 synchronizer for write pointer in read domain
  logic [PTR_WIDTH:0] write_ptr_gray_sync2;    // Stage 2 synchronizer for write pointer in read domain

  // Internal control signals
  logic [PTR_WIDTH:0] read_ptr_plus1;          // Next read pointer for pop
  logic [PTR_WIDTH:0] read_ptr_plus1_gray;     // Gray-coded next read pointer

  // ========================================================================
  // WRITE DOMAIN - WRITE OPERATION (Sequential)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       write_ptr <= '0;                  else                                // Reset write pointer to 0 on asynchronous reset
    if (awvalid && awready)                             write_ptr <= write_ptr + 1'b1;    else                                // Increment write pointer on successful AXI write address handshake
    if (arvalid && arready)                             write_ptr <= write_ptr + 1'b1;                                        // Increment write pointer on successful AXI read address handshake
  end

  // ========================================================================
  // WRITE ADDRESS TO MEMORY (Sequential)
  // ========================================================================

  always_ff @(posedge wclk) begin
    if (awvalid && awready)                             addr_mem[write_ptr[PTR_WIDTH-1:0]] <= awaddr;                   else // Store AXI write address into memory array
    if (arvalid && arready)                             addr_mem[write_ptr[PTR_WIDTH-1:0]] <= araddr;                   // Store AXI read address into memory array
  end

  // ========================================================================
  // WRITE TYPE TO MEMORY (Sequential)
  // ========================================================================

  always_ff @(posedge wclk) begin
    if (awvalid && awready)                             type_mem[write_ptr[PTR_WIDTH-1:0]] <= 1'b1;                     else // Store 1 to indicate a write transaction
    if (arvalid && arready)                             type_mem[write_ptr[PTR_WIDTH-1:0]] <= 1'b0;                     // Store 0 to indicate a read transaction
  end

  // ========================================================================
  // WRITE POINTER TO GRAY (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       write_ptr_gray = '0;                                            else // Reset Gray pointer to 0 to prevent X-state propagation
                                                        write_ptr_gray = write_ptr ^ (write_ptr >> 1);                  // Convert binary write pointer to Gray code for safe CDC
  end

  // ========================================================================
  // READ POINTER SYNC - STAGE 1 (Sequential - Write Domain)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync1 <= '0;                                      else // Reset stage 1 synchronizer
                                                        read_ptr_gray_sync1 <= read_ptr_gray;                           // Capture Gray read pointer from read domain
  end

  // ========================================================================
  // READ POINTER SYNC - STAGE 2 (Sequential - Write Domain)
  // ========================================================================

  always_ff @(posedge wclk or negedge wresetn) begin
    if (!wresetn)                                       read_ptr_gray_sync2 <= '0;                                      else // Reset stage 2 synchronizer
                                                        read_ptr_gray_sync2 <= read_ptr_gray_sync1;                     // Clean meta-stability to provide stable pointer
  end

  // ========================================================================
  // WRITE FULL FLAG (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       fifo_addr_full = 1'b0;                                          else // Default full flag to 0 on reset
                                                        fifo_addr_full = (write_ptr_gray == {~read_ptr_gray_sync2[PTR_WIDTH:PTR_WIDTH-1], read_ptr_gray_sync2[PTR_WIDTH-2:0]}); // Assert full when Gray write pointer catches up to synchronized read pointer
  end

  // ========================================================================
  // WRITE READY (Combinational)
  // WRITE READY ARBITRATION (Combinational)
  // ========================================================================

  always_comb begin
    if (!wresetn)                                       awready = 1'b1;                                                 else // Default AXI write address ready to 0
    if (fifo_addr_full)                                 awready = 1'b0;                                                 else // Accept AXI write addresses as long as FIFO is not full
                                                        awready = 1'b1;                                                  // Accept AXI write addresses if not full, giving priority to pending writes
  end

  always_comb begin
    if (!wresetn)                                       arready = 1'b1;                                                 else // Default AXI read address ready to 0
    if (fifo_addr_full)                                 arready = 1'b0;                                                 else
                                                        arready = 1'b1;                                                 // Accept AXI read addresses if not full, giving priority to pending writes
  end

  // ========================================================================
  // POP SIGNAL (Combinational) - Matches 'pop' in waveform
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_addr_pop = 1'b0;                                            else // Default pop flag to 0
                                                        fifo_addr_pop = fifo_addr_output_valid && valid_ready_addr_ready; // Assert pop when data is valid and consumer is ready
  end

  // ========================================================================
  // READ DOMAIN - READ OPERATION (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       read_ptr <= '0;                                                 else // Reset read pointer to 0
    if (fifo_addr_pop)                                  read_ptr <= read_ptr + 1'b1;                                    // Increment read pointer on successful pop handshake
  end

  // ========================================================================
  // READ POINTER TO GRAY (Combinational)
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       read_ptr_gray = '0;                                             else // Reset Gray pointer to 0
                                                        read_ptr_gray = read_ptr ^ (read_ptr >> 1);                     // Convert binary read pointer to Gray code
  end

  // ========================================================================
  // NEXT READ POINTER (Combinational)
  // ========================================================================

  always_comb begin
    read_ptr_plus1 = read_ptr + 1'b1;                                     // Compute next read pointer for pop
  end

  // ========================================================================
  // NEXT READ POINTER GRAY (Combinational)
  // ========================================================================

  always_comb begin
    read_ptr_plus1_gray = read_ptr_plus1 ^ (read_ptr_plus1 >> 1);         // Convert next read pointer to Gray code
  end

  // ========================================================================
  // WRITE POINTER SYNC - STAGE 1 (Sequential - Read Domain)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync1 <= '0;                                     else // Reset stage 1 synchronizer
                                                        write_ptr_gray_sync1 <= write_ptr_gray;                         // Capture Gray write pointer from write domain
  end

  // ========================================================================
  // WRITE POINTER SYNC - STAGE 2 (Sequential - Read Domain)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       write_ptr_gray_sync2 <= '0;                                     else // Reset stage 2 synchronizer
                                                        write_ptr_gray_sync2 <= write_ptr_gray_sync1;                   // Clean meta-stability
  end

  // ========================================================================
  // READ VALID REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_addr_output_valid <= 1'b0;                                else
    if (!fifo_addr_output_valid && (read_ptr_gray != write_ptr_gray_sync2)) fifo_addr_output_valid <= 1'b1;          else
    if (fifo_addr_pop)                                  fifo_addr_output_valid <= (read_ptr_plus1_gray != write_ptr_gray_sync2);
  end

  // ========================================================================
  // READ ADDRESS REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_addr_output_addr <= '0;                                  else
    if (!fifo_addr_output_valid && (read_ptr_gray != write_ptr_gray_sync2)) fifo_addr_output_addr <= addr_mem[read_ptr[PTR_WIDTH-1:0]]; else
    if (fifo_addr_pop) begin
      if (read_ptr_plus1_gray == write_ptr_gray_sync2)  fifo_addr_output_addr <= '0;                                  else
                                                        fifo_addr_output_addr <= addr_mem[read_ptr_plus1[PTR_WIDTH-1:0]];
    end
  end

  // ========================================================================
  // READ TYPE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge rclk or negedge rresetn) begin
    if (!rresetn)                                       fifo_addr_output_type <= 1'b0;                                 else
    if (!fifo_addr_output_valid && (read_ptr_gray != write_ptr_gray_sync2)) fifo_addr_output_type <= type_mem[read_ptr[PTR_WIDTH-1:0]]; else
    if (fifo_addr_pop) begin
      if (read_ptr_plus1_gray == write_ptr_gray_sync2)  fifo_addr_output_type <= 1'b0;                                else
                                                        fifo_addr_output_type <= type_mem[read_ptr_plus1[PTR_WIDTH-1:0]];
    end
  end

  // ========================================================================
  // READ EMPTY FLAG (Combinational)
  // ========================================================================

  always_comb begin
    if (!rresetn)                                       fifo_addr_empty = 1'b1;                                         else // Default empty flag to 1
                                                        fifo_addr_empty = (read_ptr_gray == write_ptr_gray_sync2);      // Assert empty when read pointer equals synchronized write pointer
  end

  // ========================================================================
  // DEBUG TRACE
  // ========================================================================

  always_ff @(posedge wclk) begin
    if ($test$plusargs("trace_fifo_addr")) begin
      $display("[FIFO_ADDR W] time=%0t awv=%b awr=%b arav=%b arr=%b wp=%0d wp_g=%0b rpg2=%0b full=%b",
               $realtime,
               awvalid, awready,
               arvalid, arready,
               write_ptr,
               write_ptr_gray,
               read_ptr_gray_sync2,
               fifo_addr_full);
    end
  end

  always_ff @(posedge rclk) begin
    if ($test$plusargs("trace_fifo_addr")) begin
      $display("[FIFO_ADDR R] time=%0t rpv=%b rp=%0d rp_g=%0b wp_g1=%0b wp_g2=%0b out_v=%b fifo_empty=%b",
               $realtime,
               fifo_addr_output_valid,
               read_ptr,
               read_ptr_gray,
               write_ptr_gray_sync1,
               write_ptr_gray_sync2,
               fifo_addr_output_valid,
               fifo_addr_empty);
    end
  end

endmodule : fifo_addr
