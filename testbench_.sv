
//-------------------------------------------------------------------------------------------------
// Description:  Top-level testbench module for the Asynchronous FIFO verification environment.
//
// Responsibilities:
// - Generates write and read clocks.
// - Instantiates the FIFO interface.
// - Instantiates the DUT.
// - Binds SystemVerilog assertions.
// - Configures UVM components.
// - Starts UVM test execution.
// - Generates simulation waveforms.
//
// Verification Architecture:
//
//        +---------------------+
//        |      UVM TEST       |
//        +---------------------+
//                   |
//                   v
//        +---------------------+
//        |      fifo_if        |
//        +---------------------+
//                   |
//                   v
//        +---------------------+
//        |     Async_fifo      |
//        +---------------------+
//                   |
//                   v
//        +---------------------+
//        |  fifo_assertions    |
//        +---------------------+
//
// Notes:
// - Independent write/read clocks emulate true
//   asynchronous FIFO operation.
// - Assertions are bound non-intrusively.
// - UVM communicates with DUT through virtual interface.
//
//-----------------------------------------------------------------------------------------------

`include "interface.sv"
`include "my_packages.sv"
`include "assertions.sv"

module top;

    //////////////////////////////////////////////////////////
    // Package Imports
    //
    // Imports UVM library and project package contents.
    //////////////////////////////////////////////////////////

    import uvm_pkg::*;
    import pack1::*;

    /////////////////////////////////////////////////////////////////////
    // Clock Signals
    //
    // Independent clocks used to verify asynchronous FIFO functionality.
    //////////////////////////////////////////////////////////////////////

    bit w_clk;
    bit r_clk;

    //////////////////////////////////////////////////////////
    // Clock Initialization
    //////////////////////////////////////////////////////////

    initial
    begin

        w_clk = 1'b0;
        r_clk = 1'b0;

    end

    //////////////////////////////////////////////////////////
    // Clock Generation
    //
    // Write Clock : 30 ns Period
    // Read Clock  : 40 ns Period
    //////////////////////////////////////////////////////////

    always #15 w_clk = ~w_clk;

    always #20 r_clk = ~r_clk;

    //////////////////////////////////////////////////////////
    // Interface Instance
    //
    // Central communication layer between DUT and UVM.
    //////////////////////////////////////////////////////////

    fifo_if #(
        .D_SIZE (16),
        .F_DEPTH(8),
      .P_SIZE (4) )
    intf1();

    //////////////////////////////////////////////////////////
    // Connect Interface Clocks
    //////////////////////////////////////////////////////////

    assign intf1.w_clk = w_clk;
    assign intf1.r_clk = r_clk;

    //////////////////////////////////////////////////////////
    // DUT Instance
    //
    // Asynchronous FIFO under verification.
    //////////////////////////////////////////////////////////

    Async_fifo #(
        .D_SIZE (16),
        .F_DEPTH(8),
        .P_SIZE (4)  )
    Async_fifo_TEST (

        .w_clk    (intf1.w_clk),
        .i_w_rstn (intf1.i_w_rstn),
        .i_w_inc  (intf1.i_w_inc),

        .r_clk    (intf1.r_clk),
        .i_r_rstn (intf1.i_r_rstn),
        .i_r_inc  (intf1.i_r_inc),

        .i_w_data (intf1.i_w_data),

        .o_r_data (intf1.o_r_data),
        .o_full   (intf1.o_full),
        .o_empty  (intf1.o_empty)  );

    //////////////////////////////////////////////////////////
    // Assertion Binding
    //
    // Non-intrusive binding of SystemVerilog assertions
    // into the DUT hierarchy.
    //////////////////////////////////////////////////////////

    bind Async_fifo fifo_assertions #(

        .D_SIZE (16),
        .F_DEPTH(8),
        .P_SIZE (4) )
    fifo_assertions_inst (

        //----------------------------------------------------
        // Write Domain Signals
        //----------------------------------------------------

        .w_clk       (w_clk),
        .i_w_rstn    (i_w_rstn),
        .i_w_inc     (i_w_inc),

        .o_full      (o_full),

        .w_addr      (u_fifo_wr.w_addr),
        .w_ptr       (u_fifo_wr.w_ptr),
        .gray_w_ptr  (u_fifo_wr.gray_w_ptr),

        .sync_rd_ptr (u_fifo_wr.sync_rd_ptr),

        .i_w_data    (i_w_data),

        //----------------------------------------------------
        // Read Domain Signals
        //----------------------------------------------------

        .r_clk       (r_clk),
        .i_r_rstn    (i_r_rstn),
        .i_r_inc     (i_r_inc),

        .o_empty     (o_empty),

        .r_addr      (u_fifo_rd.rd_addr),
        .rd_ptr      (u_fifo_rd.rd_ptr),
        .gray_rd_ptr (u_fifo_rd.gray_rd_ptr),

        .sync_wr_ptr (u_fifo_rd.sync_wr_ptr),

        .o_r_data    (o_r_data),

        //----------------------------------------------------
        // FIFO Memory
        //----------------------------------------------------

        .FIFO_MEM    (u_fifo_mem.FIFO_MEM) );

    //////////////////////////////////////////////////////////
    // UVM Configuration
    //
    // Places the virtual interface into the configuration
    // database and launches the UVM test.
    //////////////////////////////////////////////////////////

    initial
    begin

        uvm_config_db #(virtual fifo_if)::set(
            null,"*","my_vif",intf1);

        run_test("test");

    end

    //////////////////////////////////////////////////////////
    // Waveform Generation
    //
    // Enables post-simulation debug and analysis.
    //////////////////////////////////////////////////////////

    initial begin

        $dumpfile("dump.vcd");

        $dumpvars(0, top);

    end

endmodule
