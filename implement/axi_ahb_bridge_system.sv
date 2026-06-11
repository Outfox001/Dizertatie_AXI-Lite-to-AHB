// ============================================================================
// AXI-Lite to AHB Bridge System Wrapper
// ============================================================================
// This module connects:
// - AXI-Lite controlled register interface
// - AXI-Lite to AHB bridge core
// - AHB RAM slave
//
// Register map:
// 0x00 ADDR
// 0x04 WDATA_LOW
// 0x08 WDATA_HIGH
// 0x0C CMD        bit[0] = start_write, bit[1] = start_read
// 0x10 STATUS     bit[0] = busy, bit[1] = done, bit[2] = error
// 0x14 RDATA_LOW
// 0x18 RDATA_HIGH
// 0x1C RESP
// ============================================================================

module axi_ahb_bridge_system #(
  parameter int FIFO_DEPTH = 16
) (
  // Clock and Reset
  input  logic          clk,                 // System clock from AXI-Lite peripheral
  input  logic          resetn,              // System active-low reset

  // Control Registers from AXI-Lite Wrapper
  input  logic [31:0]   ctrl_addr,           // Target transaction address
  input  logic [31:0]   ctrl_wdata_low,      // Lower 32-bit write data
  input  logic [31:0]   ctrl_wdata_high,     // Upper 32-bit write data
  input  logic [31:0]   ctrl_cmd,            // Command register

  // Status Registers to AXI-Lite Wrapper
  output logic [31:0]   ctrl_status,         // Status register
  output logic [31:0]   ctrl_rdata_low,      // Lower 32-bit read data
  output logic [31:0]   ctrl_rdata_high,     // Upper 32-bit read data
  output logic [31:0]   ctrl_resp            // Response register
);

  import axi_ahb_pkg::*;

  // ========================================================================
  // INTERNAL TYPES & SIGNALS
  // ========================================================================

  typedef enum logic [2:0] {
    SYS_IDLE       = 3'b000,                 // Idle state
    SYS_WRITE_REQ  = 3'b001,                 // Drive bridge write request
    SYS_WRITE_RESP = 3'b010,                 // Wait for bridge write response
    SYS_READ_REQ   = 3'b011,                 // Drive bridge read request
    SYS_READ_RESP  = 3'b100,                 // Wait for bridge read response
    SYS_DONE       = 3'b101                  // Command completed
  } sys_state_t;

  sys_state_t    sys_state_reg;              // Current system FSM state
  sys_state_t    sys_state_nxt;              // Next system FSM state

  // Command tracking
  logic [31:0]   cmd_reg;                    // Delayed command register
  logic          start_write;                // Start write pulse
  logic          start_read;                 // Start read pulse

  // Status registers
  logic          status_done_reg;            // Done status flag
  logic          status_error_reg;           // Error status flag
  logic [1:0]    resp_reg;                   // Captured response code
  logic [31:0]   rdata_low_reg;              // Captured lower read data
  logic [31:0]   rdata_high_reg;             // Captured upper read data

  // Bridge AXI-Lite side signals
  logic [31:0]   core_awaddr;                // Internal bridge AW address
  logic          core_awvalid;               // Internal bridge AW valid
  logic          core_awready;               // Internal bridge AW ready
  logic [63:0]   core_wdata;                 // Internal bridge W data
  logic          core_wvalid;                // Internal bridge W valid
  logic          core_wready;                // Internal bridge W ready
  logic [1:0]    core_bresp;                 // Internal bridge B response
  logic          core_bvalid;                // Internal bridge B valid
  logic          core_bready;                // Internal bridge B ready
  logic [31:0]   core_araddr;                // Internal bridge AR address
  logic          core_arvalid;               // Internal bridge AR valid
  logic          core_arready;               // Internal bridge AR ready
  logic [63:0]   core_rdata;                 // Internal bridge R data
  logic [1:0]    core_rresp;                 // Internal bridge R response
  logic          core_rvalid;                // Internal bridge R valid
  logic          core_rready;                // Internal bridge R ready

  // AHB interconnect signals
  logic [31:0]   ahb_haddr;                  // AHB address
  logic          ahb_hwrite;                 // AHB write control
  logic [2:0]    ahb_hsize;                  // AHB transfer size
  logic [1:0]    ahb_htrans;                 // AHB transfer type
  logic [2:0]    ahb_hburst;                 // AHB burst type
  logic [31:0]   ahb_hwdata;                 // AHB write data
  logic [31:0]   ahb_hrdata;                 // AHB read data
  logic          ahb_hresp;                  // AHB response
  logic          ahb_hready;                 // AHB ready

  // ========================================================================
  // START WRITE CONTROL
  // ========================================================================

  assign start_write = ctrl_cmd[0] && !cmd_reg[0] && (sys_state_reg == SYS_IDLE);                      // Detect rising edge of write command

  // ========================================================================
  // START READ CONTROL
  // ========================================================================

  assign start_read = ctrl_cmd[1] && !cmd_reg[1] && (sys_state_reg == SYS_IDLE);                        // Detect rising edge of read command

  // ========================================================================
  // COMMAND REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       cmd_reg <= '0;                                  else // Reset delayed command register
                                                        cmd_reg <= ctrl_cmd;                            // Capture command register
  end

  // ========================================================================
  // SYSTEM FSM NEXT STATE CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn) begin
      sys_state_nxt = SYS_IDLE;                                                                         // Reset next state
    end else begin
      sys_state_nxt = sys_state_reg;                                                                    // Default next state

      case (sys_state_reg)

        SYS_IDLE: begin
          if (start_write)                              sys_state_nxt = SYS_WRITE_REQ;                 else // Start write command
          if (start_read)                               sys_state_nxt = SYS_READ_REQ;                  else // Start read command
                                                        sys_state_nxt = SYS_IDLE;                      // Stay idle
        end

        SYS_WRITE_REQ: begin
          if (core_awready && core_wready)              sys_state_nxt = SYS_WRITE_RESP;                else // Wait until bridge accepts write request
                                                        sys_state_nxt = SYS_WRITE_REQ;                 // Hold write request
        end

        SYS_WRITE_RESP: begin
          if (core_bvalid)                              sys_state_nxt = SYS_DONE;                      else // Wait for bridge write response
                                                        sys_state_nxt = SYS_WRITE_RESP;                // Hold response wait
        end

        SYS_READ_REQ: begin
          if (core_arready)                             sys_state_nxt = SYS_READ_RESP;                 else // Wait until bridge accepts read request
                                                        sys_state_nxt = SYS_READ_REQ;                  // Hold read request
        end

        SYS_READ_RESP: begin
          if (core_rvalid)                              sys_state_nxt = SYS_DONE;                      else // Wait for bridge read response
                                                        sys_state_nxt = SYS_READ_RESP;                 // Hold response wait
        end

        SYS_DONE: begin
          if (ctrl_cmd[1:0] == 2'b00)                   sys_state_nxt = SYS_IDLE;                      else // Return to idle after software clears command
                                                        sys_state_nxt = SYS_DONE;                      // Hold done until command clear
        end

        default:                                        sys_state_nxt = SYS_IDLE;                      // Failsafe state

      endcase
    end
  end

  // ========================================================================
  // SYSTEM FSM STATE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       sys_state_reg <= SYS_IDLE;                      else // Reset system FSM
                                                        sys_state_reg <= sys_state_nxt;                // Update system FSM
  end

  // ========================================================================
  // STATUS DONE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       status_done_reg <= 1'b0;                        else // Reset done flag
    if (start_write || start_read)                     status_done_reg <= 1'b0;                        else // Clear done on new command
    if ((sys_state_reg == SYS_WRITE_RESP) && core_bvalid)
                                                        status_done_reg <= 1'b1;                        else // Set done after write response
    if ((sys_state_reg == SYS_READ_RESP) && core_rvalid)
                                                        status_done_reg <= 1'b1;                         // Set done after read response
  end

  // ========================================================================
  // STATUS ERROR REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       status_error_reg <= 1'b0;                       else // Reset error flag
    if (start_write || start_read)                     status_error_reg <= 1'b0;                       else // Clear error on new command
    if ((sys_state_reg == SYS_WRITE_RESP) && core_bvalid)
                                                        status_error_reg <= (core_bresp != RESP_OKAY);  else // Capture write error
    if ((sys_state_reg == SYS_READ_RESP) && core_rvalid)
                                                        status_error_reg <= (core_rresp != RESP_OKAY);   // Capture read error
  end

  // ========================================================================
  // RESPONSE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       resp_reg <= RESP_OKAY;                          else // Reset response register
    if (start_write || start_read)                     resp_reg <= RESP_OKAY;                          else // Clear response on new command
    if ((sys_state_reg == SYS_WRITE_RESP) && core_bvalid)
                                                        resp_reg <= core_bresp;                         else // Capture write response
    if ((sys_state_reg == SYS_READ_RESP) && core_rvalid)
                                                        resp_reg <= core_rresp;                          // Capture read response
  end

  // ========================================================================
  // READ DATA LOW REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       rdata_low_reg <= '0;                            else // Reset lower read data
    if ((sys_state_reg == SYS_READ_RESP) && core_rvalid)
                                                        rdata_low_reg <= core_rdata[31:0];              // Capture lower read data
  end

  // ========================================================================
  // READ DATA HIGH REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)                                       rdata_high_reg <= '0;                           else // Reset upper read data
    if ((sys_state_reg == SYS_READ_RESP) && core_rvalid)
                                                        rdata_high_reg <= core_rdata[63:32];            // Capture upper read data
  end

  // ========================================================================
  // CORE WRITE ADDRESS CONTROL
  // ========================================================================

  assign core_awaddr = ctrl_addr;                                                                        // Drive bridge write address

  // ========================================================================
  // CORE WRITE DATA CONTROL
  // ========================================================================

  assign core_wdata = {ctrl_wdata_high, ctrl_wdata_low};                                                 // Drive bridge write data

  // ========================================================================
  // CORE READ ADDRESS CONTROL
  // ========================================================================

  assign core_araddr = ctrl_addr;                                                                        // Drive bridge read address

  // ========================================================================
  // CORE WRITE ADDRESS VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn)                                      core_awvalid = 1'b0;                              else // Default write address valid to 0
                                                       core_awvalid = (sys_state_reg == SYS_WRITE_REQ);  // Assert write address valid during write request
  end

  // ========================================================================
  // CORE WRITE DATA VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn)                                      core_wvalid = 1'b0;                               else // Default write data valid to 0
                                                       core_wvalid = (sys_state_reg == SYS_WRITE_REQ);   // Assert write data valid during write request
  end

  // ========================================================================
  // CORE WRITE RESPONSE READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn)                                      core_bready = 1'b0;                               else // Default write response ready to 0
                                                       core_bready = (sys_state_reg == SYS_WRITE_RESP);  // Accept write response during response wait
  end

  // ========================================================================
  // CORE READ ADDRESS VALID CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn)                                      core_arvalid = 1'b0;                              else // Default read address valid to 0
                                                       core_arvalid = (sys_state_reg == SYS_READ_REQ);   // Assert read address valid during read request
  end

  // ========================================================================
  // CORE READ RESPONSE READY CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!resetn)                                      core_rready = 1'b0;                               else // Default read response ready to 0
                                                       core_rready = (sys_state_reg == SYS_READ_RESP);   // Accept read response during response wait
  end

  // ========================================================================
  // CONTROL STATUS OUTPUT ASSIGNMENT
  // ========================================================================

  assign ctrl_status = {29'b0, status_error_reg, status_done_reg, ((sys_state_reg != SYS_IDLE) && (sys_state_reg != SYS_DONE))}; // Drive status register

  // ========================================================================
  // CONTROL READ DATA LOW OUTPUT ASSIGNMENT
  // ========================================================================

  assign ctrl_rdata_low = rdata_low_reg;                                                                  // Drive lower read data register

  // ========================================================================
  // CONTROL READ DATA HIGH OUTPUT ASSIGNMENT
  // ========================================================================

  assign ctrl_rdata_high = rdata_high_reg;                                                                // Drive upper read data register

  // ========================================================================
  // CONTROL RESPONSE OUTPUT ASSIGNMENT
  // ========================================================================

  assign ctrl_resp = {30'b0, resp_reg};                                                                   // Drive response register

  // ========================================================================
  // INSTANTIATE AXI-LITE TO AHB BRIDGE CORE
  // ========================================================================

  axi_ahb_bridge_core #(
    .FIFO_DEPTH(FIFO_DEPTH)
  ) bridge_core_inst (
    .aclk(clk),
    .aresetn(resetn),
    .hclk(clk),
    .hresetn(resetn),

    .awaddr(core_awaddr),
    .awvalid(core_awvalid),
    .awready(core_awready),
    .wdata(core_wdata),
    .wvalid(core_wvalid),
    .wready(core_wready),
    .bresp(core_bresp),
    .bvalid(core_bvalid),
    .bready(core_bready),
    .araddr(core_araddr),
    .arvalid(core_arvalid),
    .arready(core_arready),
    .rdata(core_rdata),
    .rresp(core_rresp),
    .rvalid(core_rvalid),
    .rready(core_rready),

    .haddr(ahb_haddr),
    .hwrite(ahb_hwrite),
    .hsize(ahb_hsize),
    .htrans(ahb_htrans),
    .hburst(ahb_hburst),
    .hwdata(ahb_hwdata),
    .hrdata(ahb_hrdata),
    .hresp(ahb_hresp),
    .hready(ahb_hready)
  );

  // ========================================================================
  // INSTANTIATE AHB RAM SLAVE
  // ========================================================================

  ahb_ram_slave ahb_ram_slave_inst (
    .hclk(clk),
    .hresetn(resetn),
    .haddr(ahb_haddr),
    .hwrite(ahb_hwrite),
    .hsize(ahb_hsize),
    .htrans(ahb_htrans),
    .hburst(ahb_hburst),
    .hwdata(ahb_hwdata),
    .hrdata(ahb_hrdata),
    .hresp(ahb_hresp),
    .hready(ahb_hready)
  );

endmodule : axi_ahb_bridge_system