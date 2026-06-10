//-----------------------------------------------------------------------------------

// Description:
// UVM driver responsible for converting sequence transactions
// into pin-level activity on the Async FIFO interface.
//
// Responsibilities:
// - Retrieves transactions from the sequencer.
// - Drives write-domain stimulus.
// - Drives read-domain stimulus.
// - Performs interface initialization.
// - Applies reset during simulation startup.
// - Supports independent write and read clock domains.
//
// Notes:
// - Uses dedicated clocking blocks from fifo_if.
// - Write and read domains are driven concurrently.
// - Designed for asynchronous FIFO verification.
//
//--------------------------------------------------------------------------------------

class driver extends uvm_driver #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(driver)

    //////////////////////////////////////////////////////////////////////
    // Virtual Interface
    //
    // Provides access to DUT signals through the UVM interface abstraction.
    ///////////////////////////////////////////////////////////////////////

    virtual fifo_if driv_intf;

    //////////////////////////////////////////////////////////
    // Transaction Handle
    //
    // Stores transactions received from the sequencer.
    //////////////////////////////////////////////////////////

    sequence_item t_drive;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new (
        string name = "driver",
        uvm_component parent = null);

        super.new(name, parent);

    endfunction

    ///////////////////////////////////////////////////////////////////////
    // Build Phase
    //
    // Retrieves the virtual interface and creates local transaction objects.
    ////////////////////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Obtain Virtual Interface
        //----------------------------------------------------

        if(!uvm_config_db #(virtual fifo_if)::get(
            this, "",  "my_vif",driv_intf ))
       
          begin
            `uvm_fatal( get_type_name(),
                "Failed to get virtual interface" )

        end

        //----------------------------------------------------
        // Create Transaction Handle
        //----------------------------------------------------

        t_drive = sequence_item::type_id::create("t_drive");

    endfunction

    //////////////////////////////////////////////////////////
    // Run Phase
    //
    // 1. Initialize interface.
    // 2. Wait for transactions from the sequencer.
    // 3. Drive transactions onto the DUT interface.
    //////////////////////////////////////////////////////////

    task run_phase(uvm_phase phase);

        //----------------------------------------------------
        // Apply Initial Reset Sequence
        //----------------------------------------------------

        initialize_interface();

        //----------------------------------------------------
        // Main Driver Loop
        //----------------------------------------------------

        forever
        begin

            seq_item_port.get_next_item(t_drive);

            drive_transaction(t_drive);

            seq_item_port.item_done();

        end

    endtask

    //////////////////////////////////////////////////////////
    // Interface Initialization
    //
    // Places the DUT into a known reset state before any
    // verification stimulus is applied.
    //////////////////////////////////////////////////////////

    task initialize_interface();

        //----------------------------------------------------
        // Write-Domain Initialization
        //----------------------------------------------------

        driv_intf.wr_drv_cb.i_w_rstn <= 1'b0;
        driv_intf.wr_drv_cb.i_w_inc  <= 1'b0;
        driv_intf.wr_drv_cb.i_w_data <= '0;

        //----------------------------------------------------
        // Read-Domain Initialization
        //----------------------------------------------------

        driv_intf.rd_drv_cb.i_r_rstn <= 1'b0;
        driv_intf.rd_drv_cb.i_r_inc  <= 1'b0;

        //----------------------------------------------------
        // Hold Reset
        //
        // Allow DUT logic to stabilize before releasing reset.
        //----------------------------------------------------

        repeat(5)
            @(posedge driv_intf.w_clk);

        //----------------------------------------------------
        // Release Reset
        //----------------------------------------------------

        driv_intf.wr_drv_cb.i_w_rstn <= 1'b1;
        driv_intf.rd_drv_cb.i_r_rstn <= 1'b1;

        //----------------------------------------------------
        // Stabilization Cycles
        //----------------------------------------------------

        repeat(2)
            @(posedge driv_intf.w_clk);

        `uvm_info( get_type_name(),
            "Driver Interface Initialized", UVM_LOW  );

    endtask

    //////////////////////////////////////////////////////////
    // Transaction Driver
    //
    // Converts a transaction-level object into signal-level
    // activity on both FIFO clock domains.
    //
    // Write and read sides are driven concurrently to model
    // true asynchronous FIFO operation.
    //////////////////////////////////////////////////////////

    task drive_transaction(sequence_item trans);

        fork

            //////////////////////////////////////////////////
            // Write-Domain Driving
            //////////////////////////////////////////////////

            begin

                @(posedge driv_intf.w_clk);

                driv_intf.wr_drv_cb.i_w_rstn <= trans.i_w_rstn_tb;

                driv_intf.wr_drv_cb.i_w_inc <= trans.i_w_inc_tb;

                driv_intf.wr_drv_cb.i_w_data <= trans.i_w_data_tb;

            end

            //////////////////////////////////////////////////
            // Read-Domain Driving
            //////////////////////////////////////////////////

            begin

                @(posedge driv_intf.r_clk);

                driv_intf.rd_drv_cb.i_r_rstn <=  trans.i_r_rstn_tb;

                driv_intf.rd_drv_cb.i_r_inc <=   trans.i_r_inc_tb;

            end

        join

    endtask

endclass
