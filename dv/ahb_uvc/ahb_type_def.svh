typedef enum {MASTER, SLAVE} agent_type_t;

typedef enum logic [1:0] {
  IDLE    = 2'b00,
  BUSY    = 2'b01,
  NONSEQ  = 2'b10,
  SEQ     = 2'b11
} ahb_trans_e;

typedef enum logic [2:0] {
  SINGLE   = 3'b000,
  INCR     = 3'b001,
  WRAP4    = 3'b010,
  INCR4    = 3'b011,
  WRAP8    = 3'b100,
  INCR8    = 3'b101,
  WRAP16   = 3'b110,
  INCR16   = 3'b111
} ahb_burst_e;
