# Protocol conformance validations
### REQ-001: Device address acknowledgement {#req-001}
The slave shall acknowledge a valid 7-bit device address (0x55) by driving SDA low during the ninth SCL clock pulse of the address byte, for both read and write transactions.
**Validated by:** [VAL-001](validation.md#val-001), [VAL-002](validation.md#val-002), [VAL-004](validation.md#val-004)

### REQ-002: Foreign address rejection {#req-002}
The slave shall not acknowledge any device address other than 0x55. SDA shall remain released (high via pull-up) during the ninth SCL pulse, and the slave shall return to its idle state.
**Validated by:** [VAL-003](validation.md#val-003)

### REQ-003: START condition detection {#req-003}
The slave shall detect a START condition (falling edge on SDA while SCL is high) at any point during operation and begin sampling the subsequent address byte.
**Validated by:** (to be assigned)

### REQ-004: STOP condition returns to idle {#req-004}
The slave shall detect a STOP condition (rising edge on SDA while SCL is high) and return its internal state machine to the idle state, releasing the bus and resetting the register address pointer to zero.
**Validated by:** [VAL-004](validation.md#val-004), [VAL-005](validation.md#val-005)

### REQ-005: Repeated START handling {#req-005}
The slave shall correctly process a repeated START condition (a new START without a preceding STOP), re-entering the address phase while preserving the previously set register address pointer.
**Validated by:** [VAL-005](validation.md#val-005)

### REQ-006: Read/write direction bit {#req-006}
The slave shall interpret the least significant bit of the address byte as the direction bit: 0 selects a write transaction (master sends register index and data), 1 selects a read transaction (slave outputs register data).
**Validated by:** [VAL-001](validation.md#val-001), [VAL-002](validation.md#val-002), [VAL-004](validation.md#val-004)

### REQ-007: MSB-first bit ordering {#req-007}
The slave shall transmit and receive all bytes most-significant-bit first, in accordance with the I2C specification.
**Validated by:** [VAL-000b](validation.md#val-000b)

### REQ-008: Open-drain SDA behaviour {#req-008}
The slave shall only ever drive SDA actively low; to represent a logic high it shall release the line (high-impedance), relying on the external pull-up. The slave shall never drive SDA actively high.
**Validated by:** [VAL-000b](validation.md#val-000b)

### REQ-009: Clock speed range {#req-009}
The slave shall operate correctly at the three standard I2C bus speeds: Standard Mode (100 kHz), Fast Mode (400 kHz), and Fast Mode Plus (1 MHz), given a system clock of 25 MHz.
**Validated by:** [VAL-000a](validation.md#val-000a)




# Register architecture
### REQ-010: Register block address ranges {#req-010}
The design shall expose two register blocks at disjoint address ranges: Block A at register addresses 0x00–0x07 (8 registers) and Block B at 0x08–0x0F (8 registers). Each register shall be 8 bits wide.
**Validated by:** [VAL-008](validation.md#val-008)

### REQ-011: Write to addressed register {#req-011}
On a write transaction targeting a register in Block A, the slave shall store the received data byte in the register identified by the preceding register-index byte.
**Validated by:** [VAL-004](validation.md#val-004), [VAL-005](validation.md#val-005), [VAL-006](validation.md#val-006)

### REQ-012: Register address auto-increment {#req-012}
During a multi-byte (bulk) transaction, the register address pointer shall increment by one after each data byte, so that consecutive bytes are written to or read from consecutive register addresses.
**Validated by:** [VAL-006](validation.md#val-006), [VAL-007](validation.md#val-007)

### REQ-013: Read from addressed register {#req-013}
On a read transaction, the slave shall output the contents of the register identified by the current register address pointer, most-significant-bit first.
**Validated by:** [VAL-002](validation.md#val-002), [VAL-005](validation.md#val-005), [VAL-007](validation.md#val-007)

### REQ-014: Cross-block address decoding {#req-014}
A write or read access shall affect only the register block whose address range contains the target address. An access to Block A shall leave all Block B registers unchanged, and vice versa.
**Validated by:** [VAL-008](validation.md#val-008)

### REQ-015: Block boundary integrity {#req-015}
The address decoding shall correctly distinguish the boundary between Block A and Block B: address 0x07 shall resolve to the last register of Block A and 0x08 to the first register of Block B, with no overlap.
**Validated by:** (to be assigned)

### REQ-016: Block B is read-only from the master {#req-016}
The slave shall not allow a master write transaction to modify any register in Block B. A write attempt targeting a Block B address shall be acknowledged on the bus but shall have no effect on the register contents.
(Block B represents sensor data fed internally by the LFSR. The master may read but not overwrite it)
**Validated by:** [VAL-008](validation.md#val-008), [VAL-010](validation.md#val-010)

### REQ-017: Unmapped address — no write effect {#req-017}
A write transaction targeting a register address outside both block ranges (0x10–0xFF) shall be acknowledged on the bus but shall not modify any register in either block.
**Validated by:** [VAL-009](validation.md#val-009)

### REQ-018: Unmapped address — read returns zero {#req-018}
A read transaction from an unmapped register address shall return 0x00, as a consequence of each unselected register block outputting zero and the outputs being combined by an OR reduction.
**Validated by:** [VAL-009](validation.md#val-009)

### REQ-019: Register reset values {#req-019}
On reset, each register shall be initialised to a defined value specified at design time via the block's RESET_VALUES parameter. Block A shall hold its configured reset pattern; Block B shall hold its configured reset pattern until overwritten by the LFSR.
**Validated by:** (to be assigned)




# LFSR (pseudo) random number generation
### REQ-020: LFSR drives Block B with pseudo-random data {#req-020}
An internal LFSR module shall continuously generate pseudo-random 8-bit values and write them into the registers of Block B, simulating an autonomous sensor data source. The master shall observe changing values when reading Block B over time.
Rationale: Provides a self-contained, observable "sensor" without requiring external stimulus.
**Validated by:** [VAL-011](validation.md#val-011), [VAL-014](validation.md#val-014)

### REQ-021: All Block B registers are serviced {#req-021}
The LFSR write mechanism shall cycle through and update every register in Block B (0x08–0x0F), so that no register remains permanently at its reset value during operation.
Rationale: Guards against an address-rotation fault that would leave one or more registers stuck.
**Validated by:** [VAL-012](validation.md#val-012)

### REQ-022: LFSR does not affect Block A {#req-022}
The LFSR write path shall target only Block B. No LFSR activity shall ever modify a register in Block A, regardless of how long the design runs.
Rationale: Confirms the LFSR's write address decoding is strictly confined to the Block B range — the complement of REQ-014 from the LFSR side.
**Validated by:** [VAL-013](validation.md#val-013)




# Reset behaviour
### REQ-023: Synchronous active-low reset {#req-023}
The design shall be reset by an active-low signal (N_RST) sampled synchronously to the system clock. While the reset is asserted, all sequential elements shall be held in their defined reset state.
**Validated by:** (to be assigned)

### REQ-024: Defined state after reset {#req-024}
After reset is released, the slave's state machine shall be in the idle state, the register address pointer shall be zero, and SDA shall be released (bus idle). The slave shall be ready to accept a new transaction on the next START condition.
**Validated by:** (to be assigned)

### REQ-025: LFSR halted during reset {#req-025}
While reset is asserted, the LFSR shall not advance and shall not write to Block B, so that the configured reset values of Block B are observable immediately after reset is released and before the first LFSR update.
**Validated by:** (to be assigned)

# Robustness
### REQ-026: State recovery after every transaction {#req-026}
After completing any transaction — single or bulk, read or write, terminated by STOP or NACK — the slave shall return to the idle state and be ready to process the next transaction without requiring a reset.
**Validated by:** [VAL-014](validation.md#val-014), [VAL-015](validation.md#val-015)

### REQ-027: Consistency under repeated bulk reads {#req-027}
The slave shall handle repeated bulk read transactions over an extended period without loss of consistency: every transaction shall complete correctly, return plausible data, and leave the slave ready for the next access.
**Validated by:** [VAL-014](validation.md#val-014)

### REQ-028: Consistency under mixed read/write sequences {#req-028}
The slave shall maintain a consistent register state under an arbitrary, extended sequence of interleaved read and write transactions. The contents of Block A read back at the end of such a sequence shall match the cumulative effect of all preceding writes.
**Validated by:** [VAL-015](validation.md#val-015)
