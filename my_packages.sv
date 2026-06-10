//-------------------------------------------------------------------------------------------

// Description:  Central UVM package for the Asynchronous FIFO verification environment.
//
// Responsibilities:
// - Imports UVM library components.
// - Includes all verification source files.
// - Provides a single package import point for the testbench.
//
// Package Hierarchy:
//
//   Transaction Layer
//      ├─ sequence_item
//      ├─ sequences
//      └─ sequencer
//
//   Agent Layer
//      ├─ driver
//      └─ monitor
//
//   Verification Layer
//      ├─ scoreboard
//      └─ subscriber
//
//   Environment Layer
//      ├─ agent
//      └─ environment
//
//   Test Layer
//      └─ test
//
//------------------------------------------------------------------------------------------

package pack1;

    //////////////////////////////////////////////////////////
    // UVM Library Import
    //////////////////////////////////////////////////////////

    import uvm_pkg::*;

    `include "uvm_macros.svh"

    ///////////////////////////////////////////////////////////////////////
    // Transaction Layer
    // Defines transaction objects, sequences, and  sequencer infrastructure.
    ////////////////////////////////////////////////////////////////////////

    `include "sequence_item.sv"

    `include "sequence.sv"

    `include "sequencer.sv"

    //////////////////////////////////////////////////////////
    // Agent Components
    // Active stimulus generation and DUT monitoring.
    //////////////////////////////////////////////////////////

    `include "driver.sv"

    `include "monitor.sv"

    //////////////////////////////////////////////////////////
    // Verification Components
    // Functional checking and coverage collection.
    //////////////////////////////////////////////////////////

    `include "scoreboard.sv"

    `include "subscriber.sv"

    //////////////////////////////////////////////////////////
    // Environment Layer
    // Integrates agent, scoreboard, and subscriber.
    //////////////////////////////////////////////////////////

    `include "agent.sv"

    `include "environment.sv"

    //////////////////////////////////////////////////////////
    // Test Layer
    // Top-level UVM test implementation.
    //////////////////////////////////////////////////////////

    `include "test.sv"

endpackage

