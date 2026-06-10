//-------------------------------------------------------------------------------------------

// Description:
// UVM monitor responsible for observing DUT activity and
// converting pin-level activity into transaction-level data.
//
// Responsibilities:
// - Monitors write-domain activity.
// - Monitors read-domain activity.
// - Samples DUT outputs through clocking blocks.
// - Creates transaction objects.
// - Sends transactions through analysis port.
//
// Notes:
// - Separate monitoring threads are used for write and
//   read clock domains.
// - Monitor is passive and never drives DUT signals.
// - Acts as the transaction source for:
//      • Scoreboard
//      • Subscriber / Coverage
//
//----------------------------------------------------------------------------------------------

class monitor extends uvm_monitor;

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(monitor)

    //////////////////////////////////////////////////////////////////////
    // Virtual Interface
    //
    // Provides access to DUT signals through the UVM interface abstraction.
    //////////////////////////////////////////////////////////////////////

    virtual fifo_if moni_intf;

    //////////////////////////////////////////////////////////
    // Analysis Port
    //
    // Broadcasts monitored transactions to all analysis
    // components connected in the environment.
    //////////////////////////////////////////////////////////

    uvm_analysis_port #(sequence_item) mon_ap;

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "monitor",
        uvm_component parent = null);

        super.new(name, parent);

    endfunction

    //////////////////////////////////////////////////////////
    // Build Phase
    //
    // Retrieves the virtual interface and creates the
    // analysis port used for transaction broadcasting.
    //////////////////////////////////////////////////////////

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        //----------------------------------------------------
        // Obtain Virtual Interface
        //----------------------------------------------------

        if(!uvm_config_db #(virtual fifo_if)::get(
            this,"", "my_vif", moni_intf ))
          
        begin
            `uvm_fatal(get_type_name(),
                "Failed to get virtual interface"  )

        end

        //----------------------------------------------------
        // Create Analysis Port
        //----------------------------------------------------

        mon_ap = new("mon_ap", this);

    endfunction

    //////////////////////////////////////////////////////////
    // Run Phase
    //
    // Launch independent monitoring processes for:
    //   1. Write Clock Domain
    //   2. Read Clock Domain
    //
    // This mirrors the asynchronous nature of the FIFO.
    //////////////////////////////////////////////////////////

    task run_phase(uvm_phase phase);

        fork

            //////////////////////////////////////////////////
            // WRITE DOMAIN MONITORING
            //
            // Captures valid write-side transactions and
            // forwards them through the analysis port.
            //////////////////////////////////////////////////

            forever
            begin

                sequence_item t_wr;

                //------------------------------------------------
                // Create Transaction
                //------------------------------------------------

                t_wr =sequence_item::type_id::create("t_wr");

                //------------------------------------------------
                // Default Read-Domain Fields
                //
                // These fields are unused for write
                // transactions but are initialized for
                // transaction consistency.
                //------------------------------------------------

                t_wr.i_r_rstn_tb = 1'b1;
                t_wr.i_r_inc_tb  = 1'b0;

                t_wr.o_empty_tb  = 1'b0;
                t_wr.o_r_data_tb = '0;

                //------------------------------------------------
                // Wait for Write Clock Event
                //------------------------------------------------

                @(moni_intf.wr_mon_cb);

                //------------------------------------------------
                // Sample Write-Domain Activity
                //------------------------------------------------

                t_wr.i_w_rstn_tb = moni_intf.wr_mon_cb.i_w_rstn;

                t_wr.i_w_inc_tb =  moni_intf.wr_mon_cb.i_w_inc;

                t_wr.i_w_data_tb =  moni_intf.wr_mon_cb.i_w_data;

                t_wr.o_full_tb = moni_intf.wr_mon_cb.o_full;

                //------------------------------------------------
                // Ignore Reset Cycles
                //------------------------------------------------

                if(!t_wr.i_w_rstn_tb)
                    continue;

                //------------------------------------------------
                // Publish Valid Write Transactions
                //------------------------------------------------

                if(t_wr.i_w_inc_tb)
                begin

                    mon_ap.write(t_wr);

                end

            end

            //////////////////////////////////////////////////
            // READ DOMAIN MONITORING
            //
            // Captures valid read-side transactions and
            // forwards them through the analysis port.
            //////////////////////////////////////////////////

            forever
            begin

                sequence_item t_rd;

                //------------------------------------------------
                // Create Transaction
                //------------------------------------------------

                t_rd = sequence_item::type_id::create("t_rd");

                //------------------------------------------------
                // Default Write-Domain Fields
                //
                // These fields are unused for read
                // transactions but are initialized for
                // transaction consistency.
                //------------------------------------------------

                t_rd.i_w_rstn_tb = 1'b1;
                t_rd.i_w_inc_tb  = 1'b0;

                t_rd.i_w_data_tb = '0;
                t_rd.o_full_tb   = 1'b0;

                //------------------------------------------------
                // Wait for Read Clock Event
                //------------------------------------------------

                @(moni_intf.rd_mon_cb);

                //------------------------------------------------
                // Sample Read-Domain Activity
                //------------------------------------------------

                t_rd.i_r_rstn_tb = moni_intf.rd_mon_cb.i_r_rstn;

                t_rd.i_r_inc_tb = moni_intf.rd_mon_cb.i_r_inc;

                t_rd.o_r_data_tb =  moni_intf.rd_mon_cb.o_r_data;

                t_rd.o_empty_tb = moni_intf.rd_mon_cb.o_empty;

                //------------------------------------------------
                // Ignore Reset Cycles
                //------------------------------------------------

                if(!t_rd.i_r_rstn_tb)
                    continue;

                //------------------------------------------------
                // Publish Valid Read Transactions
                //------------------------------------------------

                if(t_rd.i_r_inc_tb)
                begin

                    mon_ap.write(t_rd);

                end

            end

        join_none

    endtask

endclass
