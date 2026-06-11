// ============================================================================
// AXI-Lite to AHB Bridge Core - Main Orchestration Logic
// ============================================================================

module axi_ahb_bridge_core #(
  parameter int FIFO_DEPTH = 16
) (
  // Clock and Reset
  input  logic          aclk,                // AXI clock domain
  input  logic          aresetn,             // AXI active-low reset
  input  logic          hclk,                // AHB clock domain
  input  logic          hresetn,             // AHB active-low reset

  // AXI-Lite Slave Ports
  input  logic [31:0]   awaddr,              // AXI write address
  input  logic          awvalid,             // AXI write address valid
  output logic          awready,             // AXI write address ready
  input  logic [63:0]   wdata,               // AXI write data
  input  logic          wvalid,              // AXI write data valid
  output logic          wready,              // AXI write data ready
  output logic [1:0]    bresp,               // AXI write response code
  output logic          bvalid,              // AXI write response valid
  input  logic          bready,              // AXI write response ready
  input  logic [31:0]   araddr,              // AXI read address
  input  logic          arvalid,             // AXI read address valid
  output logic          arready,             // AXI read address ready
  output logic [63:0]   rdata,               // AXI read data
  output logic [1:0]    rresp,               // AXI read response code
  output logic          rvalid,              // AXI read data valid
  input  logic          rready,              // AXI read data ready

  // AHB Master Ports
  output logic [31:0]   haddr,               // AHB transfer address
  output logic          hwrite,              // AHB transfer direction
  output logic [2:0]    hsize,               // AHB transfer size
  output logic [1:0]    htrans,              // AHB transfer type
  output logic [2:0]    hburst,              // AHB burst type
  output logic [31:0]   hwdata,              // AHB write data
  input  logic [31:0]   hrdata,              // AHB read data
  input  logic          hresp,               // AHB response from slave
  input  logic          hready               // AHB ready from slave
);

  import axi_ahb_pkg::*;

  // ========================================================================
  // INTERNAL TYPES & SIGNALS
  // ========================================================================

  typedef enum logic [2:0] {
    ST_IDLE       = 3'b000,                  // Idle state
    ST_WRITE_ADDR = 3'b001,                  // Write address phase
    ST_WRITE_DATA = 3'b010,                  // Write data phase
    ST_READ_ADDR  = 3'b011,                  // Read address phase
    ST_READ_DATA  = 3'b100                   // Read data phase
  } state_t;

  state_t       state_reg;                   // Current FSM state
  state_t       state_nxt;                   // Next FSM state

  // Shared Address FIFO Signals
  logic [31:0]  shared_fifo_addr;            // Address FIFO output address
  logic         shared_fifo_rtype;           // Address FIFO output type
  logic         shared_fifo_rvalid;          // Address FIFO output valid
  logic         shared_fifo_rready;          // Address FIFO read ready
  logic         shared_fifo_rpop;            // Address FIFO pop
  logic         shared_fifo_rempty;          // Address FIFO empty
  logic         shared_fifo_awvalid;         // Address FIFO write valid for AW
  logic         shared_fifo_awready;         // Address FIFO write ready for AW

  // Write Data FIFO Signals
  logic [63:0]  wdata_fifo_data;             // Data FIFO output data
  logic         wdata_fifo_wvalid;           // Data FIFO write valid
  logic         wdata_fifo_wready;           // Data FIFO write ready
  logic         wdata_fifo_wfull;            // Data FIFO full
  logic         wdata_fifo_rvalid;           // Data FIFO read valid
  logic         wdata_fifo_rready;           // Data FIFO read ready
  logic         wdata_fifo_rpop;             // Data FIFO pop
  logic         wdata_fifo_rempty;           // Data FIFO empty

  // Response FIFO Signals
  logic         resp_fifo_rtype;             // Response FIFO output type
  logic [63:0]  resp_fifo_rrdata;            // Response FIFO output data
  logic [1:0]   resp_fifo_rresp;             // Response FIFO output response
  logic         resp_fifo_rvalid;            // Response FIFO output valid
  logic         resp_fifo_rready;            // Response FIFO read ready
  logic         resp_fifo_rempty;            // Response FIFO empty
  logic [63:0]  resp_fifo_wrdata;            // Response FIFO input data
  logic [1:0]   resp_fifo_wresp;             // Response FIFO input response
  logic         resp_fifo_wvalid;            // Response FIFO write valid
  logic         resp_fifo_wready;            // Response FIFO write ready
  logic         resp_fifo_wfull;             // Response FIFO full
  logic         resp_fifo_wtype;             // Response FIFO input type

  // Ready/Valid Address Signals
  logic [31:0]  shared_rv_addr;              // Ready/valid address
  logic         shared_rv_rtype;             // Ready/valid transaction type
  logic         shared_rv_valid;             // Ready/valid address valid
  logic         shared_rv_ready;             // Ready/valid address ready
  logic         shared_rv_pop;               // Ready/valid address pop

  // Ready/Valid Data Signals
  logic [31:0]  wdata_rv_lower;              // Ready/valid lower data
  logic [31:0]  wdata_rv_upper;              // Ready/valid upper data
  logic         wdata_rv_valid;              // Ready/valid data valid
  logic         wdata_rv_ready;              // Ready/valid data ready
  logic         wdata_rv_pop;                // Ready/valid data pop

  // AHB Master Data/Control Latches
  logic [31:0]  write_addr_reg;              // Latched write address
  logic [63:0]  write_data_reg;              // Latched write data
  logic [31:0]  read_addr_reg;               // Latched read address
  logic [31:0]  read_data_low;               // Latched low read data
  logic [1:0]   resp_code_reg;               // Latched AHB response code
  logic         resp_pending;                // Pending response flag
  logic         resp_is_write;               // Pending response type

  // AHB Accept Control Signals
  logic         accept_slot;                 // Transaction accept slot
  logic         accept_write;                // Write accept condition
  logic         accept_read;                 // Read accept condition
  logic         response_push;               // Response FIFO push handshake

  // AHB Write Data Pipeline Register
  logic [31:0]  hwdata_reg;                  // Registered AHB write data

  // ========================================================================
  // INSTANTIATE FIFOs
  // ========================================================================

  fifo_addr shared_addr_fifo (
    .wclk(aclk), .wresetn(aresetn),
    .awaddr(awaddr), .awvalid(shared_fifo_awvalid), .awready(shared_fifo_awready),
    .araddr(araddr), .arvalid(arvalid), .arready(arready), .fifo_addr_full(),
    .rclk(hclk), .rresetn(hresetn),
    .fifo_addr_output_addr(shared_fifo_addr),
    .fifo_addr_output_type(shared_fifo_rtype),
    .fifo_addr_output_valid(shared_fifo_rvalid),
    .valid_ready_addr_ready(shared_fifo_rready),
    .fifo_addr_pop(shared_fifo_rpop),
    .fifo_addr_empty(shared_fifo_rempty)
  );

  fifo_data write_data_fifo (
    .wclk(aclk), .wresetn(aresetn),
    .wdata(wdata), .wvalid(wdata_fifo_wvalid), .wready(wdata_fifo_wready), .fifo_data_full(wdata_fifo_wfull),
    .rclk(hclk), .rresetn(hresetn),
    .fifo_data_output_data(wdata_fifo_data),
    .fifo_data_output_valid(wdata_fifo_rvalid),
    .valid_ready_data_ready(wdata_fifo_rready),
    .fifo_data_pop(wdata_fifo_rpop),
    .fifo_data_empty(wdata_fifo_rempty)
  );

  fifo_response response_fifo (
    .wclk(hclk), .wresetn(hresetn),
    .wtype(resp_fifo_wtype), .wrdata(resp_fifo_wrdata), .wresp(resp_fifo_wresp),
    .core_resp_valid(resp_fifo_wvalid), .core_resp_ready(resp_fifo_wready), .fifo_response_full(resp_fifo_wfull),
    .rclk(aclk), .rresetn(aresetn),
    .fifo_response_output_type(resp_fifo_rtype),
    .fifo_response_output_data(resp_fifo_rrdata),
    .fifo_response_output_resp(resp_fifo_rresp),
    .fifo_response_output_valid(resp_fifo_rvalid),
    .axi_resp_ready(resp_fifo_rready),
    .fifo_response_empty(resp_fifo_rempty)
  );

  // ========================================================================
  // AXI WRITE ADDRESS FIFO VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                     shared_fifo_awvalid = 1'b0;                                     else // Default AW FIFO valid to 0
                                                        shared_fifo_awvalid = awvalid && wdata_fifo_wready;             // Push AW only if data FIFO can accept
  end

  // ========================================================================
  // AXI WRITE DATA FIFO VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                     wdata_fifo_wvalid = 1'b0;                                       else // Default W FIFO valid to 0
                                                        wdata_fifo_wvalid = wvalid;                                     // Pass W valid to data FIFO
  end

  // ========================================================================
  // RESPONSE FIFO READ READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                     resp_fifo_rready = 1'b0;                                        else // Default response ready to 0
                                                        resp_fifo_rready = ((resp_fifo_rtype == 1'b1) && bready && resp_fifo_rvalid) ||
                                                                           ((resp_fifo_rtype == 1'b0) && rready && resp_fifo_rvalid); // Consume matching AXI response
  end

  // ========================================================================
  // INSTANTIATE READY/VALID STAGES
  // ========================================================================

  ready_valid_addr shared_addr_rv (
    .hclk(hclk), .hresetn(hresetn),
    .fifo_addr(shared_fifo_addr), .fifo_rtype(shared_fifo_rtype), .fifo_addr_valid(shared_fifo_rvalid), .fifo_addr_pop(shared_rv_pop),
    .addr_out(shared_rv_addr), .rtype_out(shared_rv_rtype), .addr_valid(shared_rv_valid), .addr_ready(shared_rv_ready)
  );

  ready_valid_data write_data_rv (
    .hclk(hclk), .hresetn(hresetn),
    .fifo_data(wdata_fifo_data), .fifo_data_valid(wdata_fifo_rvalid), .fifo_data_pop(wdata_rv_pop),
    .data_lower(wdata_rv_lower), .data_upper(wdata_rv_upper), .data_valid(wdata_rv_valid), .data_ready(wdata_rv_ready)
  );

  // ========================================================================
  // RESPONSE PUSH CONTROL
  // ========================================================================

  assign response_push = resp_pending && resp_fifo_wready;                                                            // Response accepted by response FIFO

  // ========================================================================
  // TRANSACTION ACCEPT SLOT CONTROL
  // ========================================================================

  assign accept_slot = ((state_reg == ST_IDLE) ||
                        (state_reg == ST_WRITE_DATA) ||
                        (state_reg == ST_READ_DATA)) &&
                        hready &&
                        resp_fifo_wready &&
                       !resp_pending;                                                                                 // Accept only when response path is free

  // ========================================================================
  // WRITE ACCEPT CONTROL
  // ========================================================================

  assign accept_write = accept_slot &&
                        shared_rv_valid &&
                        shared_rv_rtype &&
                        wdata_rv_valid;                                                                               // Accept complete write request

  // ========================================================================
  // READ ACCEPT CONTROL
  // ========================================================================

  assign accept_read = accept_slot &&
                       shared_rv_valid &&
                      !shared_rv_rtype;                                                                               // Accept complete read request

  // ========================================================================
  // ADDRESS FIFO READ READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                     shared_fifo_rready = 1'b0;                                      else // Default address FIFO ready to 0
                                                        shared_fifo_rready = shared_rv_pop;                             // Pop address FIFO from ready/valid stage
  end

  // ========================================================================
  // DATA FIFO READ READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                     wdata_fifo_rready = 1'b0;                                       else // Default data FIFO ready to 0
                                                        wdata_fifo_rready = wdata_rv_pop;                               // Pop data FIFO from ready/valid stage
  end

  // ========================================================================
  // AXI WRITE ADDRESS READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                     awready = 1'b0;                                                 else // Default AW ready to 0
                                                        awready = shared_fifo_awready && wdata_fifo_wready;             // Accept AW only when both paths can accept
  end

  // ========================================================================
  // AXI WRITE DATA READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                     wready = 1'b0;                                                  else // Default W ready to 0
                                                        wready = wdata_fifo_wready;                                     // Accept W when data FIFO can accept
  end

  // ========================================================================
  // FSM NEXT STATE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn) begin
      state_nxt = ST_IDLE;                                                                                            // Reset next state to IDLE
    end else begin
      state_nxt = state_reg;                                                                                          // Default next state is current state

      case (state_reg)

        ST_IDLE: begin
          if (accept_write)                              state_nxt = ST_WRITE_ADDR;                                   else // Start write transfer
          if (accept_read)                               state_nxt = ST_READ_ADDR;                                    else // Start read transfer
                                                          state_nxt = ST_IDLE;                                         // Stay idle
        end

        ST_WRITE_ADDR: begin
          if (hready)                                    state_nxt = ST_WRITE_DATA;                                   // Continue write transfer
        end

        ST_WRITE_DATA: begin
          if (hready) begin
            if (accept_write)                            state_nxt = ST_WRITE_ADDR;                                   else // Pipeline next write
            if (accept_read)                             state_nxt = ST_READ_ADDR;                                    else // Pipeline next read
                                                          state_nxt = ST_IDLE;                                         // Return idle
          end
        end

        ST_READ_ADDR: begin
          if (hready)                                    state_nxt = ST_READ_DATA;                                    // Continue read transfer
        end

        ST_READ_DATA: begin
          if (hready) begin
            if (accept_write)                            state_nxt = ST_WRITE_ADDR;                                   else // Pipeline next write
            if (accept_read)                             state_nxt = ST_READ_ADDR;                                    else // Pipeline next read
                                                          state_nxt = ST_IDLE;                                         // Return idle
          end
        end

        default:                                         state_nxt = ST_IDLE;                                         // Failsafe state

      endcase
    end
  end

  // ========================================================================
  // FSM STATE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   state_reg <= ST_IDLE;                              else // Reset FSM state
    if (hready || state_reg == ST_IDLE)                             state_reg <= state_nxt;                            // Update FSM state
  end

  // ========================================================================
  // WRITE ADDRESS REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   write_addr_reg <= '0;                              else // Reset write address register
    if (accept_write)                                               write_addr_reg <= shared_rv_addr;                  // Latch write address
  end

  // ========================================================================
  // WRITE DATA REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   write_data_reg <= '0;                              else // Reset write data register
    if (accept_write)                                               write_data_reg <= {wdata_rv_upper, wdata_rv_lower}; // Latch write data
  end

  // ========================================================================
  // READ ADDRESS REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   read_addr_reg <= '0;                               else // Reset read address register
    if (accept_read)                                                read_addr_reg <= shared_rv_addr;                   // Latch read address
  end

  // ========================================================================
  // READ DATA LOW REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   read_data_low <= '0;                               else // Reset low read data register
    if (state_reg == ST_READ_DATA && hready)                        read_data_low <= hrdata;                           // Capture low read data
  end

  // ========================================================================
  // RESPONSE CODE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   resp_code_reg <= RESP_OKAY;                        else // Reset response code
    if ((state_reg == ST_WRITE_DATA || state_reg == ST_READ_DATA) && hready)
                                                                    resp_code_reg <= (hresp == 1'b1) ? RESP_SLVERR : RESP_OKAY; else // Capture AHB slave error
    if (response_push)                                              resp_code_reg <= RESP_OKAY;                        // Clear response code
  end

  // ========================================================================
  // RESPONSE PENDING REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   resp_pending <= 1'b0;                              else // Reset response pending
    if ((state_reg == ST_WRITE_DATA || state_reg == ST_READ_DATA) && hready)
                                                                    resp_pending <= 1'b1;                              else // Mark response pending
    if (response_push)                                              resp_pending <= 1'b0;                              // Clear response pending
  end

  // ========================================================================
  // RESPONSE TYPE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   resp_is_write <= 1'b0;                             else // Reset response type
    if ((state_reg == ST_WRITE_DATA || state_reg == ST_READ_DATA) && hready)
                                                                    resp_is_write <= (state_reg == ST_WRITE_DATA);     // Store response type
  end

  // ========================================================================
  // ADDRESS READY/VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   shared_rv_ready = 1'b0;                            else // Default address ready to 0
                                                                    shared_rv_ready = accept_write || accept_read;      // Consume accepted address
  end

  // ========================================================================
  // DATA READY/VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   wdata_rv_ready = 1'b0;                             else // Default data ready to 0
                                                                    wdata_rv_ready = accept_write;                     // Consume accepted write data
  end

  // ========================================================================
  // AHB ADDRESS OUTPUT CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   haddr = '0;                                        else // Default address
    if (state_reg == ST_WRITE_ADDR)                                 haddr = write_addr_reg;                            else // First write address
    if (state_reg == ST_READ_ADDR)                                  haddr = read_addr_reg;                             else // First read address
    if (state_reg == ST_WRITE_DATA)                                 haddr = write_addr_reg + 32'h4;                    else // Second write address
    if (state_reg == ST_READ_DATA)                                  haddr = read_addr_reg + 32'h4;                     else // Second read address
                                                                    haddr = '0;                                        // Idle address
  end

  // ========================================================================
  // AHB WRITE ENABLE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   hwrite = 1'b0;                                     else // Default read transfer
    if (state_reg == ST_WRITE_ADDR)                                 hwrite = 1'b1;                                     else // Write first beat
    if (state_reg == ST_WRITE_DATA)                                 hwrite = 1'b1;                                     else // Write second beat
                                                                    hwrite = 1'b0;                                     // Read or idle
  end

  // ========================================================================
  // AHB TRANSFER TYPE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   htrans = HTRANS_IDLE;                              else // Default transfer type
    if (state_reg == ST_WRITE_ADDR)                                 htrans = HTRANS_NONSEQ;                            else // First write beat
    if (state_reg == ST_READ_ADDR)                                  htrans = HTRANS_NONSEQ;                            else // First read beat
    if (state_reg == ST_WRITE_DATA)                                 htrans = HTRANS_SEQ;                               else // Second write beat
    if (state_reg == ST_READ_DATA)                                  htrans = HTRANS_SEQ;                               else // Second read beat
                                                                    htrans = HTRANS_IDLE;                              // Idle transfer
  end

  // ========================================================================
  // AHB SIZE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   hsize = '0;                                        else // Default size
                                                                    hsize = HSIZE_32;                                  // Fixed 32-bit size
  end

  // ========================================================================
  // AHB BURST CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   hburst = '0;                                       else // Default burst
                                                                    hburst = 3'b000;                                   // SINGLE burst
  end

  // ========================================================================
  // AHB WRITE DATA REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                                   hwdata_reg <= '0;                                  else // Reset write data output
    if (hready && state_reg == ST_WRITE_ADDR)                       hwdata_reg <= write_data_reg[31:0];                else // Drive lower data
    if (hready && state_reg == ST_WRITE_DATA)                       hwdata_reg <= write_data_reg[63:32];               else // Drive upper data
    if (hready)                                                     hwdata_reg <= '0;                                  // Clear outside write
  end

  // ========================================================================
  // AHB WRITE DATA OUTPUT ASSIGNMENT
  // ========================================================================

  assign hwdata = hwdata_reg;                                                                                         // Drive AHB write data

  // ========================================================================
  // RESPONSE FIFO WRITE DATA CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   resp_fifo_wrdata = '0;                             else // Default response data
    if (resp_is_write)                                              resp_fifo_wrdata = 64'b0;                          else // Empty write response data
                                                                    resp_fifo_wrdata = {hrdata, read_data_low};         // Combine read data beats
  end

  // ========================================================================
  // RESPONSE FIFO WRITE RESPONSE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   resp_fifo_wresp = RESP_OKAY;                       else // Default response OKAY
                                                                    resp_fifo_wresp = (resp_code_reg == RESP_SLVERR || hresp) ? RESP_SLVERR : RESP_OKAY; // Propagate AHB slave error
  end

  // ========================================================================
  // RESPONSE FIFO WRITE VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   resp_fifo_wvalid = 1'b0;                           else // Default response valid
                                                                    resp_fifo_wvalid = resp_pending;                   // Hold valid while pending
  end

  // ========================================================================
  // RESPONSE FIFO WRITE TYPE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                                   resp_fifo_wtype = 1'b0;                            else // Default response type
                                                                    resp_fifo_wtype = resp_is_write;                   // Drive response type
  end

  // ========================================================================
  // AXI WRITE RESPONSE VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                                   bvalid = 1'b0;                                    else // Default B valid
                                                                    bvalid = resp_fifo_rvalid && (resp_fifo_rtype == 1'b1); // Write response valid
  end

  // ========================================================================
  // AXI WRITE RESPONSE CODE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                                   bresp = RESP_OKAY;                                else // Default B response to OKAY
    if (resp_fifo_rvalid && (resp_fifo_rtype == 1'b1))               bresp = resp_fifo_rresp;                          else // Drive B response only when FIFO item is write response
                                                                    bresp = RESP_OKAY;                                // Keep OKAY when no valid write response
  end

  // ========================================================================
  // AXI READ DATA VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                                   rvalid = 1'b0;                                    else // Default R valid
                                                                    rvalid = resp_fifo_rvalid && (resp_fifo_rtype == 1'b0); // Read response valid
  end

  // ========================================================================
  // AXI READ DATA CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                                   rdata = '0;                                      else // Default R data to 0
    if (resp_fifo_rvalid && (resp_fifo_rtype == 1'b0))               rdata = resp_fifo_rrdata;                         else // Drive R data only when FIFO item is read response
                                                                    rdata = '0;                                      // Keep R data at 0 when no valid read response
  end

  // ========================================================================
  // AXI READ RESPONSE CODE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!aresetn)                                                   rresp = RESP_OKAY;                                else // Default R response to OKAY
    if (resp_fifo_rvalid && (resp_fifo_rtype == 1'b0))               rresp = resp_fifo_rresp;                          else // Drive R response only when FIFO item is read response
                                                                    rresp = RESP_OKAY;                                // Keep OKAY when no valid read response
  end

endmodule : axi_ahb_bridge_core