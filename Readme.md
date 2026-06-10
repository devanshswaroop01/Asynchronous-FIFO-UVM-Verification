# Asynchronous FIFO Design and UVM Verification Environment
---

# Project Overview

This project implements a **parameterized Asynchronous FIFO** along with a complete **UVM-based verification environment**.

The FIFO enables reliable data transfer between **two independent clock domains** while preventing data corruption caused by clock-domain crossing (CDC) issues such as metastability.

The verification environment is developed using industry-standard Design Verification methodologies including:

- Universal Verification Methodology (UVM)
- Constrained and Directed Testing
- Scoreboard-Based Checking
- Functional Coverage
- SystemVerilog Assertions (SVA)
- CDC Verification Concepts

The project demonstrates the complete verification flow followed in modern ASIC/FPGA development from RTL design to verification closure.

---

# Why Asynchronous FIFO?

Modern digital systems rarely operate using a single clock.

Examples include:

- CPU ↔ Peripheral Interfaces
- DMA ↔ Memory Controllers
- Network Interfaces
- Multi-Clock SoCs
- FPGA Subsystems

Directly transferring signals between unrelated clock domains can cause:

- Metastability
- Data corruption
- Timing violations
- Unpredictable behavior

An **Asynchronous FIFO** solves this problem by buffering data and safely synchronizing occupancy information across clock domains.

---

# Key Features

## RTL Design

- Parameterized FIFO Architecture
- Independent Write and Read Clocks
- Gray-Code Pointer Synchronization
- Multi-Flop Synchronizers
- Full Detection Logic
- Empty Detection Logic
- Overflow Protection
- Underflow Protection
- CDC-Safe Operation

---

## Verification Features

- Complete UVM Testbench
- Directed Test Sequences
- Scoreboard-Based Data Integrity Checking
- Functional Coverage Collection
- SystemVerilog Assertions
- Dual Clock Domain Verification
- Reset Verification
- Concurrent Read/Write Verification
- Overflow and Underflow Verification

---

# Design Specifications

| Parameter | Value |
|------------|---------|
| Data Width | 16 Bits |
| FIFO Depth | 8 Entries |
| Pointer Width | 4 Bits |
| Write Clock | Independent |
| Read Clock | Independent |
| Verification Methodology | UVM |
| Assertions | SVA |
| Coverage | Functional Coverage |

---

# Project Architecture

## High-Level Verification Architecture

```text
                    TEST

                      │

                      ▼

                ENVIRONMENT

                      │

                      ▼

                   AGENT

        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼

    DRIVER      SEQUENCER      MONITOR

                                      │
                                      │
                    ┌─────────────────┴──────────────┐
                    │                                │
                    ▼                                ▼

              SCOREBOARD                      SUBSCRIBER
```

---

# RTL Architecture

```text
                   ASYNC FIFO

      ┌─────────────────────────────────┐

           WRITE CLOCK DOMAIN

               FIFO_WR
                  │
                  ▼

               FIFO_MEM

                  ▲
                  │

               FIFO_RD

            READ CLOCK DOMAIN

      └─────────────────────────────────┘


          CDC Synchronization Logic

         Gray Pointer Synchronizers
```

---

# Clock Domain Crossing (CDC) Strategy

The primary challenge in an Asynchronous FIFO is safe communication between independent clock domains.

This design uses:

### Binary Pointers

Used internally for:

- Address generation
- Occupancy tracking

### Gray Pointers

Used for:

- Cross-domain synchronization

Reason:

Only one bit changes between adjacent Gray-code values.

Example:

Binary:

```text
0111 → 1000
```

Four bits change simultaneously.

Gray:

```text
0100 → 1100
```

Only one bit changes.

This significantly reduces CDC risks.

---

# RTL Modules

## FIFO Memory

### Responsibilities

- Stores FIFO data
- Handles write operations
- Provides read data

---

## FIFO_WR

### Responsibilities

- Write Pointer Management
- Gray Pointer Generation
- Full Flag Generation

### Outputs

```text
w_ptr
gray_w_ptr
o_full
```

---

## FIFO_RD

### Responsibilities

- Read Pointer Management
- Gray Pointer Generation
- Empty Flag Generation

### Outputs

```text
rd_ptr
gray_rd_ptr
o_empty
```

---

## BIT_SYNC

### Responsibilities

- Synchronize Gray pointers
- Prevent metastability
- Enable safe CDC communication

Implemented using:

```text
Two-Flip-Flop Synchronizer
```

---

# UVM Verification Environment

## UVM Component Hierarchy

```text
test

└── environment

    ├── agent

    │   ├── sequencer
    │   ├── driver
    │   └── monitor

    ├── scoreboard

    └── subscriber
```

---

# UVM Components

## Sequence Item

Transaction object used throughout the environment.

### Inputs

```systemverilog
i_w_rstn_tb
i_w_inc_tb

i_r_rstn_tb
i_r_inc_tb

i_w_data_tb
```

### Outputs

```systemverilog
o_r_data_tb

o_empty_tb
o_full_tb
```

---

## Sequencer

Responsibilities:

- Sequence arbitration
- Transaction delivery
- Driver communication

---

## Driver

Responsibilities:

- Convert transactions into DUT activity
- Drive write domain
- Drive read domain
- Initialize DUT

---

## Monitor

Responsibilities:

- Observe DUT activity
- Convert signal activity into transactions
- Broadcast transactions

Separate monitoring threads:

```text
Write Domain Monitor

Read Domain Monitor
```

---

## Scoreboard

Acts as the reference model of the FIFO.

Implemented using:

```systemverilog
ref_queue.push_back()
ref_queue.pop_front()
```

### Verification Flow

```text
Write Transaction
      │
      ▼

Store in Reference Queue

      │

Read Transaction

      │
      ▼

Compare DUT Output
Against Expected Data
```

---

## Subscriber

Collects Functional Coverage.

Coverage Areas:

- Write Reset
- Read Reset
- Write Enable
- Read Enable
- Full Flag
- Empty Flag
- Write Data Patterns
- Read Data Patterns

---

# Assertion-Based Verification

The project includes a dedicated assertion module.

Assertions verify:

## Pointer Logic

- Write Pointer Increment
- Read Pointer Increment

## Gray Code Logic

- Write Gray Pointer Validation
- Read Gray Pointer Validation

## Status Flags

- Full Flag Generation
- Empty Flag Generation

## Reset Behavior

- Write Reset Validation
- Read Reset Validation

## Protection Logic

- No Write While Full
- No Read While Empty

---

# Verification Strategy

The verification environment uses multiple layers of checking.

```text
Stimulus

   │

   ▼

Driver

   │

   ▼

DUT

   │

   ▼

Monitor

   │

   ├── Scoreboard
   │
   └── Coverage

Assertions Run In Parallel
```

---

# Test Plan

## Reset Verification

### Global Reset

Verifies complete FIFO reset.

### Write-Domain Reset

Verifies write-side recovery.

### Read-Domain Reset

Verifies read-side recovery.

---

## Functional Verification

### FIFO Fill

Fills FIFO until FULL.

### FIFO Empty

Drains FIFO until EMPTY.

### Full Condition

Attempts write when FIFO is FULL.

### Empty Condition

Attempts read when FIFO is EMPTY.

### Write Then Read

Verifies FIFO ordering.

### Concurrent Read/Write

Verifies simultaneous activity.

---

## Data Pattern Verification

### All-Zero Pattern

```text
0x0000
```

### All-One Pattern

```text
0xFFFF
```

---

# Implemented Test Sequences

```text
fifo_reset_sequence

fifo_write_reset_sequence

fifo_read_reset_sequence

fill_fifo_sequence

empty_fifo_sequence

attempt_write_to_full_sequence

attempt_read_from_empty_sequence

write_then_read_sequence

concurrent_rw_sequence

all_one_sequence

all_zero_sequence
```

---

# Simulation Flow

```text
Generate Transaction

        │

        ▼

Sequencer

        │

        ▼

Driver

        │

        ▼

DUT

        │

        ▼

Monitor

        │

        ├────────► Scoreboard

        └────────► Coverage

Assertions Execute Continuously
```

---

# Verification Results

Verified Functionality:

- FIFO Ordering
- Data Integrity
- Full Flag Logic
- Empty Flag Logic
- CDC Synchronization
- Overflow Protection
- Underflow Protection
- Reset Recovery
- Concurrent Read/Write Operations
- Gray-Code Pointer Logic

---

# Skills Demonstrated

## RTL Design

- Verilog RTL Design
- Parameterized Architectures
- CDC Design
- Gray-Code Synchronization

---

## Verification

- UVM Methodology
- Scoreboard-Based Verification
- Functional Coverage
- Constrained/Directed Testing
- SystemVerilog Assertions
- Debug and Root-Cause Analysis

---

## Digital Design Concepts

- Clock Domain Crossing (CDC)
- Synchronizers
- FIFO Architectures
- Pointer Management
- Verification Planning

---

# Repository Structure

```text
├── rtl/
│   ├── Async_fifo.sv
│   ├── fifo_wr.sv
│   ├── fifo_rd.sv
│   ├── fifo_mem.sv
│   └── bit_sync.sv
│
├── uvm/
│   ├── interface.sv
│   ├── sequence_item.sv
│   ├── sequence.sv
│   ├── sequencer.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── agent.sv
│   ├── scoreboard.sv
│   ├── subscriber.sv
│   ├── environment.sv
│   ├── test.sv
│   └── async_fifo_pkg.sv
│
├── assertions/
│   └── fifo_assertions.sv
│
├── docs/
│   ├── architecture_diagram.png
│   └── dataflow_diagram.png
│
└── top.sv
```

---

# Future Enhancements

### RTL

- Almost Full Flag
- Almost Empty Flag
- Occupancy Counter
- Registered Read Path

### Verification

- Clock-Ratio Stress Testing
- Long Constrained-Random Regression
- Cross Coverage
- Gray-Code Transition Assertions
- Formal Verification

---

# Conclusion

This project demonstrates the complete lifecycle of designing and verifying an industry-style Asynchronous FIFO.

The design safely transfers data between independent clock domains using Gray-code synchronization and multi-flop CDC protection. The verification environment employs UVM, Scoreboards, Functional Coverage, and Assertions to validate correctness through multiple independent verification layers.

The result is a reusable and scalable verification framework that reflects real-world ASIC/FPGA Design Verification practices and provides strong evidence of RTL Design and Verification skills suitable for internship, graduate, and entry-level Design Verification roles.

---
