
//-------------------------------------------------------------------------------------
// Description: Top-level UVM test for the Asynchronous FIFO verification environment.
//
// Responsibilities:
// - Creates the verification environment.
// - Creates all directed test sequences.
// - Controls simulation execution.
// - Launches verification scenarios.
// - Manages UVM objections.
//
// Verification Plan:
//
//   Reset Verification
//      ├─ Global Reset
//      ├─ Write-Domain Reset
//      └─ Read-Domain Reset
//
//   FIFO Functional Verification
//      ├─ FIFO Fill
//      ├─ FIFO Empty
//      ├─ Full Condition
//      ├─ Empty Condition
//      ├─ Write Then Read
//      └─ Concurrent Read/Write
//
//   Data Integrity Verification
//      ├─ All-Ones Pattern
//      └─ All-Zeros Pattern
//
// Notes:
// - Uses directed sequences.
// - Executes scenarios sequentially.
// - Provides deterministic regression behavior.
//
//-------------------------------------------------------------------------------------

class test extends uvm_test;

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(test)

    //////////////////////////////////////////////////////////
    // Environment Handle
    //
    // Top-level verification environment containing:
    //   Agent
    //   Scoreboard
    //   Subscriber
    //////////////////////////////////////////////////////////

    environment env_h;

    //////////////////////////////////////////////////////////
    // Sequence Handles
    //
    // Directed sequences used to verify Async FIFO
    // functionality and corner cases.
    //////////////////////////////////////////////////////////

    fifo_reset_sequence               reset_seq;
    fifo_write_reset_sequence         wr_reset_seq;
    fifo_read_reset_sequence          rd_reset_seq;

    fill_fifo_sequence                fill_seq;
    empty_fifo_sequence               empty_seq;

    attempt_write_to_full_sequence    full_seq;
    attempt_read_from_empty_sequence  empty_read_seq;

    write_then_read_sequence          wr_rd_seq;

    concurrent_rw_sequence            concurrent_seq;

    all_one_sequence                  all_one_seq;
    all_zero_sequence                 all_zero_seq;

    //////////////////////////////////////////////////////////
    // Virtual Interface
    //
    // Retrieved from configuration database for future
    // test-level control and debug capability.
    //////////////////////////////////////////////////////////

    virtual fifo_if test_intf;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "test",
        uvm_component parent = null);

        super.new(name, parent);

    endfunction

    //////////////////////////////////////////////////////////
    // Build Phase
    //
    // Creates environment and all verification sequences.
    //////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Create Verification Environment
        //----------------------------------------------------

        env_h = environment::type_id::create("env_h",this);

        //----------------------------------------------------
        // Create Reset Sequences
        //----------------------------------------------------

        reset_seq =fifo_reset_sequence::type_id::create("reset_seq");

        wr_reset_seq =fifo_write_reset_sequence::type_id::create("wr_reset_seq");

        rd_reset_seq =fifo_read_reset_sequence::type_id::create("rd_reset_seq");

        //----------------------------------------------------
        // Create Functional Sequences
        //----------------------------------------------------

        fill_seq =fill_fifo_sequence::type_id::create("fill_seq");

        empty_seq =empty_fifo_sequence::type_id::create("empty_seq");

        full_seq =attempt_write_to_full_sequence::type_id::create("full_seq");

        empty_read_seq =attempt_read_from_empty_sequence::type_id::create("empty_read_seq");

        wr_rd_seq =write_then_read_sequence::type_id::create("wr_rd_seq");

        concurrent_seq =concurrent_rw_sequence::type_id::create("concurrent_seq");

        //----------------------------------------------------
        // Create Data Pattern Sequences
        //----------------------------------------------------

        all_one_seq =all_one_sequence::type_id::create("all_one_seq");

        all_zero_seq =all_zero_sequence::type_id::create("all_zero_seq");

        //----------------------------------------------------
        // Retrieve Virtual Interface
        //----------------------------------------------------

        if(!uvm_config_db #(virtual fifo_if)::get(
            this,"","my_vif",test_intf))
          
        begin
            `uvm_fatal(get_type_name(),"Failed to get virtual interface")

        end

    endfunction

    //////////////////////////////////////////////////////////
    // Run Phase
    //
    // Executes the complete Async FIFO verification plan.
    //////////////////////////////////////////////////////////

    task run_phase(uvm_phase phase);

        //----------------------------------------------------
        // Start Test
        //----------------------------------------------------

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
            "STARTING FIFO TEST",UVM_LOW);

        //////////////////////////////////////////////////////
        // RESET VERIFICATION
        //////////////////////////////////////////////////////

        reset_seq.start(env_h.agent_h.seqr_h);

        wr_reset_seq.start(env_h.agent_h.seqr_h);

        rd_reset_seq.start(env_h.agent_h.seqr_h);

        //////////////////////////////////////////////////////
        // FUNCTIONAL VERIFICATION
        //////////////////////////////////////////////////////

        fill_seq.start(env_h.agent_h.seqr_h);

        full_seq.start(env_h.agent_h.seqr_h);

        empty_seq.start(env_h.agent_h.seqr_h);

        empty_read_seq.start(env_h.agent_h.seqr_h);

        wr_rd_seq.start(env_h.agent_h.seqr_h);

        concurrent_seq.start(env_h.agent_h.seqr_h);

        //////////////////////////////////////////////////////
        // DATA PATTERN VERIFICATION
        //////////////////////////////////////////////////////

        all_one_seq.start(env_h.agent_h.seqr_h);

        all_zero_seq.start(env_h.agent_h.seqr_h);

        //----------------------------------------------------
        // End Test
        //----------------------------------------------------

        `uvm_info(get_type_name(),
            "FIFO TEST COMPLETED",UVM_LOW);

        phase.drop_objection(this);

    endtask

endclass
