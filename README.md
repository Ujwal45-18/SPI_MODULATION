# SPI Master-Slave Communication — Verilog-Based FPGA Design

This repository implements a complete SPI (Serial Peripheral Interface) communication system in Verilog, featuring an SPI Master and a Dummy SPI Slave module. The design is verified through behavioral simulation in Vivado and demonstrates fundamental concepts of synchronous serial communication, protocol timing, and FSM-based state machine design.

**Expected Output:** Successful byte transfer with PASS/FAIL validation

---

## Repository Contents

### Core Modules

- **`spi_master.v`** — SPI Master controller that generates clock (SCLK), chip select (CS), and manages Master-Out-Slave-In (MOSI) transmission and Master-In-Slave-Out (MISO) reception
- **`spi_slave.v`** — Dummy SPI Slave that responds to chip select (CS), synchronizes with SCLK, and shifts data on MISO line
- **`spi_top.v`** — Top-level module instantiating both master and slave, managing interconnections
- **`tb.v`** — Comprehensive testbench simulating complete SPI transaction with waveform generation

---

## System Architecture and Data Flow

### Overall Workflow

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  TX Data     │      │  SPI Master  │      │  SPI Slave   │      
│  (0xA5)      ├─────→│  (Controller)├─────→│  (Responder) ├─────→ RX Data
│              │      │              │      │              │      (0x3C)
└──────────────┘      └──────────────┘      └──────────────┘
                             ↓
                      SCLK, CS, MOSI, MISO
```

### Step-by-Step Data Flow

1. **Master Initialization** (`spi_master.v`)
   - Assert CS (Chip Select) to LOW to enable slave
   - Generate SCLK with configured frequency
   - Prepare MOSI data (0xA5 = 10100101 binary)

2. **Bit-Wise Transmission** (Master → Slave via MOSI)
   - Master shifts out MSB first on MOSI line
   - Each bit is clocked by SCLK rising/falling edges (SPI Mode 0)
   - Slave samples MOSI data on clock edges
   - 8 bits transmitted in sequence

3. **Bit-Wise Reception** (Slave → Master via MISO)
   - Slave shifts out 8-bit response (0x3C = 00111100 binary)
   - Master samples MISO on clock edges
   - Data captured bit-by-bit into receive register

4. **Transaction Completion** 
   - CS rises to HIGH to deselect slave
   - Master validates received data against expected value
   - PASS/FAIL signal asserted based on comparison

---

## SPI Protocol Configuration

| Parameter    | Value                       |
| ------------ | --------------------------- |
| **SPI Mode** | Mode 0 (CPOL=0, CPHA=0)     |
| **Data Order** | MSB First                  |
| **Data Width** | 8 bits per transaction      |
| **Bit Timing** | Programmable clock divider  |
| **Clock Source** | FPGA system clock (100 MHz) |
| **CS Behavior** | Active-low, manual control  |

---

## Detailed Code Explanations

### 1. SPI Master Module (`spi_master.v`)

**Purpose:** Generates SPI clock, controls chip select, and manages Master-Out-Slave-In (MOSI) transmission and Master-In-Slave-Out (MISO) reception.

**Key Components:**

```verilog
// FSM States
IDLE      → Waiting for start signal
PRE_TX    → Prepare transmission data
TX_RX     → Transmit/receive bits
POST_TX   → Latch received data, wait before CS release
DONE      → Transaction complete
```

**Critical Implementation Details:**

- **Clock Generation:**
  - Divides input clock to generate SCLK at desired frequency
  - Configurable via `CLOCK_DIV` parameter
  - Ensures timing alignment with slave expectations

- **Data Shifting:**
  - MSB-first transmission: shifts data left, sends MSB at each SCLK edge
  - MISO sampling occurs on rising SCLK edge for Mode 0
  - Bit counter tracks progress through 8-bit transaction

- **CS Control:**
  - CS asserted (LOW) at transaction start
  - CS held LOW throughout all 8 bits
  - CS deasserted (HIGH) after transaction completes
  - Prevents slave from responding outside transaction window

- **Handshake Signals:**
  - `start` input triggers new transaction
  - `done` output pulses when transaction completes
  - `pass_fail` indicates received data correctness

---

### 2. SPI Slave Module (`spi_slave.v`)

**Purpose:** Simulates a slave device responding to SPI master commands, accepting MOSI data and transmitting MISO response.

**Key Components:**

```verilog
// FSM States
IDLE      → Waiting for CS assertion
ACTIVE    → Shifting in data from MOSI
DONE      → Transaction complete, awaiting CS deassertion
```

**Critical Implementation Details:**

- **CS Synchronization:**
  - Detects CS transition from HIGH to LOW (active-low logic)
  - Enters active state only when CS is LOW
  - Returns to IDLE when CS returns HIGH

- **MOSI Reception:**
  - Samples MOSI on SCLK rising edge (Mode 0 timing)
  - Shifts received bits into parallel register
  - Accumulates 8 bits for complete byte reception

- **MISO Transmission:**
  - Pre-loaded with response data (0x3C)
  - Shifts out MSB first on SCLK falling edge (Mode 0 timing)
  - Maintains stable data for master sampling on rising edges

- **Data Storage:**
  - Received data available after 8 clock cycles
  - Output holds received value until next transaction
  - Allows master/testbench to verify correct reception

---

### 3. Top-Level Module (`spi_top.v`)

**Purpose:** Integrates SPI Master and Slave modules with proper signal routing.

**Signal Routing:**
- Master `mosi_out` → Slave `mosi_in`
- Slave `miso_out` → Master `miso_in`
- Master `sclk` → Slave `sclk`
- Master `cs` → Slave `cs`
- System clock distributed to both modules

---

### 4. Testbench (`tb.v`)

**Purpose:** Validates SPI communication through behavioral simulation with complete protocol verification.

**Key Features:**

- Generates system clock and reset signals
- Triggers SPI master with start pulse
- Monitors all four SPI signals (SCLK, CS, MOSI, MISO)
- Captures and displays transmitted and received data
- Verifies PASS/FAIL indicator
- Generates VCD waveform file for analysis

**Test Sequence:**

1. Apply reset to initialize both modules
2. Pulse `start` signal to initiate transaction
3. Monitor SCLK generation and timing
4. Track 8-bit transmission on MOSI (0xA5)
5. Track 8-bit reception on MISO (0x3C)
6. Verify CS assertion/deassertion timing
7. Check PASS signal when data matches expected values
8. Repeat for multiple cycles or stop on completion

**Expected Waveform Behavior:**

```
CS:    ──────┐                               ┌──────────
             └───────────────────────────────┘

SCLK:  ──────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌────────
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
       ──────┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └────────

MOSI:  ────1│0│1│0│0│1│0│1│───────────────────────
       (TX:0xA5 = 10100101)

MISO:  ────0│0│1│1│1│1│0│0│───────────────────────
       (RX:0x3C = 00111100)
```

---

## Quick Start — Simulation with Vivado

### 1. Install Tools (Windows/Linux/macOS)

```bash
# Install Vivado Design Suite from Xilinx
# https://www.xilinx.com/support/download.html
# Choose appropriate version for your OS
```

**Vivado Installation Resources:**
- [Vivado Installation Guide Part 1](https://youtu.be/W8k0cfSOFbs?si=e_4kKj7fOBpXytX6)
- [Vivado Installation Guide Part 2](https://youtu.be/-U1OzeV9EKg?si=YT9s69aZx1oj1uqo)
- [First FPGA Project in Vivado](https://youtu.be/bw7umthnRYw)

### 2. Create Vivado Project

- Launch Vivado Design Suite
- Create new RTL project
- Add source files: `spi_master.v`, `spi_slave.v`, `spi_top.v`
- Set `spi_top.v` as top module
- Create file set for design sources

### 3. Create Testbench

- Add `tb.v` as simulation source
- Set `tb.v` as testbench source
- Add file set for simulation sources

### 4. Run Behavioral Simulation

```bash
# In Vivado:
# 1. Click "Run Simulation" → "Run Behavioral Simulation"
# 2. Select Vivado Simulator
# 3. Wait for testbench to complete (observe console output)
# 4. Open Waveform viewer to inspect signals
```

**Expected Waveform:** CS assertion → SCLK generation → MOSI transmission (0xA5) → MISO reception (0x3C) → CS deassertion → PASS signal

**Simulation View:**

![SPI Simulation Output](image.png)

_Vivado behavioral simulation showing complete SPI transaction with all control signals and data transfers_

### 5. Analyze Waveforms

- Verify SCLK generation (should be lower frequency than system clock)
- Check CS assertion/deassertion timing
- Confirm MOSI transmits 0xA5 (10100101) MSB first
- Confirm MISO receives 0x3C (00111100) MSB first
- Verify timing alignment between master and slave
- Monitor `done` signal for transaction completion
- Validate `pass_fail` output signals correct reception

---

## Testing and Validation

### Master Functionality Testing

- Verify SCLK generation and frequency correctness
- Confirm CS assertion timing (goes LOW before first SCLK edge)
- Validate MOSI data output (checks MSB-first transmission)
- Verify bit shifting at each SCLK cycle
- Check CS deassertion timing (goes HIGH after 8 bits)

### Slave Functionality Testing

- Verify CS edge detection (responds to LOW transition)
- Confirm MOSI data sampling on correct SCLK edges
- Validate MISO data shifting (MSB-first output)
- Check received data latching
- Verify idle state when CS is HIGH

### Integration Testing

- Complete transaction from start to finish
- Data integrity: transmitted 0xA5, received 0x3C
- Timing synchronization between master and slave
- Back-to-back transactions (consecutive start pulses)
- Testbench validation of PASS/FAIL signal

---

## For Hardware Implementation (FPGA Board)

### 1. Create Hardware Top Module

Create a top-level module that includes:

```verilog
module spi_system_top (
    input clk,
    input rst,
    
    // SPI Signals
    output sclk,
    output cs,
    output mosi,
    input miso,
    
    // Status indicators
    output pass_led,
    output fail_led
);
    // Instantiate SPI top module
    spi_top spi_inst (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .pass_fail(pass_led)
    );
    
    assign fail_led = ~pass_led;
endmodule
```

### 2. Add Constraints File (XDC)

Create an XDC (Xilinx Design Constraints) file mapping logical signals to physical pins:

```xdc
# Clock constraint (example for 100 MHz system clock)
create_clock -period 10.000 -name clk [get_ports clk]

# SPI Signal Pin Mapping (adjust based on your FPGA board)
set_property PACKAGE_PIN A18 [get_ports clk]
set_property PACKAGE_PIN B22 [get_ports rst]
set_property PACKAGE_PIN C22 [get_ports sclk]
set_property PACKAGE_PIN D22 [get_ports cs]
set_property PACKAGE_PIN E22 [get_ports mosi]
set_property PACKAGE_PIN F22 [get_ports miso]
set_property PACKAGE_PIN G22 [get_ports pass_led]
set_property PACKAGE_PIN H22 [get_ports fail_led]

# I/O Standard
set_property IOSTANDARD LVCMOS33 [get_ports *]
```

### 3. Add Constraint File to Project

- In Vivado: File → Add Sources → Add or create constraints
- Select the XDC file
- Verify pin assignments match your hardware

### 4. Run Implementation Flow

```bash
# In Vivado:
# 1. Synthesis → Synthesis
# 2. Implementation → Place and Route
# 3. Generate → Generate Bitstream
# 4. Wait for bitstream generation to complete
```

### 5. Program FPGA Device

```bash
# In Vivado:
# 1. Open Hardware Manager
# 2. Connect to Target (FPGA board)
# 3. Select device in Hardware Manager window
# 4. Program Device
# 5. Select generated .bit file
# 6. Click Program
```

### 6. Verify Hardware Operation

- Observe `pass_led` (should illuminate on successful transaction)
- Monitor SPI signals with logic analyzer or oscilloscope
- Verify timing matches simulation results
- Test multiple transactions to confirm robustness

---

## Learning Resources

### SPI Protocol Fundamentals

- [SPI Basics](https://www.youtube.com/watch?v=MCHl0sxmW0A)
- [SPI Protocol Deep Dive](https://www.youtube.com/watch?v=fvj7iHrtbKc)
- [SPI Modes Explained](https://www.youtube.com/watch?v=8VQtFPPBhNU)

### Verilog & FPGA Design

- [Vivado Installation Guide](https://youtu.be/W8k0cfSOFbs)
- [Verilog Fundamentals Playlist](https://youtube.com/playlist?list=PLJ5C_6qdAvBELELTSPgzYkQg3HgclQh-5)
- [FSM Design Patterns](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

### Simulation & Waveform Analysis

- [GTKWave Waveform Viewer](https://gtkwave.sourceforge.net/)
- [Vivado Logic Analyzer](https://www.xilinx.com/video/vivado-logic-analyzer.html)
- [VCD File Format Reference](https://en.wikipedia.org/wiki/Value_change_dump)

---

## Contributors

### Ujwal — Top-Level Integration & Testbench Development

#### Problem Statement and Objectives

The objective was to create a system-level integration module that:

- Connects SPI Master and Slave modules seamlessly
- Automatically initiates SPI transactions from reset
- Compares received data against expected values
- Generates clear PASS/FAIL status signals for validation
- Models a real-world system where FPGA acts as microcontroller communicating with external slave chip
- Develop comprehensive testbench to verify all signals in simulation
- Enable observation of all four SPI signals plus validation indicators

#### How I Tackled the Problem

**1. Understanding System-Level Integration**

- Studied SPI master-slave interconnection requirements
- Recognized need for automatic transaction triggering
- Identified data comparison logic as critical validation step
- Determined importance of clear status indicators (PASS/FAIL)
- Understood testbench role in protocol verification

**2. Top Module Design Approach**

- Modeled system as FPGA (microcontroller) communicating with external slave
- Implemented automatic SPI start mechanism triggered from reset
- Used reset logic patterns from master module for controlled transaction initiation
- Designed data comparison pipeline to validate slave response
- Created status signals for clear pass/fail indication

**3. Testbench Development Strategy**

- Designed testbench to generate all necessary clock and reset signals
- Structured to automatically run SPI transactions without manual intervention
- Implemented signal monitoring for waveform analysis
- Included timing annotations for understanding transaction flow
- Generated VCD files for detailed waveform inspection

#### Proposed Solution and Implementation

**Top-Level Module (`spi_top.v`) Architecture**

```verilog
module spi_top (
    input clk,
    input rst,
    
    // SPI Interface Signals
    output sclk,
    output cs,
    output mosi,
    input miso,
    
    // Status Outputs
    output pass_fail,
    output done
);

    // Master module instantiation
    spi_master master_inst (
        .clk(clk),
        .rst(rst),
        .start(auto_start),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .rx_data(received_data),
        .done(done)
    );
    
    // Slave module instantiation
    spi_slave slave_inst (
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)
    );
    
    // Data Comparison Logic
    assign pass_fail = (received_data == 8'h3C) ? 1'b1 : 1'b0;
    
    // Automatic Start Logic
    reg auto_start;
    always @(posedge clk or negedge rst) begin
        if (!rst)
            auto_start <= 1'b0;
        else
            auto_start <= 1'b1;  // Trigger after reset
    end
endmodule
```

**Key Design Elements:**

**1. Master-Slave Interconnection**
- Direct signal routing: `sclk`, `cs`, `mosi`, `miso` connected between modules
- No intermediate logic corruption or delay
- Clean, efficient module instantiation

**2. Automatic Transaction Initiation**
- Reset logic triggers `auto_start` signal
- Master begins transmission automatically after reset release
- No external intervention required for testing

**3. Data Validation Logic**
- Compares master's received data (0x3C expected) against slave response
- Single-bit `pass_fail` output for clear test result
- `done` signal indicates transaction completion

**4. System Model**
```
┌─────────────────────────────────────────┐
│  FPGA (Microcontroller) — spi_top.v     │
│  ┌─────────────────────────────────────┐│
│  │ spi_master.v (FPGA Internal)        ││
│  └──────────────┬──────────────────────┘│
│                 │ SPI Signals            │
│                 │ (SCLK, CS, MOSI, MISO)│
│  ┌──────────────▼──────────────────────┐│
│  │ spi_slave.v (External Chip)         ││
│  └─────────────────────────────────────┘│
│                 │                        │
│  Data Validation & Status Generation    │
│                 │                        │
│           [PASS/FAIL]                   │
└─────────────────────────────────────────┘
```

#### Testbench Implementation (`tb.v`)

**Key Features:**

✔ **Clock Generation** — Produces system clock (100 MHz) for all operations

✔ **Reset Control** — Applies synchronous reset to trigger automatic SPI start

✔ **Automatic Transaction** — No manual intervention required; runs immediately on reset release

✔ **Signal Monitoring** — Captures all SPI signals:
- `sclk` — Serial clock showing bit-timing
- `cs` — Chip select showing transaction boundaries
- `mosi` — Master-to-slave data (0xA5 = 10100101)
- `miso` — Slave-to-master data (0x3C = 00111100)
- `pass_fail` — Validation indicator
- `done` — Transaction completion flag

✔ **VCD Generation** — Creates waveform dump for detailed analysis in GTKWave

**Testbench Structure:**

```verilog
module tb();
    reg clk, rst;
    wire sclk, cs, mosi, miso;
    wire pass_fail, done;
    
    // Instantiate top module
    spi_top dut (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .pass_fail(pass_fail),
        .done(done)
    );
    
    // Clock generation (10 ns period = 100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Reset and automatic transaction
    initial begin
        rst = 0;              // Assert reset
        #20 rst = 1;          // Release reset after 2 clock cycles
        #10000 $finish;       // Run for sufficient time to complete transaction
    end
    
    // VCD dump for waveform analysis
    initial begin
        $dumpfile("spi_simulation.vcd");
        $dumpvars(0, tb);
    end
    
    // Transaction monitoring
    initial begin
        $monitor("Time=%0d | CLK=%b | RST=%b | CS=%b | SCLK=%b | MOSI=%b | MISO=%b | PASS=%b | DONE=%b",
                 $time, clk, rst, cs, sclk, mosi, miso, pass_fail, done);
    end
endmodule
```

**Test Sequence:**

1. Clock oscillates at 100 MHz
2. Reset asserted (LOW) for 2 clock cycles
3. Reset released (HIGH) triggers automatic SPI start
4. Master begins SCLK generation and CS assertion
5. Master transmits 0xA5 on MOSI (8 bits, MSB first)
6. Slave shifts in MOSI data and shifts out 0x3C on MISO
7. After 8 SCLK cycles, transaction completes
8. Master samples final MISO bit and compares against expected 0x3C
9. `pass_fail` asserts HIGH (PASS) when data matches
10. `done` pulse indicates transaction completion

#### Validation and Testing

**Simulation Verification Steps:**

1. **Clock Verification**
   - Confirm SCLK generation with correct frequency
   - Verify clock divider produces expected bit period
   - Validate timing alignment with master logic

2. **Transaction Boundary Testing**
   - Verify CS goes LOW before first SCLK edge
   - Confirm CS remains LOW for all 8 bits
   - Validate CS goes HIGH after final SCLK cycle

3. **Data Path Validation**
   - Confirm MOSI transmits 0xA5 in correct bit order (MSB first: 1,0,1,0,0,1,0,1)
   - Verify MISO receives 0x3C in correct bit order (MSB first: 0,0,1,1,1,1,0,0)
   - Check timing alignment between transmitted and received bits

4. **Status Signal Verification**
   - Confirm `pass_fail` asserts when received data matches expected (0x3C)
   - Verify `done` pulses after transaction completion
   - Check status signals have correct timing and duration

5. **Multiple Transaction Testing**
   - Verify system can handle back-to-back transactions
   - Confirm reset properly reinitializes state for new transaction
   - Validate data integrity across multiple cycles

#### Changes from Initial Objectives

**Achieved:**

1. ✅ Complete top-level integration connecting master and slave seamlessly
2. ✅ Automatic SPI transaction triggering from reset signal
3. ✅ Data comparison logic validating received data against expected (0x3C)
4. ✅ Clear PASS/FAIL status generation for test validation
5. ✅ System-level model representing real FPGA-to-chip communication
6. ✅ Comprehensive testbench with all signal monitoring
7. ✅ Automatic transaction execution without manual intervention
8. ✅ VCD waveform generation for detailed analysis
9. ✅ Complete transaction flow verification in simulation

**Features Implemented:**

- Modular instantiation of master and slave
- Automatic transaction start using reset synchronization
- Clean data comparison pipeline
- Clear status indicators (PASS/FAIL, DONE)
- Realistic system architecture modeling
- Self-checking testbench
- Complete signal observation capability

#### Resources Used

**Primary References:**

- SPI protocol specifications and master-slave interaction models
- Verilog module instantiation and hierarchical design patterns
- Testbench development best practices from Vivado documentation
- Reset synchronization techniques for reliable state initialization

**Development Tools:**

- Vivado Design Suite for RTL simulation
- GTKWave for waveform analysis and inspection
- VCD file format for timing data storage and analysis

**Testing Methodology:**

- Signal-level verification through waveform inspection
- Timing validation against SPI protocol specifications
- Data integrity checks comparing transmitted vs. received values
- Transaction sequence monitoring for protocol compliance

#### Key Learning Outcomes

- System-level integration of communicating modules with clear interfaces
- Automatic transaction triggering and state initialization strategies
- Data validation and status generation for system monitoring
- Testbench architecture for comprehensive signal observation
- Real-world FPGA-to-peripheral communication modeling
- Hierarchical design enabling clean module reuse and testing
- Importance of clear status indicators in system validation

---

### Aradhya Nitin Patil — SPI Slave Implementation

#### Problem Statement and Objectives

The objective was to implement a reliable SPI Slave module capable of:

- Responding to chip select (CS) control signals
- Synchronizing with externally supplied SCLK (slave never generates clock)
- Accepting serial data via MOSI (Master-Out-Slave-In)
- Transmitting fixed response data via MISO (Master-In-Slave-Out)
- Ensuring correct SPI Mode-0 timing and protocol compliance
- Preventing race conditions between CS and SCLK domains

#### Solution: SPI Slave Architecture

**1. Shift Registers**

- **`rx_shift`** — Collects serial bits received from MOSI line
- **`tx_shift`** — Holds response byte (0x3C) and shifts out bits to MISO line
- Both registers operate synchronously with SCLK rising edges

**2. Bit Counter**

- **`bit_cnt`** — Tracks remaining bits in current transaction
- Initialized to 8 at transaction start (CS rising edge)
- Decrements on each valid SCLK rising edge
- Transaction completes when counter reaches zero

**3. Control Logic**

- **CS Rising Edge Handling:**
  - Resets internal state registers
  - Reloads transmit data (0x3C) into shift register
  - Prepares slave for next transaction
  - Ensures no race conditions between CS and SCLK domains

#### SPI Mode-0 Timing Compliance

The slave strictly adheres to SPI Mode-0 specifications:

**Clock Polarity (CPOL = 0)**
- SCLK idle state is LOW
- Data transitions occur on falling edges
- Sampling occurs on rising edges

**Clock Phase (CPHA = 0)**
- Slave samples MOSI data on SCLK rising edge
- Slave updates MISO on the same rising edge using shift logic
- Guarantees stable data presentation for master sampling

#### Implementation Flow

**Transaction Preparation (CS Rising Edge)**
```verilog
bit_counter ← 8              // Reset for new transaction
rx_shift ← 8'b0              // Clear receive register
tx_shift ← 8'h3C             // Load response byte
slave_state ← READY          // Prepare for data transfer
```

**Data Transfer Phase (While CS = LOW)**

On each rising edge of SCLK:
1. Sample MOSI into LSB of `rx_shift`
2. Output MSB of `tx_shift` onto MISO
3. Shift both registers left
4. Decrement bit counter
5. Update data availability flags

**Transaction Completion (bit_cnt = 0)**
- Entire response byte (0x3C) transmitted
- Received data latched for master verification
- Slave returns to idle state
- Awaits next CS assertion

#### Key Features Implemented

✔ **Shift-Register Based Design** — Proven, robust serial data handling

✔ **Safe CS/SCLK Synchronization** — Eliminates race conditions and timing violations

✔ **Fixed Response Byte (0x3C)** — Enables deterministic validation against master expectations

✔ **Correct Mode-0 Timing** — Rising edge sampling, falling edge transitions

✔ **Bit Counter Tracking** — Clear transaction state management

✔ **Clean State Management** — Idle, Active, and Done states

#### Learning Outcomes

- Practical understanding of SPI slave operation and protocol requirements
- Clear separation of control signal (CS) and data clock (SCLK) domains
- Correct implementation of serial shifting, bit counting, and timing alignment
- Design patterns for deterministic slave devices enabling reliable master validation
- Synchronization strategies for multi-clock domain systems

---

### Incharaa — SPI Master Design and Implementation

#### Problem Statement and Objectives

The primary objective was to implement a robust SPI Master module capable of:

- Generating Serial Clock (SCLK) from FPGA system clock via clock divider
- Controlling Chip Select (CS) to manage slave selection
- Transmitting 8-bit data via Master-Out-Slave-In (MOSI) line
- Receiving 8-bit data via Master-In-Slave-Out (MISO) line
- Implementing fully synchronous shift-register based serial communication
- Ensuring strict SPI Mode-0 timing compliance (CPOL=0, CPHA=0)
- Handling transaction start, completion, and reset conditions reliably
- Providing `done` signal for transaction completion indication

#### How I Tackled the Problem

**1. Understanding SPI Master Requirements**

- Studied SPI protocol fundamentals and Mode-0 timing specifications
- Recognized master's responsibility for clock generation and bus control
- Learned importance of clock divider for frequency scaling
- Understood shift-register pattern for serial data conversion
- Identified critical timing relationships between SCLK, MOSI, and MISO

**2. Synchronous Design Approach**

- Implemented fully synchronous RTL design driven by FPGA system clock
- All state changes triggered by clock edges (no asynchronous logic)
- Used clock divider to reduce effective SPI frequency for observable transactions
- Leveraged shift registers for deterministic bit-by-bit data handling

**3. Protocol Compliance Strategy**

- CPOL=0: Keep SCLK LOW during idle and between transactions
- CPHA=0: Change MOSI data on SCLK falling edge, sample MISO on rising edge
- Ensured stable data presentation before sampling window
- Validated timing alignment through simulation

#### Proposed Solution and Implementation

**SPI Master Architecture**

**1. Clock Divider**

```verilog
// Frequency scaling for observable SPI transactions
always @(posedge clk or negedge rst) begin
    if (!rst)
        clk_div <= 1'b0;
    else if (active)
        clk_div <= ~clk_div;  // Toggle on each system clock
end

// Result: SPI clock = System clock / 2
// Example: 100 MHz system → 50 MHz toggles → 25 MHz SCLK
```

**Why Clock Divider?**
- FPGA system clock (100 MHz) too fast for SPI observation
- Divider reduces frequency by half on each toggle
- Results in slower, debuggable SPI transactions
- Easier waveform analysis and timing verification

**2. Shift Registers**

- **`tx_shift` (Transmit Shift Register)**
  - Holds byte to be transmitted (0xA5 = 10100101)
  - Shifts left on SCLK falling edge
  - MSB driven on MOSI each falling edge
  - After 8 bits, register emptied

- **`rx_shift` (Receive Shift Register)**
  - Collects bits sampled from MISO
  - Shifts left on SCLK rising edge
  - New bit inserted at LSB position
  - After 8 bits, contains received byte (0x3C)

**3. Bit Counter and Control Flags**

```verilog
// 4-bit counter tracks remaining bits
reg [3:0] bit_cnt;           // Counts down from 8 to 0
reg active;                  // Transaction in progress flag

// Initialization on start signal
if (start && !active) begin
    bit_cnt <= 4'd8;         // Load 8 bits
    active <= 1'b1;          // Mark transaction active
    tx_shift <= 8'hA5;       // Load transmit data
    rx_shift <= 8'h00;       // Clear receive register
    cs <= 1'b0;              // Assert CS (LOW)
end
```

**4. SPI Control Signals**

| Signal | Direction | Description |
|--------|-----------|-------------|
| `sclk` | Output | Serial clock (Mode-0: idle LOW) |
| `cs` | Output | Chip select (active LOW) |
| `mosi` | Output | Master-Out-Slave-In data |
| `miso` | Input | Master-In-Slave-Out data |
| `done` | Output | Transaction complete pulse |

#### SPI Mode-0 Timing Implementation

**Clock Polarity (CPOL = 0)**
- SCLK remains LOW when idle (between transactions)
- Transition to active only after CS assertion
- Return to LOW after final bit transfer

**Clock Phase (CPHA = 0)**
- MOSI data changes on SCLK falling edges
- MISO data sampled on SCLK rising edges
- Ensures data stability at sampling moment

**Detailed Timing Sequence:**

```
CS:    ──────┐                               ┌──────────
             └───────────────────────────────┘

SCLK:  ──────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌────────
    (Idle)   │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
       ──────┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └────────

MOSI:  ────1│0│1│0│0│1│0│1│───────────────────────
    (TX: 0xA5 = 10100101 MSB first)
    
MISO:  ────0│0│1│1│1│1│0│0│───────────────────────
    (RX: 0x3C = 00111100 MSB first)

       ▲     ▲ ▲ ▲ ▲ ▲ ▲ ▲ ▲
       │     └─┬─┘ └─┬─┘...
     MOSI changes    MISO sampled
    on falling edge  on rising edge
```

#### Implementation Details

**1. Reset Behavior (Asynchronous Reset)**

```verilog
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        // Safe idle state initialization
        sclk <= 1'b0;        // SCLK forced LOW (Mode-0 idle)
        cs <= 1'b1;          // CS deasserted (HIGH)
        mosi <= 1'b0;        // MOSI at known value
        tx_shift <= 8'h00;   // Clear transmit register
        rx_shift <= 8'h00;   // Clear receive register
        bit_cnt <= 4'd0;     // Counter at zero
        active <= 1'b0;      // No transaction in progress
        done <= 1'b0;        // Clear done flag
        clk_div <= 1'b0;     // Reset clock divider
    end
end
```

**2. Transaction Start Logic**

```verilog
// Triggered when start signal asserted and no transfer running
if (start && !active) begin
    cs <= 1'b0;              // Assert CS (LOW) to select slave
    tx_shift <= 8'hA5;       // Load transmit byte
    rx_shift <= 8'h00;       // Clear receive register
    bit_cnt <= 4'd8;         // Set bit counter to 8
    active <= 1'b1;          // Mark transaction active
    clk_div <= 1'b0;         // Reset clock divider for clean start
    // Setup complete before first clock edge
end
```

**3. Data Transfer Phase**

**On Clock Divider Falling Edge (when SCLK should fall):**
```verilog
if (active && clk_div == 1'b1) begin
    // Falling edge of divided clock
    sclk <= 1'b0;                      // Drive SCLK LOW
    mosi <= tx_shift[7];               // Drive MSB of tx_shift on MOSI
    tx_shift <= {tx_shift[6:0], 1'b0}; // Shift left (MSB out)
end
```

**On Clock Divider Rising Edge (when SCLK should rise):**
```verilog
if (active && clk_div == 1'b0) begin
    // Rising edge of divided clock (except first cycle)
    if (bit_cnt > 0) begin
        sclk <= 1'b1;                      // Drive SCLK HIGH
        rx_shift <= {rx_shift[6:0], miso}; // Shift in MISO bit at LSB
        bit_cnt <= bit_cnt - 1'b1;         // Decrement bit counter
    end
end
```

**4. Transaction Completion**

```verilog
// When all 8 bits transferred (bit_cnt reaches 0)
if (active && bit_cnt == 4'd0) begin
    cs <= 1'b1;          // Deassert CS (HIGH)
    sclk <= 1'b0;        // Return SCLK to idle LOW
    active <= 1'b0;      // Clear active flag
    done <= 1'b1;        // Pulse done signal
    rx_data <= rx_shift; // Latch final received byte
end

// Clear done signal after one cycle
else if (done) begin
    done <= 1'b0;
end
```

#### Key Features Implemented

✔ **Clock Divider** — Scales FPGA clock to observable SPI frequencies

✔ **Synchronous Design** — All logic driven by clock edges, no glitches

✔ **Shift Register Based** — Deterministic, proven serial data handling

✔ **Mode-0 Compliance** — Correct CPOL=0, CPHA=0 timing

✔ **Bit Counter** — Accurate tracking of data transfer progress

✔ **Transaction Control** — Clear start/stop logic with proper CS management

✔ **Data Validation** — Received byte captured for comparison

✔ **Done Signal** — Clear completion indication for testbench coordination

#### Issues Faced and Resolutions

**Issue 1: Vivado Simulation Hang**

- **Problem:** Vivado stalled at "executing simulate step" phase during XSim execution
- **Root Cause:** Antivirus software scanning `xsimk.exe` process, causing delays and timeouts
- **Resolution:** Added Vivado installation directory to antivirus software exclusion list
- **Result:** Simulation resumed normal operation with full speed

**Issue 2: Clock Divider Edge Alignment**

- **Problem:** Initial clock divider toggled every edge, causing timing misalignment between SCLK phases
- **Resolution:** Used explicit phase tracking with rising/falling edge detection based on `clk_div` state
- **Result:** Precise MOSI/MISO sampling and driving at correct edges

#### Limitations and Future Improvements

**Current Limitations:**

- ⚠ Single byte transfer only (8 bits per transaction)
- ⚠ SPI Mode-0 only (no multi-mode support)
- ⚠ Fixed clock divider ratio (no dynamic frequency adjustment)
- ⚠ Single slave selection (no multi-slave support)

**Potential Enhancements:**

- Multi-byte burst transfer capability
- Configurable clock divider for variable baud rates
- Support for SPI Modes 1, 2, 3
- Multiple slave selection (extended CS decoding)
- FIFO buffers for efficient back-to-back transactions

#### Changes from Initial Objectives

**Achieved:**

1. ✅ Complete SPI Master implementation in Verilog HDL
2. ✅ SCLK generation with configurable frequency divider
3. ✅ CS control for slave selection/deselection
4. ✅ MOSI transmission (0xA5, MSB first)
5. ✅ MISO reception (0x3C, MSB first)
6. ✅ Shift register based serial data handling
7. ✅ Strict Mode-0 timing compliance verified in simulation
8. ✅ Transaction start/end logic with proper sequencing
9. ✅ Asynchronous reset to safe idle state
10. ✅ `done` signal for completion indication

**Design Quality:**

- Pure synchronous design (no asynchronous logic except reset)
- Full protocol compliance with timing diagrams
- Comprehensive state management
- Testbench compatible interface

#### Resources Used

**Primary References:**

- SPI Protocol Specifications (Mode-0 timing requirements)
- Shift Register and Serial Communication Design Patterns
- Xilinx Vivado Design Suite documentation
- Clock Domain Crossing and Synchronization techniques

**Development Tools:**

- Verilog HDL for RTL implementation
- Xilinx Vivado for project management
- XSim for behavioral simulation and waveform inspection
- GTKWave for detailed timing analysis

**Testing and Validation:**

- XSim waveform generation and analysis
- Manual timing verification against SPI Mode-0 specifications
- Functional testing with slave module integration
- Data integrity verification (transmitted 0xA5, received 0x3C)

#### Key Learning Outcomes

- Deep understanding of synchronous digital design principles
- SPI protocol implementation at bit-level detail
- Effective use of shift registers for serial communication
- Clock domain management and frequency scaling
- Testbench-driven design validation
- Protocol compliance verification through simulation
- Importance of timing diagrams in design validation
- Troubleshooting hardware design tools and antivirus integration


---

## Project Context



This project is part of a digital design curriculum focusing on serial communication protocols (SPI, I²C, UART) and FPGA implementation. The objectives include:

- Understanding synchronous serial communication fundamentals
- Implementing FSM-based protocol controllers
- Testbench development and signal verification
- Behavioral simulation and waveform analysis
- Vivado design flow and synthesis process



