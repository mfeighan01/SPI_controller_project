# SPI Slave Receiver (Mode 0) - RTL Design

Verilog implementation of an SPI slave as part of a larger SPI controller project. Features synchronised inputs, edge detection, FSM control, and byte reception logic. Built as a learning-focused, incrementally extensible hardware design.

## 🚀 Overview

This design implements a basic SPI Slave (Receiver only) using **SPI Mode 0** (CPOL=0, CPHA=0). It samples incoming data on the rising edge of the serial clock (`sclk`) and generates a completion pulse once a full byte is captured.

### Key Features
* **Clock-Domain Crossing (CDC):** Uses 2-stage synchronisers for `sclk`, `cs`, and `mosi` to mitigate metastability.
* **Edge Detection:** Internal logic detects rising and falling edges of the synchronised SPI clock.
* **FSM Architecture:** A clean 2-state Finite State Machine (IDLE/RECEIVING) manages the transfer lifecycle.
* **Efficient Counting:** Implements a **one-hot ring counter** for bit tracking, which is area-efficient and high-performance in FPGA fabric.
* **Debug-Ready:** Includes external probes for internal state and bit counts to simplify hardware-in-the-loop debugging.

## 🛠 Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Language** | Verilog (RTL) |
| **SPI Mode** | Mode 0 (CPOL=0, CPHA=0) |
| **Interface** | 3-wire SPI (CS, SCLK, MOSI) |
| **Buffer** | 8-bit received data register |
| **Toolchain** | Vivado |

## 📂 Module Structure

### Synchronisation & Edge Detection
External signals are sampled into the system clock domain. 

The `sclk_rising` signal is derived by comparing successive samples, ensuring the data is sampled only when the SPI clock transitions.

### Finite State Machine (FSM)
- **IDLE:** Slave is deselected (`cs` is HIGH). Counters are held in reset.
- **RECEIVING:** Triggered when `cs` goes LOW. The module begins shifting bits on detected `sclk` edges.

### Datapath
Incoming bits from `mosi` are shifted into an 8-bit register. Once the ring counter reaches the 8th bit, the `done` flag pulses HIGH for one clock cycle, and the data is latched to the `received_data` output.

## 📈 Simulation

The design was verified using a behavioural testbench in Vivado. The waveforms confirm:
1. Correct synchronisation of asynchronous inputs.
2. Accurate bit-shifting on the rising edge of `sclk`.
3. Valid data latching and `done` pulse generation upon byte completion.

## 📝 Future Improvements
- [ ] Implement MISO (Transmit) logic.
- [ ] Add support for configurable SPI modes (1, 2, and 3).
- [ ] Implement a parameterized word length (e.g., 16-bit or 32-bit transfers).

---
*Developed as part of an exploration into RTL design and FPGA verification workflows.*
