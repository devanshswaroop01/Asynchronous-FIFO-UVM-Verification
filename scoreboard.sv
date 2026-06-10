
//-------------------------------------------------------------------------------------
// Description:  Reference model and checking component for the Async FIFO.
//
// Responsibilities:
// - Maintains a reference FIFO model using a SystemVerilog queue.
// - Tracks valid write transactions.
// - Tracks valid read transactions.
// - Compares DUT output against expected data.
// - Handles reset recovery.
// - Collects pass/fail statistics.
//
// Verification Strategy:
// - Valid writes are stored in a reference queue.
// - Valid reads remove data from the reference queue.
// - DUT read data is compared against reference data.
// - Any mismatch is reported as a UVM error.
//
// Notes:
// - Implements FIFO ordering using push_back/pop_front.
// - Acts as the primary functional checker.
// - Receives transactions from the monitor through an
//   analysis connection.
//
//--------------------------------------------------------------------------------------------

class scoreboard extends uvm_scoreboard;

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(scoreboard)

    //////////////////////////////////////////////////////////
    // Analysis Import
    //
    // Receives transactions broadcast by the monitor.
    //////////////////////////////////////////////////////////

    uvm_analysis_imp #(sequence_item, scoreboard)sb_imp;

    //////////////////////////////////////////////////////////
    // Reference FIFO Model
    //
    // Queue-based golden reference used to emulate FIFO
    // behavior for comparison against DUT outputs.
    //////////////////////////////////////////////////////////

    bit [15:0] ref_queue[$];

    //////////////////////////////////////////////////////////
    // Statistics Counters
    //
    // Used for regression summary and debug reporting.
    //////////////////////////////////////////////////////////

    int total_writes;
    int total_reads;

    int pass_count;
    int fail_count;

    /////////////////////////////////////////////////////////////////////
    // Reset Tracking
    //
    // Prevents multiple queue clears during a continuous reset interval.
    /////////////////////////////////////////////////////////////////////

    bit reset_active;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "scoreboard",
        uvm_component parent = null );

        super.new(name, parent);

    endfunction

    //////////////////////////////////////////////////////////////////////
    // Build Phase
    //
    // Creates analysis import and initializes internal scoreboard state.
    //////////////////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Create Analysis Import
        //----------------------------------------------------

        sb_imp = new("sb_imp", this);

        //----------------------------------------------------
        // Initialize Statistics
        //----------------------------------------------------

        total_writes = 0;
        total_reads  = 0;

        pass_count   = 0;
        fail_count   = 0;

        //----------------------------------------------------
        // Reset State
        //----------------------------------------------------

        reset_active = 0;

    endfunction

    //////////////////////////////////////////////////////////
    // Analysis Write Method
    //
    // Called automatically whenever the monitor publishes
    // a transaction through the analysis port.
    //
    // Processing Flow:
    //   1. Handle reset activity
    //   2. Track valid writes
    //   3. Track valid reads
    //   4. Compare DUT vs reference model
    //////////////////////////////////////////////////////////

    function void write(sequence_item t);

        bit [15:0] expected_data;

        /////////////////////////////////////////////////////////////////
        // RESET HANDLING
        //
        // Clear reference model whenever either FIFO domain  enters reset.
        //////////////////////////////////////////////////////////////////

        if((t.i_w_rstn_tb === 1'b0) ||
           (t.i_r_rstn_tb === 1'b0))
        begin

            //------------------------------------------------
            // Clear Queue Once Per Reset Event
            //------------------------------------------------

            if(!reset_active)
            begin

                ref_queue.delete();

                reset_active = 1'b1;

              `uvm_info( get_type_name(),
                    "RESET DETECTED -> REFERENCE QUEUE CLEARED", UVM_LOW  );

            end

            return;

        end

        //----------------------------------------------------
        // Reset Release Detection
        //----------------------------------------------------

        if((t.i_w_rstn_tb === 1'b1) &&
           (t.i_r_rstn_tb === 1'b1))
        begin

            reset_active = 1'b0;

        end

        //////////////////////////////////////////////////////
        // WRITE TRANSACTION PROCESSING
        //
        // Store every successful DUT write into the
        // reference FIFO model.
        //////////////////////////////////////////////////////

        if(
            (t.i_w_rstn_tb === 1'b1) &&
            (t.i_w_inc_tb  === 1'b1) &&
            (t.o_full_tb   === 1'b0))
        begin

            //------------------------------------------------
            // Update Reference FIFO
            //------------------------------------------------

            ref_queue.push_back(t.i_w_data_tb);

            total_writes++;

            `uvm_info( get_type_name(),
                      $sformatf( "WRITE SUCCESS : DATA = 0x%0h", t.i_w_data_tb),UVM_HIGH);

        end

        //////////////////////////////////////////////////////
        // READ TRANSACTION PROCESSING
        //
        // Compare DUT output against reference FIFO model.
        //////////////////////////////////////////////////////

        if(
            (t.i_r_rstn_tb === 1'b1) &&
            (t.i_r_inc_tb  === 1'b1) &&
            (t.o_empty_tb  === 1'b0))
        begin

            total_reads++;

            //------------------------------------------------
            // Reference Queue Underflow Protection
            //------------------------------------------------

            if(ref_queue.size() == 0)
            begin

                fail_count++;

                `uvm_warning(  get_type_name(),
                           "READ OCCURRED BEFORE REFERENCE QUEUE UPDATED");

            end

            else
            begin

                //------------------------------------------------
                // Expected FIFO Data
                //------------------------------------------------

                expected_data = ref_queue.pop_front();

                //------------------------------------------------
                // DUT vs Reference Comparison
                //------------------------------------------------

                if(expected_data == t.o_r_data_tb)
                begin

                    pass_count++;

                    `uvm_info( get_type_name(),
                        $sformatf(  "READ MATCH : EXPECTED = 0x%0h | ACTUAL = 0x%0h",
                         expected_data, t.o_r_data_tb),UVM_MEDIUM);

                end

                else
                begin

                    fail_count++;

                  `uvm_error( get_type_name(),
                        $sformatf("READ MISMATCH : EXPECTED = 0x%0h | ACTUAL = 0x%0h",
                            expected_data, t.o_r_data_tb));

                end

            end

        end

    endfunction

    //////////////////////////////////////////////////////////
    // Report Phase
    //
    // Prints final scoreboard statistics at the end of simulation.
    //////////////////////////////////////////////////////////

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        // Existing report code unchanged

    endfunction

endclass
