
//----------------------------------------------------------------------------------------------
// Description:  Functional coverage collector for the Async FIFO UVM verification environment.
//
// Responsibilities:
// - Receives transactions from the monitor.
// - Samples functional coverage.
// - Tracks protocol activity.
// - Tracks status flag transitions.
// - Tracks data pattern usage.
// - Reports overall coverage percentage.
//
// Coverage Areas:
// - Write reset activity
// - Read reset activity
// - Write enable activity
// - Read enable activity
// - FULL flag behavior
// - EMPTY flag behavior
// - Write data patterns
// - Read data patterns
//
// Notes:
// - Receives transactions through analysis connections.
// - Coverage is sampled only when transactions are observed.
// - Acts as the primary functional coverage component.
//
//-----------------------------------------------------------------------------------------

class subscriber extends uvm_subscriber #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(subscriber)

    //////////////////////////////////////////////////////////
    // Coverage Transaction
    //
    // Stores the latest transaction received from the
    // monitor for coverage sampling.
    //////////////////////////////////////////////////////////

    sequence_item cov_item;

    //////////////////////////////////////////////////////////
    // Functional Coverage Model
    //
    // Captures protocol behavior, status transitions,
    // and data pattern activity.
    //////////////////////////////////////////////////////////

    covergroup fifo_cg;

        //////////////////////////////////////////////////////
        // Write Reset Coverage
        //
        // Tracks write-domain reset assertion, deassertion,
        // and reset transitions.
        //////////////////////////////////////////////////////

        write_reset : coverpoint cov_item.i_w_rstn_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        //////////////////////////////////////////////////////
        // Read Reset Coverage
        //
        // Tracks read-domain reset assertion, deassertion,
        // and reset transitions.
        //////////////////////////////////////////////////////

        read_reset : coverpoint cov_item.i_r_rstn_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        //////////////////////////////////////////////////////
        // Write Enable Coverage
        //
        // Tracks write activity and enable transitions.
        //////////////////////////////////////////////////////

        write_increment : coverpoint cov_item.i_w_inc_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        //////////////////////////////////////////////////////
        // Read Enable Coverage
        //
        // Tracks read activity and enable transitions.
        //////////////////////////////////////////////////////

        read_increment : coverpoint cov_item.i_r_inc_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        ///////////////////////////////////////////////////////////////
        // FULL Flag Coverage
        //
        // Ensures the FIFO reaches FULL state and transitions correctly.
        ///////////////////////////////////////////////////////////////

        full_flag : coverpoint cov_item.o_full_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        /////////////////////////////////////////////////////////////////
        // EMPTY Flag Coverage
        //
        // Ensures the FIFO reaches EMPTY state and transitions correctly.
        //////////////////////////////////////////////////////////////////

        empty_flag : coverpoint cov_item.o_empty_tb{
            bins low   = {0};
            bins high  = {1};

            bins hi_lw = (1 => 0);
            bins lw_hi = (0 => 1);}

        //////////////////////////////////////////////////////
        // Write Data Coverage
        //
        // Tracks special patterns and general payload
        // distribution during write operations.
        //////////////////////////////////////////////////////

        write_data : coverpoint cov_item.i_w_data_tb{
            option.auto_bin_max = 32;

            bins all_zero = {16'h0000};
            bins all_one  = {16'hFFFF};

            bins others = default;}

        //////////////////////////////////////////////////////
        // Read Data Coverage
        //
        // Tracks data values observed on FIFO reads.
        //////////////////////////////////////////////////////

        read_data : coverpoint cov_item.o_r_data_tb{
            bins all_zero = {16'h0000};
            bins all_one  = {16'hFFFF};

            bins others = default;}

    endgroup

    //////////////////////////////////////////////////////////
    // Constructor
    //
    // Creates the functional coverage model.
    //////////////////////////////////////////////////////////

    function new(
        string name = "subscriber",
        uvm_component parent = null);

        super.new(name, parent);

        fifo_cg = new();

    endfunction

    ///////////////////////////////////////////////////////////////////////
    // Analysis Write Method
    //
    // Receives transactions from the monitor and samples the coverage model.
    /////////////////////////////////////////////////////////////////////////

    function void write(sequence_item t);

        //----------------------------------------------------
        // Update Coverage Transaction
        //----------------------------------------------------

        cov_item = t;

        //----------------------------------------------------
        // Sample Functional Coverage
        //----------------------------------------------------

        fifo_cg.sample();

    endfunction

    /////////////////////////////////////////////////////////////////////
    // Report Phase
    //
    // Displays overall functional coverage at the end of simulation.
    //////////////////////////////////////////////////////////////////

    function void report_phase(uvm_phase phase);

        real coverage_percentage;

        super.report_phase(phase);

        coverage_percentage = fifo_cg.get_coverage();

        `uvm_info(get_type_name(),
                  $sformatf("FUNCTIONAL COVERAGE = %0.2f%%",coverage_percentage),UVM_NONE );

    endfunction

endclass
