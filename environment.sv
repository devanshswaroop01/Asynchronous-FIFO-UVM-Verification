
//-------------------------------------------------------------------------------------------

// Description: Top-level UVM environment for the Async FIFO verificationarchitecture.
//
// Responsibilities:
// - Instantiates all major verification components.
// - Connects transaction analysis paths.
// - Integrates stimulus, checking, and coverage collection.
//
// Architecture:
//
//                     +----------------+
//                     |     Agent      |
//                     +----------------+
//                              |
//                              |
//                      Monitor Analysis Port
//                              |
//                 +------------+------------+
//                 |                         |
//                 v                         v
//          +-------------+         +---------------+
//          | Subscriber  |         |  Scoreboard   |
//          +-------------+         +---------------+
//
// Notes:
// - Agent generates and monitors DUT activity.
// - Subscriber collects functional coverage.
// - Scoreboard performs functional checking.
// - Monitor broadcasts transactions to both
//   scoreboard and subscriber.
//
//-------------------------------------------------------------------------------------------

class environment extends uvm_env;

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(environment)

    //////////////////////////////////////////////////////////
    // Component Handles
    //
    // Agent      : Stimulus generation and monitoring.
    // Subscriber : Functional coverage collection.
    // Scoreboard : Reference-model based checking.
    //////////////////////////////////////////////////////////

    agent       agent_h;
    subscriber  sub_h;
    scoreboard  sb_h;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new (
        string name = "environment",
        uvm_component parent = null );

        super.new(name, parent);

    endfunction

    //////////////////////////////////////////////////////////
    // Build Phase
    //
    // Creates all environment-level verificationcomponents.
    //////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Create Agent
        //----------------------------------------------------

        agent_h = agent::type_id::create("agent_h",this);

        //----------------------------------------------------
        // Create Subscriber
        //----------------------------------------------------

        sub_h = subscriber::type_id::create("sub_h",this);

        //----------------------------------------------------
        // Create Scoreboard
        //----------------------------------------------------

        sb_h = scoreboard::type_id::create("sb_h",this);

    endfunction

    //////////////////////////////////////////////////////////
    // Connect Phase
    //
    // Establishes transaction broadcast paths from the
    // monitor to coverage and checking components.
    //////////////////////////////////////////////////////////

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        //----------------------------------------------------
        // Monitor -> Subscriber
        //
        // Functional coverage collection path.
        //----------------------------------------------------

        agent_h.mon_h.mon_ap.connect(sub_h.analysis_export);

        //----------------------------------------------------
        // Monitor -> Scoreboard
        //
        // Functional checking path.
        //----------------------------------------------------

        agent_h.mon_h.mon_ap.connect(sb_h.sb_imp);

    endfunction

endclass
