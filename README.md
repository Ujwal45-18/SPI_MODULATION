🧩Basic SPI Data Transfer (FPGA)
📌 Project Overview

This mini project demonstrates basic SPI (Serial Peripheral Interface) communication using an FPGA.
The FPGA acts as an SPI Master and communicates with a dummy SPI Slave that returns a fixed response byte.

The goal of this project is to understand:

SPI timing and signaling

Bit-wise data shifting

Master–Slave communication

Verification through simulation

No external SPI device is required — the slave is modeled in Verilog.

🎯 Project Objective

Transmit one byte (0xA5) from SPI Master

Receive one byte (0x3C) from SPI Slave

Verify correct reception

Indicate result using PASS / FAIL

⚙️ SPI Configuration

SPI Mode: Mode 0

CPOL = 0 (Clock idle LOW)

CPHA = 0 (Sample on rising edge)

Data Order: MSB first

Data Width: 8 bits

Transaction Type: Single-byte transfer

🧱 Project Architecture
+-------------+        SPI Bus        +------------------+
| SPI Master  |----------------------| Dummy SPI Slave  |
|   (FPGA)    |  SCLK, CS, MOSI, MISO |   (Verilog)     |
+-------------+                      +------------------+
        |
        |
   PASS / FAIL

📄 Module Description

1️⃣ spi_master.v

Generates SCLK, CS, MOSI

Sends fixed byte 0xA5

Samples MISO on rising edge

Receives one byte

Raises done signal after transfer

2️⃣ spi_slave_dummy.v

Acts as a simple SPI slave

Responds with fixed byte 0x3C

Shifts data out on falling edge of SCLK

No memory or addressing logic

3️⃣ spi_top.v

Connects SPI master and slave

Automatically starts SPI transaction after reset

Compares received data with expected value

Generates pass or fail output

4️⃣ tb_spi_top.v

Generates FPGA clock (100 MHz)

Applies reset

Runs SPI transaction

Displays PASS / FAIL in simulation

Used for waveform verification

🧪 Simulation Instructions (Vivado)

Open Vivado

Create a new RTL Project

Add:

Design Sources:
spi_master.v, spi_slave_dummy.v, spi_top.v

Simulation Source:
tb_spi_top.v

Run: Run Simulation → Run Behavioral Simulation
🧠 Key Learnings

SPI protocol fundamentals

CPOL / CPHA timing

Shift-register based communication

FPGA-based protocol implementation

Simulation-based verification

🚀 Future Enhancements

Button-triggered SPI transfer

Clock divider for real FPGA hardware

Multiple-byte SPI transfer

Interface with real SPI devices (Flash, Sensor)

On-board LED indication

🛠 Tools Used

Vivado Design Suite

Verilog HDL

GTKWave / Vivado Waveform Viewer

👥 Contributors

This project was developed collaboratively, with each member responsible for a specific part of the SPI system design and verification.
🔹 Ujwal

Role: Top Module Integration & Verification

Designed the Top module

Integrated SPI Master and SPI Slave

Implemented automatic SPI start after reset

Compared transmitted and received data

Generated PASS / FAIL output for verification

Developed the Testbench:

Generated FPGA clock

Applied reset

Observed SPI signals (SCLK, CS, MOSI, MISO)

Verified correct SPI data transfer in simulation
.

🔹 Incharaa

Role: SPI Master Design

Designed the SPI Master module

Implemented generation of SPI signals: SCLK, CS, MOSI

Implemented data transmission and reception using shift registers

Added start, reset, and end-of-transfer logic

Ensured correct SPI timing (Mode 0) from the master side

Considered FPGA board as the SPI Master

🔹 Aradhya

Role: SPI Slave Design

Designed the Dummy SPI Slave module

Implemented fixed-response slave behavior (0x3C)

Used shift-register logic to drive MISO

Ensured slave reacts correctly to CS and SCLK

Followed SPI rule that slave does not generate clock

