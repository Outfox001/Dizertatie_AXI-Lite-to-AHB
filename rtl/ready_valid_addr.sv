// ============================================================================
// Ready/Valid Logic for Address FIFO Output
// ============================================================================
// Passes FIFO address and transaction type to the bridge FSM:
// - Address is forwarded unchanged
// - Transaction type is forwarded unchanged
// ============================================================================

module ready_valid_addr (
  input  logic                 hclk,            // AHB clock domain
  input  logic                 hresetn,         // AHB active-low reset

  // From Address FIFO
  input  logic [31:0]          fifo_addr,       // FIFO address
  input  logic                 fifo_rtype,      // FIFO transaction type
  input  logic                 fifo_addr_valid, // FIFO address valid
  output logic                 fifo_addr_pop,   // FIFO address pop

  // Ready/Valid output interface
  output logic [31:0]          addr_out,        // Output address
  output logic                 rtype_out,       // Output transaction type
  output logic                 addr_valid,      // Output valid
  input  logic                 addr_ready       // Output ready
);

  // Internal ready/valid stage registers
  logic [31:0]                 addr_out_reg;    // Registered output address
  logic                        rtype_out_reg;   // Registered output transaction type
  logic                        addr_valid_reg;  // Registered output valid flag

  // Internal control signals
  logic                        addr_load;       // Address load condition
  logic                        addr_consume;    // Address consume condition

  // ========================================================================
  // ADDRESS LOAD CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   addr_load = 1'b0;                              else // Default load condition to 0
                                                    addr_load = !addr_valid_reg && fifo_addr_valid; // Load when stage is empty and FIFO has valid address
  end

  // ========================================================================
  // ADDRESS CONSUME CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   addr_consume = 1'b0;                           else // Default consume condition to 0
                                                    addr_consume = addr_valid_reg && addr_ready;    // Consume when address is valid and bridge is ready
  end

  // ========================================================================
  // ADDRESS OUTPUT REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   addr_out_reg <= '0;                            else // Reset address register
    if (addr_load)                                  addr_out_reg <= fifo_addr;                      // Capture FIFO address
  end

  // ========================================================================
  // ADDRESS TYPE REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   rtype_out_reg <= 1'b0;                         else // Reset transaction type register
    if (addr_load)                                  rtype_out_reg <= fifo_rtype;                    // Capture FIFO transaction type
  end

  // ========================================================================
  // ADDRESS VALID REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   addr_valid_reg <= 1'b0;                        else // Reset valid register
    if (addr_consume)                               addr_valid_reg <= 1'b0;                        else // Clear valid after bridge consumes address
    if (addr_load)                                  addr_valid_reg <= 1'b1;                        // Assert valid after address load
  end

  // ========================================================================
  // ADDRESS OUTPUT ASSIGNMENT
  // ========================================================================

  assign addr_out = addr_out_reg;                                                                    // Drive output address

  // ========================================================================
  // ADDRESS TYPE OUTPUT ASSIGNMENT
  // ========================================================================

  assign rtype_out = rtype_out_reg;                                                                  // Drive output transaction type

  // ========================================================================
  // ADDRESS VALID OUTPUT ASSIGNMENT
  // ========================================================================

  assign addr_valid = addr_valid_reg;                                                                // Drive output valid

  // ========================================================================
  // FIFO ADDRESS POP CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   fifo_addr_pop = 1'b0;                           else // Default FIFO pop to 0
                                                    fifo_addr_pop = addr_load;                       // Pop FIFO when loading address into stage
  end

endmodule : ready_valid_addr