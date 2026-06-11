# Bridge Register Definition v0.2 (April 16, 2026)

**Synchronized with:**

- AXI_Lite_to_AHB_High-Level_Specifications.md (v0.2)
- AXI_Lite_to_AHB_Low-Level_Specifications.md (v0.2)

**Key Changes:**

- Dual-clock FIFO architecture with built-in Gray-coded pointer synchronization
- Unified Response FIFO for both write and read responses
- Outstanding Requests Register for response type tracking
- 2-stage synchronizer chains for safe clock domain crossing (~2-3 cycles latency)

---

## AXI Lite Interface Registers (AXI Clock Domain - 800 MHz)

### AXI Write Address Channel

| Register Name    | Width | Description |
|-----------------|-------|-------------|
| awaddr_reg      | 32    | Captured write address (from awaddr) |
| awvalid_latch   | 1     | Latched write address valid |
| awready_out     | 1     | Write address ready output (from addr FIFO not-full) |

### AXI Write Data Channel

| Register Name    | Width | Description |
|-----------------|-------|-------------|
| wdata_reg       | 64    | Captured 64-bit write data (from wdata) |
| wvalid_latch    | 1     | Latched write data valid |
| wready_out      | 1     | Write data ready output (from data FIFO not-full) |

### AXI Write Response Channel

| Register Name    | Width | Description |
|-----------------|-------|-------------|
| bresp_out       | 2     | Write response output (from response FIFO) |
| bvalid_out      | 1     | Write response valid (from response FIFO rvalid) |
| bready_latch    | 1     | Latched write response ready (from bready) |

### AXI Read Address Channel

| Register Name    | Width | Description |
|-----------------|-------|-------------|
| araddr_reg      | 32    | Captured read address (from araddr) |
| arvalid_latch   | 1     | Latched read address valid |
| arready_out     | 1     | Read address ready output (from addr FIFO not-full) |

### AXI Read Data Channel

| Register Name    | Width | Description |
|-----------------|-------|-------------|
| rdata_out       | 64    | Read data output (from response FIFO) |
| rresp_out       | 2     | Read response output (from response FIFO) |
| rvalid_out      | 1     | Read data valid (from response FIFO rvalid) |
| rready_latch    | 1     | Latched read data ready (from rready) |

## Dual-Clock Address FIFO (Shared by Read & Write)

### FIFO Memory and Pointers (AXI Write Domain - 800 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| addr_fifo_mem[16] | 32    | Address FIFO memory array (16 entries, 32-bit each) |
| wr_addr_ptr       | 4     | Binary write pointer (write domain) |
| wr_addr_ptr_gray  | 4     | Gray-coded write pointer (synchronized to read domain) |
| wr_addr_full      | 1     | FIFO full flag (write domain - address) |
| wr_addr_count     | 5     | Write-side count of valid entries |

### FIFO Memory and Pointers (AHB Read Domain - 400 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| rd_addr_ptr       | 4     | Binary read pointer (read domain) |
| rd_addr_ptr_gray  | 4     | Gray-coded read pointer (synchronized to write domain) |
| rd_addr_empty     | 1     | FIFO empty flag (read domain - address) |
| rd_addr_count     | 5     | Read-side count of valid entries |
| rd_addr_out       | 32    | Address data output from FIFO |
| rd_addr_valid     | 1     | Address valid output flag |

---

## Dual-Clock Data FIFO (Write Path Only)

### FIFO Memory and Pointers (AXI Write Domain - 800 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| data_fifo_mem[16] | 64    | Data FIFO memory array (16 entries, 64-bit each) |
| wr_data_ptr       | 4     | Binary write pointer (write domain) |
| wr_data_ptr_gray  | 4     | Gray-coded write pointer (synchronized to read domain) |
| wr_data_full      | 1     | FIFO full flag (write domain - data) |
| wr_data_count     | 5     | Write-side count of valid entries |

### FIFO Memory and Pointers (AHB Read Domain - 400 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| rd_data_ptr       | 4     | Binary read pointer (read domain) |
| rd_data_ptr_gray  | 4     | Gray-coded read pointer (synchronized to write domain) |
| rd_data_empty     | 1     | FIFO empty flag (read domain - data) |
| rd_data_count     | 5     | Read-side count of valid entries |
| rd_data_out       | 64    | Data output from FIFO (64-bit) |
| rd_data_valid     | 1     | Data valid output flag |

## Dual-Clock Response FIFO (Unified for Read & Write)

**Purpose:** Single dual-clock FIFO stores both write responses (2-bit `bresp` + 64-bit don't-care) and read responses (2-bit `rresp` + 64-bit read data). Both types share the same 66-bit physical FIFO; Bridge Core Logic distinguishes via Outstanding Requests Register.

### FIFO Memory and Pointers (AHB Write Domain - 400 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| resp_fifo_mem[16] | 66    | Response FIFO memory (16 entries: 64-bit data + 2-bit response) |
| wr_resp_ptr       | 4     | Binary write pointer (write domain) |
| wr_resp_ptr_gray  | 4     | Gray-coded write pointer (synchronized to read domain) |
| wr_resp_full      | 1     | FIFO full flag (write domain) |
| wr_resp_data_in   | 64    | Write data input (read data for reads, don't-care for writes) |
| wr_resp_code_in   | 2     | Write response code input (hresp from AHB) |

### FIFO Memory and Pointers (AXI Read Domain - 800 MHz)

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| rd_resp_ptr       | 4     | Binary read pointer (read domain) |
| rd_resp_ptr_gray  | 4     | Gray-coded read pointer (synchronized to write domain) |
| rd_resp_empty     | 1     | FIFO empty flag (read domain) |
| rd_resp_count     | 5     | Read-side count of valid entries |
| rd_resp_data_out  | 64    | Response data output (read data for reads) |
| rd_resp_code_out  | 2     | Response code output (bresp/rresp) |
| rd_resp_valid     | 1     | Response valid output flag |

---

## Dual-Clock FIFO Synchronizer Registers (Built-In)

**Each FIFO contains 2-stage synchronizer chains for Gray-coded pointers:**

### Address FIFO Synchronizers (Gray-Coded Pointers)

**Write-to-Read Domain Synchronization (800 MHz → 400 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| wr_addr_ptr_gray       | 4     | Write pointer (Gray-coded in write domain) |
| wr_addr_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in read domain) |
| wr_addr_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in read domain) |
| wr_addr_ptr_bin        | 4     | Binary conversion of synchronized write pointer |

**Read-to-Write Domain Synchronization (400 MHz → 800 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| rd_addr_ptr_gray       | 4     | Read pointer (Gray-coded in read domain) |
| rd_addr_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in write domain) |
| rd_addr_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in write domain) |
| rd_addr_ptr_bin        | 4     | Binary conversion of synchronized read pointer |

### Data FIFO Synchronizers (Gray-Coded Pointers)

**Write-to-Read Domain Synchronization (800 MHz → 400 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| wr_data_ptr_gray       | 4     | Write pointer (Gray-coded in write domain) |
| wr_data_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in read domain) |
| wr_data_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in read domain) |
| wr_data_ptr_bin        | 4     | Binary conversion of synchronized write pointer |

**Read-to-Write Domain Synchronization (400 MHz → 800 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| rd_data_ptr_gray       | 4     | Read pointer (Gray-coded in read domain) |
| rd_data_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in write domain) |
| rd_data_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in write domain) |
| rd_data_ptr_bin        | 4     | Binary conversion of synchronized read pointer |

### Response FIFO Synchronizers (Gray-Coded Pointers)

**Write-to-Read Domain Synchronization (400 MHz → 800 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| wr_resp_ptr_gray       | 4     | Write pointer (Gray-coded in write domain) |
| wr_resp_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in read domain) |
| wr_resp_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in read domain) |
| wr_resp_ptr_bin        | 4     | Binary conversion of synchronized write pointer |

**Read-to-Write Domain Synchronization (800 MHz → 400 MHz):**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| rd_resp_ptr_gray       | 4     | Read pointer (Gray-coded in read domain) |
| rd_resp_ptr_sync_stg1  | 4     | Synchronizer stage 1 (capture in write domain) |
| rd_resp_ptr_sync_stg2  | 4     | Synchronizer stage 2 (clean output in write domain) |
| rd_resp_ptr_bin        | 4     | Binary conversion of synchronized read pointer |

**CDC Latency:** ~2-3 cycles through both synchronizer stages

---

## Bridge Core Logic Registers (AHB Clock Domain - 400 MHz)

### Write Operation Control

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| write_state       | 2     | Write FSM state: IDLE(00), FIRST_XFER(01), SECOND_XFER(10), WAIT(11) |
| addr_fifo_pop     | 1     | Pop address from FIFO on handshake |
| data_fifo_pop     | 1     | Pop data from FIFO on handshake |
| write_active      | 1     | Write transaction in progress |
| transfer_pending  | 1     | First transfer complete, second pending |

### Write Data Path

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| wdata_lower_reg   | 32    | Lower 32-bits of 64-bit data [31:0] |
| wdata_upper_reg   | 32    | Upper 32-bits of 64-bit data [63:32] |
| waddr_current     | 32    | Current address for transfer |
| waddr_next        | 32    | Next address (current + 4) |

### Read Operation Control

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| read_state        | 2     | Read FSM state: IDLE(00), FIRST_XFER(01), SECOND_XFER(10), WAIT(11) |
| addr_fifo_pop     | 1     | Pop address from FIFO on handshake |
| read_active       | 1     | Read transaction in progress |
| transfer_pending  | 1     | First transfer complete, assembling second |

### Read Data Assembly

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| rdata_lower_reg   | 32    | Lower 32-bits of read response [31:0] |
| rdata_upper_reg   | 32    | Upper 32-bits of read response [63:32] |
| rdata_assembled   | 64    | Assembled 64-bit read data |
| raddr_current     | 32    | Current address for read transfer |
| raddr_next        | 32    | Next address (current + 4) |

---

## Outstanding Requests Register (AHB Clock Domain - 400 MHz)

**Tracks pending write vs read responses to distinguish them in unified Response FIFO:**

| Register Name           | Width | Description |
|------------------------|-------|-------------|
| outstanding_requests   | 5     | Count of pending requests (max 16 writes + 16 reads) |
| request_type_fifo[31]  | 1     | FIFO tracking response type: 0=Write, 1=Read (32 entries for 16 outstanding) |
| req_type_wr_ptr        | 5     | Write pointer for request type tracker |
| req_type_rd_ptr        | 5     | Read pointer for request type tracker |
| next_resp_is_read      | 1     | Indicates next response from FIFO is for read (else write) |

**Usage:** When response popped from Response FIFO, this register determines whether to route to BVALID (write) or RVALID (read) channel.

---

## AHB Interface Registers (AHB Clock Domain - 400 MHz)

### AHB Write Transaction Control

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| ahb_write_state   | 2     | AHB write FSM: IDLE(00), FIRST_XFER(01), SECOND_XFER(10), WAIT(11) |
| haddr_reg         | 32    | Current AHB address (from bridge logic) |
| hwdata_reg        | 32    | Current AHB write data |
| htrans_reg        | 2     | AHB transfer type: NONSEQ(10) for first, SEQ(11) for second |
| hwrite_reg        | 1     | AHB write enable (set to 1 for writes) |
| hsize_reg         | 3     | AHB transfer size (fixed at 3'b010 for 32-bit) |
| hready_capture    | 1     | Captured HREADY signal from slave |

### AHB Read Transaction Control

| Register Name      | Width | Description |
|-------------------|-------|-------------|
| ahb_read_state    | 2     | AHB read FSM: IDLE(00), FIRST_XFER(01), SECOND_XFER(10), WAIT(11) |
| haddr_reg         | 32    | Current AHB address (from bridge logic) |
| hrdata_latch_0    | 32    | Latched first read data from AHB |
| hrdata_latch_1    | 32    | Latched second read data from AHB |
| htrans_reg        | 2     | AHB transfer type: NONSEQ(10) for first, SEQ(11) for second |
| hwrite_reg        | 1     | AHB write enable (set to 0 for reads) |
| hsize_reg         | 3     | AHB transfer size (fixed at 3'b010 for 32-bit) |
| hresp_capture     | 1     | Captured HRESP signal from slave |
| hready_capture    | 1     | Captured HREADY signal from slave |

---

## Summary: Architecture at a Glance

**Clock Domains:**

- AXI Domain: 800 MHz
- AHB Domain: 400 MHz

**Dual-Clock FIFOs:**

1. **Address FIFO** (16 entries, 32-bit): Shared by read & write paths
2. **Data FIFO** (16 entries, 64-bit): Write path only (reads use response FIFO)
3. **Response FIFO** (16 entries, 66-bit): Unified for write & read responses

**CDC Mechanism:**

- Gray-coded binary pointers for safe synchronization
- 2-stage synchronizer chains (capture + clean stages) in each FIFO
- ~2-3 cycle latency per clock domain crossing
- No separate CDC module (built into each FIFO)

**Response Handling:**

- Outstanding Requests Register tracks write vs read response types
- Single Response FIFO (unified) reduces area
- Bridge Core Logic routes FIFO outputs to BVALID (writes) or RVALID (reads)
