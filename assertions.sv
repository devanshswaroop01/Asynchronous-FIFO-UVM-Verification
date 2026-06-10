//-------------------------------------------------------------------------------------

// Description:
// SystemVerilog Assertion (SVA) module used to verify the
// functional correctness of the Asynchronous FIFO.
//
// Verification Areas:
//   • Reset behavior
//   • Pointer increment logic
//   • Gray-code generation
//   • Empty flag generation
//   • Full flag generation
//   • Overflow protection
//   • Underflow protection
//
// Notes:
// - Bound non-intrusively to the DUT.
// - Operates as a passive verification component.
// - Complements scoreboard and functional coverage.
// - Provides cycle-accurate protocol checking.
//
//-------------------------------------------------------------------------------------

module fifo_assertions #(

    parameter D_SIZE  = 16,
    parameter F_DEPTH = 8,
    parameter P_SIZE  = 4)(
    //////////////////////////////////////////////////////////
    // Write Domain Signals
    //////////////////////////////////////////////////////////

    input                     w_clk,
    input                     i_w_rstn,
    input                     i_w_inc,

    input                     o_full,

    input [P_SIZE-2:0]        w_addr,

    input [P_SIZE-1:0]        w_ptr,
    input [P_SIZE-1:0]        gray_w_ptr,

    input [P_SIZE-1:0]        sync_rd_ptr,

    input [D_SIZE-1:0]        i_w_data,

    //////////////////////////////////////////////////////////
    // Read Domain Signals
    //////////////////////////////////////////////////////////

    input                     r_clk,
    input                     i_r_rstn,
    input                     i_r_inc,

    input                     o_empty,

    input [P_SIZE-2:0]        r_addr,

    input [P_SIZE-1:0]        rd_ptr,
    input [P_SIZE-1:0]        gray_rd_ptr,

    input [P_SIZE-1:0]        sync_wr_ptr,

    input [D_SIZE-1:0]        o_r_data,

    //////////////////////////////////////////////////////////
    // FIFO Memory
    //////////////////////////////////////////////////////////

    input [D_SIZE-1:0]        FIFO_MEM [F_DEPTH-1:0]);

    //////////////////////////////////////////////////////////
    // Helper Function
    //
    // Converts binary value into Gray-code equivalent.
    //////////////////////////////////////////////////////////

    function automatic [P_SIZE-1:0]bin_to_gray(input [P_SIZE-1:0] bin);

        bin_to_gray = (bin >> 1) ^ bin;

    endfunction

    //////////////////////////////////////////////////////////
    // Expected Next-State Logic
    //
    // Used by pointer and flag assertions.
    //////////////////////////////////////////////////////////

    wire [P_SIZE-1:0] next_w_ptr;
    wire [P_SIZE-1:0] next_rd_ptr;

    wire [P_SIZE-1:0] next_gray_w_ptr;
    wire [P_SIZE-1:0] next_gray_rd_ptr;

    assign next_w_ptr =w_ptr + ((i_w_inc && !o_full) ? 1'b1 : 1'b0);

    assign next_rd_ptr =rd_ptr + ((i_r_inc && !o_empty) ? 1'b1 : 1'b0);

    assign next_gray_w_ptr =bin_to_gray(next_w_ptr);

    assign next_gray_rd_ptr =bin_to_gray(next_rd_ptr);

    //////////////////////////////////////////////////////////
    // WRITE POINTER ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // Valid write increments write pointer by one.
    //--------------------------------------------------------

    property p_write_ptr_increment;

        @(posedge w_clk)
        disable iff(!i_w_rstn)

      (i_w_inc && !o_full) |=> (w_ptr == $past(w_ptr) + 1);

    endproperty

    a_write_ptr_increment : assert property(p_write_ptr_increment)
    else
    $error("WRITE POINTER FAILED TO INCREMENT");

    //////////////////////////////////////////////////////////
    // READ POINTER ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // Valid read increments read pointer by one.
    //--------------------------------------------------------

    property p_read_ptr_increment;

        @(posedge r_clk)
        disable iff(!i_r_rstn)

        (i_r_inc && !o_empty)|=> (rd_ptr == $past(rd_ptr) + 1);

    endproperty

    a_read_ptr_increment :assert property(p_read_ptr_increment)
    else
    $error("READ POINTER FAILED TO INCREMENT");

    //////////////////////////////////////////////////////////
    // GRAY POINTER ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // Write Gray pointer must match binary conversion.
    //--------------------------------------------------------

    property p_gray_write_pointer;

        @(posedge w_clk)
        disable iff(!i_w_rstn)

        gray_w_ptr == bin_to_gray(w_ptr);

    endproperty

    a_gray_write_pointer :
    assert property(p_gray_write_pointer)
    else
    $error("WRITE GRAY POINTER ERROR");

    //--------------------------------------------------------
    // Read Gray pointer must match binary conversion.
    //--------------------------------------------------------

    property p_gray_read_pointer;

        @(posedge r_clk)
        disable iff(!i_r_rstn)

        gray_rd_ptr == bin_to_gray(rd_ptr);

    endproperty

    a_gray_read_pointer :assert property(p_gray_read_pointer)
    else
    $error("READ GRAY POINTER ERROR");

    //////////////////////////////////////////////////////////
    // EMPTY FLAG ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // FIFO is empty when synchronized write pointer
    // equals next read Gray pointer.
    //--------------------------------------------------------

    property p_empty_flag;

        @(posedge r_clk)
        disable iff(!i_r_rstn)

        (sync_wr_ptr == next_gray_rd_ptr)|-> o_empty;

    endproperty

    a_empty_flag :assert property(p_empty_flag)
    else
    $error("EMPTY FLAG GENERATION ERROR");

    //////////////////////////////////////////////////////////
    // FULL FLAG ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // FIFO full detection logic validation.
    //--------------------------------------------------------

    property p_full_flag;

        @(posedge w_clk)
        disable iff(!i_w_rstn)

        (next_gray_w_ptr =={~sync_rd_ptr[P_SIZE-1:P_SIZE-2],sync_rd_ptr[P_SIZE-3:0]})|-> o_full;

    endproperty

    a_full_flag :assert property(p_full_flag)
    else
    $error("FULL FLAG GENERATION ERROR");

    //////////////////////////////////////////////////////////
    // RESET ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // Write-domain reset initializes pointers.
    //--------------------------------------------------------

    property p_write_reset;

        @(posedge w_clk)

        !i_w_rstn |=> (w_ptr == 0 &&gray_w_ptr == 0);

    endproperty

    a_write_reset :assert property(p_write_reset)
    else
    $error("WRITE RESET FAILURE");

    //--------------------------------------------------------
    // Read-domain reset initializes pointers.
    //--------------------------------------------------------

    property p_read_reset;

        @(posedge r_clk)

      !i_r_rstn |=> (rd_ptr == 0 &&  gray_rd_ptr == 0);

    endproperty

    a_read_reset : assert property(p_read_reset)
    else
    $error("READ RESET FAILURE");

    //////////////////////////////////////////////////////////
    // PROTECTION ASSERTIONS
    //////////////////////////////////////////////////////////

    //--------------------------------------------------------
    // No write pointer movement while FIFO is FULL.
    //--------------------------------------------------------

    property p_no_write_when_full;

        @(posedge w_clk)
        disable iff(!i_w_rstn)

      (o_full && i_w_inc) |=> $stable(w_ptr);

    endproperty

    a_no_write_when_full : assert property(p_no_write_when_full)
    else
    $error("WRITE OCCURRED WHILE FIFO FULL");

    //--------------------------------------------------------
    // No read pointer movement while FIFO is EMPTY.
    //--------------------------------------------------------

    property p_no_read_when_empty;

        @(posedge r_clk)
        disable iff(!i_r_rstn)

      (o_empty && i_r_inc) |=> $stable(rd_ptr);

    endproperty

    a_no_read_when_empty :
    assert property(p_no_read_when_empty)
    else
    $error("READ OCCURRED WHILE FIFO EMPTY");

endmodule
