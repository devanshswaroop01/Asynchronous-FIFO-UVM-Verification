//-----------------------------------------------------------------------------------------

// Description: Active UVM agent for the Async FIFO verification environment.
//
// Responsibilities:
// - Instantiates driver, sequencer, and monitor.
// - Connects driver and sequencer.
// - Serves as the primary stimulus generation block.
//
// Architecture:
//
//          +------------+
//          | Sequencer  |
//          +------------+
//                 |
//                 v
//          +------------+
//          |  Driver    |
//          +------------+
//
//          +------------+
//          |  Monitor   |
//          +------------+
//
// Notes:
// - Configured as an active agent.
// - Generates and monitors FIFO transactions.
// - Provides the stimulus path for the DUT.
//
//---------------------------------------------------------------------------------
class agent extends uvm_agent;

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(agent)

    //////////////////////////////////////////////////////////
    // Component Handles
    //
    // Driver    : Drives DUT stimulus.
    // Sequencer : Supplies transactions to the driver.
    // Monitor   : Observes DUT activity.
    //////////////////////////////////////////////////////////

    monitor   mon_h;
    driver    drv_h;
    sequencer seqr_h;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "agent",
        uvm_component parent = null);

        super.new(name, parent);

    endfunction

    //////////////////////////////////////////////////////////
    // Build Phase
    //
    // Creates all agent-level verification components.
    //////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Create Monitor
        //----------------------------------------------------

        mon_h =monitor::type_id::create("mon_h",this);

        //----------------------------------------------------
        // Create Driver
        //----------------------------------------------------

        drv_h =driver::type_id::create("drv_h",this);

        //----------------------------------------------------
        // Create Sequencer
        //----------------------------------------------------

        seqr_h =
        sequencer::type_id::create("seqr_h",this);

    endfunction

    ////////////////////////////////////////////////////////////////////
    // Connect Phase
    //
    // Establishes the transaction path between the sequencer and driver.
    ///////////////////////////////////////////////////////////////////////

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        //----------------------------------------------------
        // Sequencer -> Driver Connection
        //----------------------------------------------------

      drv_h.seq_item_port.connect( seqr_h.seq_item_export );

    endfunction

endclass

