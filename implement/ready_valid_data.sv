// ============================================================================
// Ready/Valid Logic for Data FIFO Output - Data Width Conversion
// ============================================================================
// Converts 64-bit FIFO data into two 32-bit transfers to AHB:
// - First transfer: data_lower[31:0]
// - Second transfer: data_upper[31:0]
// ============================================================================

module ready_valid_data (
  input  logic                 hclk,            // AHB clock domain
  input  logic                 hresetn,         // AHB active-low reset

  // From Data FIFO
  input  logic [63:0]          fifo_data,       // FIFO data
  input  logic                 fifo_data_valid, // FIFO data valid
  output logic                 fifo_data_pop,   // FIFO data pop

  // Ready/Valid output interface
  output logic [31:0]          data_lower,      // Lower output data
  output logic [31:0]          data_upper,      // Upper output data
  output logic                 data_valid,      // Output data valid
  input  logic                 data_ready       // Output data ready
);

  // Internal ready/valid stage registers
  logic [31:0]                 data_lower_reg;  // Registered lower data
  logic [31:0]                 data_upper_reg;  // Registered upper data
  logic                        data_valid_reg;  // Registered valid flag

  // Internal control signals
  logic                        data_load;       // Data load condition
  logic                        data_consume;    // Data consume condition

  // ========================================================================
  // DATA LOAD CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   data_load = 1'b0;                              else // Default load condition to 0
                                                    data_load = !data_valid_reg && fifo_data_valid; // Load when stage is empty and FIFO has valid data
  end

  // ========================================================================
  // DATA CONSUME CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   data_consume = 1'b0;                           else // Default consume condition to 0
                                                    data_consume = data_valid_reg && data_ready;    // Consume when data is valid and bridge is ready
  end

  // ========================================================================
  // DATA LOWER REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   data_lower_reg <= '0;                          else // Reset lower data register
    if (data_load)                                  data_lower_reg <= fifo_data[31:0];              // Capture lower 32 bits from FIFO data
  end

  // ========================================================================
  // DATA UPPER REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   data_upper_reg <= '0;                          else // Reset upper data register
    if (data_load)                                  data_upper_reg <= fifo_data[63:32];             // Capture upper 32 bits from FIFO data
  end

  // ========================================================================
  // DATA VALID REGISTER UPDATE (Sequential)
  // ========================================================================

  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn)                                   data_valid_reg <= 1'b0;                        else // Reset valid register
    if (data_consume)                               data_valid_reg <= 1'b0;                        else // Clear valid after bridge consumes data
    if (data_load)                                  data_valid_reg <= 1'b1;                        // Assert valid after data load
  end

  // ========================================================================
  // DATA LOWER OUTPUT ASSIGNMENT
  // ========================================================================

  assign data_lower = data_lower_reg;                                                                // Drive lower output data

  // ========================================================================
  // DATA UPPER OUTPUT ASSIGNMENT
  // ========================================================================

  assign data_upper = data_upper_reg;                                                                // Drive upper output data

  // ========================================================================
  // DATA VALID OUTPUT ASSIGNMENT
  // ========================================================================

  assign data_valid = data_valid_reg;                                                                // Drive output valid

  // ========================================================================
  // FIFO DATA POP CONTROL (Combinational)
  // ========================================================================

  always_comb begin
    if (!hresetn)                                   fifo_data_pop = 1'b0;                           else // Default FIFO pop to 0
                                                    fifo_data_pop = data_load;                       // Pop FIFO when loading data into stage
  end

endmodule : ready_valid_data