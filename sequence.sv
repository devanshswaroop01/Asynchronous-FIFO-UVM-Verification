//-----------------------------------------------------------------------------------
// Sequence Name : fifo_reset_sequence
// Description: Applies simultaneous reset to both write and read clock domains.
//
// Verification Intent:
// - Initializes the FIFO to a known state.
// - Clears read and write pointers.
// - Resets FULL and EMPTY status generation logic.
// - Serves as the starting point for directed regression.
//
// Expected Behavior:
// - Write pointer resets to zero.
// - Read pointer resets to zero.
// - Gray pointers reset to zero.
// - FIFO becomes EMPTY.
//
//----------------------------------------------------------------------------------

class fifo_reset_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(fifo_reset_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "fifo_reset_sequence");
        super.new(name);
    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Drives reset in both clock domains while disabling
    // all read and write activity.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Create Transaction
        //----------------------------------------------------

        t = sequence_item::type_id::create("t");

        //----------------------------------------------------
        // Start Sequence Item
        //----------------------------------------------------

        start_item(t);

        //----------------------------------------------------
        // Apply Global FIFO Reset
        //----------------------------------------------------

        assert(t.randomize() with {

            // Assert resets
            i_w_rstn_tb == 1'b0;
            i_r_rstn_tb == 1'b0;

            // Disable FIFO activity
            i_w_inc_tb  == 1'b0;
            i_r_inc_tb  == 1'b0;  });

        //----------------------------------------------------
        // Debug Display
        //----------------------------------------------------

        t.display_sequence_item( "FIFO_RESET_SEQUENCE" );

        //----------------------------------------------------
        // Send Transaction to Driver
        //----------------------------------------------------

        finish_item(t);

    endtask

endclass

//----------------------------------------------------------------------------------
// Sequence Name : fifo_write_reset_sequence
// Description:
// Applies reset only to the write clock domain while keeping
// the read clock domain active.
//
// Verification Intent:
// - Verifies independent write-domain reset operation.
// - Checks write pointer reset behavior.
// - Verifies Gray write pointer reset.
// - Validates FULL flag recovery after reset.
// - Ensures read-domain logic remains operational during
//   write-domain reset.
//
// Expected Behavior:
// - Write pointer resets to zero.
// - Gray write pointer resets to zero.
// - FULL flag deasserts.
// - Read-side state remains unaffected.
//
//----------------------------------------------------------------------------------

class fifo_write_reset_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(fifo_write_reset_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "fifo_write_reset_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Applies reset to the write domain while keeping the
    // read domain out of reset. All FIFO activity is disabled
    // during the reset operation.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Create Transaction
        //----------------------------------------------------

        t = sequence_item::type_id::create("t");

        //----------------------------------------------------
        // Start Sequence Item
        //----------------------------------------------------

        start_item(t);

        //----------------------------------------------------
        // Apply Write-Domain Reset
        //----------------------------------------------------

        assert(t.randomize() with {

            // Reset write domain
            i_w_rstn_tb == 1'b0;

            // Keep read domain active
            i_r_rstn_tb == 1'b1;

            // Disable FIFO activity
            i_w_inc_tb  == 1'b0;
            i_r_inc_tb  == 1'b0;  });

        //----------------------------------------------------
        // Debug Display
        //----------------------------------------------------

        t.display_sequence_item("FIFO_WRITE_RESET_SEQUENCE");

        //----------------------------------------------------
        // Send Transaction to Driver
        //----------------------------------------------------

        finish_item(t);

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : fifo_read_reset_sequence
// Description:
// Applies reset only to the read clock domain while keeping
// the write clock domain active.
//
// Verification Intent:
// - Verifies independent read-domain reset operation.
// - Checks read pointer reset behavior.
// - Verifies Gray read pointer reset.
// - Validates EMPTY flag recovery after reset.
// - Ensures write-domain logic remains operational during
//   read-domain reset.
//
// Expected Behavior:
// - Read pointer resets to zero.
// - Gray read pointer resets to zero.
// - EMPTY flag reflects FIFO reset state correctly.
// - Write-side state remains unaffected.
//
//----------------------------------------------------------------------------------

class fifo_read_reset_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(fifo_read_reset_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "fifo_read_reset_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Applies reset to the read domain while keeping the
    // write domain active. All FIFO activity is disabled
    // during the reset operation.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Create Transaction
        //----------------------------------------------------

        t = sequence_item::type_id::create("t");

        //----------------------------------------------------
        // Start Sequence Item
        //----------------------------------------------------

        start_item(t);

        //----------------------------------------------------
        // Apply Read-Domain Reset
        //----------------------------------------------------

        assert(t.randomize() with {

            // Keep write domain active
            i_w_rstn_tb == 1'b1;

            // Reset read domain
            i_r_rstn_tb == 1'b0;

            // Disable FIFO activity
            i_w_inc_tb  == 1'b0;
            i_r_inc_tb  == 1'b0; });

        //----------------------------------------------------
        // Debug Display
        //----------------------------------------------------

        t.display_sequence_item( "FIFO_READ_RESET_SEQUENCE" );

        //----------------------------------------------------
        // Send Transaction to Driver
        //----------------------------------------------------

        finish_item(t);

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : fill_fifo_sequence
// Description:
// Performs consecutive write operations to fill the FIFO
// from EMPTY state toward FULL state.
//
// Verification Intent:
// - Verifies normal write-side functionality.
// - Exercises write pointer increment logic.
// - Verifies Gray write pointer generation.
// - Validates FIFO memory write operations.
// - Exercises write-to-read pointer synchronization.
// - Drives FIFO occupancy growth until FULL condition.
//
// Expected Behavior:
// - Write pointer advances on every valid write.
// - Data is stored into FIFO memory.
// - FULL flag eventually asserts.
// - EMPTY flag deasserts after initial writes.
// - No read activity occurs during this sequence.
//
//----------------------------------------------------------------------------------
class fill_fifo_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(fill_fifo_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "fill_fifo_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates a burst of write transactions while keeping
    // the read side idle. The number of transactions is
    // chosen to completely fill the FIFO.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Fill FIFO Through Consecutive Write Operations
        //----------------------------------------------------

        repeat(8)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Write Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Enable write operation
                i_w_inc_tb  == 1'b1;

                // Disable read operation
                i_r_inc_tb  == 1'b0; });

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item( "FILL_FIFO_SEQUENCE");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : empty_fifo_sequence
// Description:
// Performs consecutive read operations to drain the FIFO
// from a previously filled state until it reaches EMPTY.
//
// Verification Intent:
// - Verifies normal read-side functionality.
// - Exercises read pointer increment logic.
// - Verifies Gray read pointer generation.
// - Validates FIFO memory read operations.
// - Exercises read-domain CDC synchronization.
// - Drives FIFO occupancy reduction until EMPTY condition.
//
// Expected Behavior:
// - Read pointer advances on every valid read.
// - Data is retrieved from FIFO memory.
// - EMPTY flag eventually asserts.
// - FULL flag deasserts as occupancy decreases.
// - No write activity occurs during this sequence.
//
//----------------------------------------------------------------------------------

class empty_fifo_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(empty_fifo_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "empty_fifo_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates a burst of read transactions while keeping
    // the write side idle. The number of transactions is
    // chosen to completely drain the FIFO.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Empty FIFO Through Consecutive Read Operations
        //----------------------------------------------------

        repeat(8)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Read Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Disable write operation
                i_w_inc_tb  == 1'b0;

                // Enable read operation
                i_r_inc_tb  == 1'b1;});

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item("EMPTY_FIFO_SEQUENCE");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : attempt_write_to_full_sequence
// Description:
// Attempts additional write operations after the FIFO has
// already reached the FULL condition.
//
// Verification Intent:
// - Verifies FIFO overflow protection.
// - Confirms write pointer does not advance when FULL.
// - Validates FULL flag stability.
// - Verifies memory contents are not corrupted by invalid
//   write attempts.
// - Exercises write-side boundary condition handling.
//
// Expected Behavior:
// - FULL flag remains asserted.
// - Write pointer remains unchanged.
// - Gray write pointer remains unchanged.
// - No new data is written into FIFO memory.
// - FIFO occupancy remains at maximum capacity.
//
//----------------------------------------------------------------------------------

class attempt_write_to_full_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(attempt_write_to_full_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "attempt_write_to_full_sequence" );

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates write requests while read activity remains
    // disabled. This sequence is intended to execute after
    // the FIFO has already reached the FULL state.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Attempt Additional Writes Beyond FIFO Capacity
        //----------------------------------------------------

        repeat(3)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Overflow Attempt Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Attempt write operation
                i_w_inc_tb  == 1'b1;

                // Disable read operation
                i_r_inc_tb  == 1'b0;});

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item("ATTEMPT_WRITE_TO_FULL_SEQUENCE");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass

//----------------------------------------------------------------------------------
// Sequence Name : attempt_read_from_empty_sequence
// Description:
// Attempts additional read operations after the FIFO has
// already reached the EMPTY condition.
//
// Verification Intent:
// - Verifies FIFO underflow protection.
// - Confirms read pointer does not advance when EMPTY.
// - Validates EMPTY flag stability.
// - Ensures no invalid data is consumed from the FIFO.
// - Exercises read-side boundary condition handling.
//
// Expected Behavior:
// - EMPTY flag remains asserted.
// - Read pointer remains unchanged.
// - Gray read pointer remains unchanged.
// - No data is removed from the FIFO.
// - FIFO occupancy remains at zero.
//
//////////////////////////////////////////////////////////////////////////////////

class attempt_read_from_empty_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(attempt_read_from_empty_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name =
        "attempt_read_from_empty_sequence" );

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates read requests while write activity remains
    // disabled. This sequence is intended to execute after
    // the FIFO has already reached the EMPTY state.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Attempt Additional Reads Beyond FIFO Contents
        //----------------------------------------------------

        repeat(3)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Underflow Attempt Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Disable write operation
                i_w_inc_tb  == 1'b0;

                // Attempt read operation
                i_r_inc_tb  == 1'b1;});

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item("ATTEMPT_READ_FROM_EMPTY_SEQUENCE");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : write_then_read_sequence
// Description:
// Performs a complete FIFO transaction cycle consisting of:
// 1. FIFO Fill Phase
// 2. CDC Synchronization Window
// 3. FIFO Drain Phase
//
// Verification Intent:
// - Verifies end-to-end FIFO functionality.
// - Validates correct data movement from write side to read side.
// - Exercises both write and read pointer logic.
// - Verifies Gray-code pointer synchronization.
// - Validates FULL and EMPTY flag transitions.
// - Verifies scoreboard data integrity checking.
// - Exercises FIFO memory read and write paths.
//
// Expected Behavior:
// - FIFO accepts write transactions during fill phase.
// - Write pointer advances correctly.
// - Synchronizers propagate Gray pointers across domains.
// - Read operations retrieve data in FIFO order.
// - Scoreboard reports matching expected and actual data.
// - FIFO transitions from EMPTY -> ACTIVE -> EMPTY.
//
//----------------------------------------------------------------------------------

class write_then_read_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(write_then_read_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new (
        string name = "write_then_read_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Phase 1 : Fill FIFO
    // Phase 2 : Allow CDC synchronization
    // Phase 3 : Read back FIFO contents
    //////////////////////////////////////////////////////////

    task body();

        //////////////////////////////////////////////////////
        // WRITE PHASE
        //
        // Fill the FIFO using consecutive write operations
        // while keeping the read side idle.
        //////////////////////////////////////////////////////

        repeat(8)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Write Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Enable write operation
                i_w_inc_tb  == 1'b1;

                // Disable read operation
                i_r_inc_tb  == 1'b0;});

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item("WRITE_THEN_READ_SEQUENCE_WRITE");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

        //////////////////////////////////////////////////////
        // CDC SYNCHRONIZATION WINDOW
        //
        // Allows synchronized Gray-coded pointers to safely
        // propagate across clock domains before beginning
        // read operations.
        //
        // This delay is particularly important in
        // asynchronous FIFO verification.
        //////////////////////////////////////////////////////

        repeat(4)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Idle Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // No FIFO activity
                i_w_inc_tb  == 1'b0;
                i_r_inc_tb  == 1'b0;});

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

        //////////////////////////////////////////////////////
        // READ PHASE
        //
        // Drain FIFO using consecutive read operations
        // while keeping the write side idle.
        //////////////////////////////////////////////////////

        repeat(8)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Read Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Disable write operation
                i_w_inc_tb  == 1'b0;

                // Enable read operation
                i_r_inc_tb  == 1'b1;});

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item("WRITE_THEN_READ_SEQUENCE_READ");

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass
 

//----------------------------------------------------------------------------------
// Sequence Name : concurrent_rw_sequence
// Description:
// Generates simultaneous read and write operations while
// both clock domains remain active.
//
// Verification Intent:
// - Verifies concurrent FIFO operation.
// - Exercises simultaneous read and write requests.
// - Validates independent write and read clock domains.
// - Verifies pointer updates under concurrent traffic.
// - Exercises Gray-pointer synchronization in both directions.
// - Verifies correct occupancy tracking.
// - Validates scoreboard operation during mixed traffic.
// - Exercises realistic FIFO usage scenarios.
//
// Expected Behavior:
// - Write operations occur when FIFO is not FULL.
// - Read operations occur when FIFO is not EMPTY.
// - Write and read pointers advance independently.
// - FIFO occupancy changes according to traffic conditions.
// - Data ordering remains FIFO compliant.
// - No data corruption occurs during simultaneous activity.
//
//////////////////////////////////////////////////////////////////////////////////

class concurrent_rw_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(concurrent_rw_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new
    (
        string name = "concurrent_rw_sequence"
    );

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates simultaneous read and write transactions
    // to exercise concurrent FIFO activity.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Concurrent Read/Write Activity
        //----------------------------------------------------

        repeat(4)
        begin

            //------------------------------------------------
            // Create Transaction
            //------------------------------------------------

            t = sequence_item::type_id::create("t");

            //------------------------------------------------
            // Start Sequence Item
            //------------------------------------------------

            start_item(t);

            //------------------------------------------------
            // Generate Concurrent RW Transaction
            //------------------------------------------------

            assert(t.randomize() with {

                // Keep both domains active
                i_w_rstn_tb == 1'b1;
                i_r_rstn_tb == 1'b1;

                // Enable write operation
                i_w_inc_tb  == 1'b1;

                // Enable read operation
                i_r_inc_tb  == 1'b1;

            });

            //------------------------------------------------
            // Debug Display
            //------------------------------------------------

            t.display_sequence_item(
                "CONCURRENT_RW_SEQUENCE"
            );

            //------------------------------------------------
            // Send Transaction to Driver
            //------------------------------------------------

            finish_item(t);

        end

    endtask

endclass


//----------------------------------------------------------------------------------
// Sequence Name : all_one_sequence
// Description:
// Generates a write transaction using an all-ones data pattern (16'hFFFF).
//
// Verification Intent:
// - Verifies FIFO data integrity using a maximum-value pattern.
// - Exercises FIFO memory write path.
// - Verifies data storage of all logic 1's.
// - Supports scoreboard data comparison.
// - Contributes to functional coverage of data patterns.
// - Helps identify stuck-at-0 and data corruption issues.
//
// Expected Behavior:
// - 16'hFFFF is written into the FIFO.
// - Write pointer advances if FIFO is not FULL.
// - Data is stored correctly in FIFO memory.
// - Scoreboard receives matching write/read data.
// - Readback data should exactly match 16'hFFFF.
//
//----------------------------------------------------------------------------------

class all_one_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(all_one_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "all_one_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates a single write transaction containing an
    // all-ones data pattern.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Create Transaction
        //----------------------------------------------------

        t = sequence_item::type_id::create("t");

        //----------------------------------------------------
        // Start Sequence Item
        //----------------------------------------------------

        start_item(t);

        //----------------------------------------------------
        // Generate All-Ones Data Pattern
        //----------------------------------------------------

        assert(t.randomize() with {

            // Keep both domains active
            i_w_rstn_tb == 1'b1;
            i_r_rstn_tb == 1'b1;

            // Enable write operation
            i_w_inc_tb  == 1'b1;

            // Disable read operation
            i_r_inc_tb  == 1'b0;

            // Maximum data pattern
            i_w_data_tb == 16'hFFFF; });

        //----------------------------------------------------
        // Debug Display
        //----------------------------------------------------

        t.display_sequence_item("ALL_ONE_SEQUENCE" );

        //----------------------------------------------------
        // Send Transaction to Driver
        //----------------------------------------------------

        finish_item(t);

    endtask

endclass



//----------------------------------------------------------------------------------
// Sequence Name : all_zero_sequence
// Description:
// Generates a write transaction using an all-zeros data pattern(16'h0000).
//
// Verification Intent:
// - Verifies FIFO data integrity using a minimum-value pattern.
// - Exercises FIFO memory write path.
// - Verifies data storage of all logic 0's.
// - Supports scoreboard data comparison.
// - Contributes to functional coverage of data patterns.
// - Helps identify stuck-at-1 and data corruption issues.
//
// Expected Behavior:
// - 16'h0000 is written into the FIFO.
// - Write pointer advances if FIFO is not FULL.
// - Data is stored correctly in FIFO memory.
// - Scoreboard receives matching write/read data.
// - Readback data should exactly match 16'h0000.
//
//----------------------------------------------------------------------------------

class all_zero_sequence extends uvm_sequence #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_object_utils(all_zero_sequence)

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //////////////////////////////////////////////////////////

    sequence_item t;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(string name = "all_zero_sequence");

        super.new(name);

    endfunction

    //////////////////////////////////////////////////////////
    // Sequence Body
    //
    // Generates a single write transaction containing an
    // all-zeros data pattern.
    //////////////////////////////////////////////////////////

    task body();

        //----------------------------------------------------
        // Create Transaction
        //----------------------------------------------------

        t = sequence_item::type_id::create("t");

        //----------------------------------------------------
        // Start Sequence Item
        //----------------------------------------------------

        start_item(t);

        //----------------------------------------------------
        // Generate All-Zeros Data Pattern
        //----------------------------------------------------

        assert(t.randomize() with {

            // Keep both domains active
            i_w_rstn_tb == 1'b1;
            i_r_rstn_tb == 1'b1;

            // Enable write operation
            i_w_inc_tb  == 1'b1;

            // Disable read operation
            i_r_inc_tb  == 1'b0;

            // Minimum data pattern
            i_w_data_tb == 16'h0000;});

        //----------------------------------------------------
        // Debug Display
        //----------------------------------------------------

        t.display_sequence_item("ALL_ZERO_SEQUENCE");

        //----------------------------------------------------
        // Send Transaction to Driver
        //----------------------------------------------------

        finish_item(t);

    endtask

endclass

