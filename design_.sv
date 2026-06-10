//------------------------------------------------------------------------------------
// Description: Multi-stage bit synchronizer used for clock domain crossing (CDC).
//
// Purpose:
// Synchronizes a Gray-coded pointer bus from one clock domain into another
// clock domain using a configurable number of flip-flop stages.
//
// Notes:
// - Typically instantiated with NUM_STAGES = 2.
// - Used for write-pointer to read-domain synchronization.
// - Used for read-pointer to write-domain synchronization.
// - Gray coding ensures only one bit changes per transition, reducing CDC risk.
//
//----------------------------------------------------------------------------------------

module BIT_SYNC #(
parameter NUM_STAGES = 2,
parameter BUS_WIDTH  = 1 )(
input  wire                  CLK,       // Destination clock domain
input  wire                  RST,       // Active-low asynchronous reset
input  wire [BUS_WIDTH-1:0]  ASYNC,     // Asynchronous input bus
output wire [BUS_WIDTH-1:0]  SYNC );       // Synchronized output bus



//////////////////////////////////////////////////////////
// Synchronizer Registers
// Each bit is synchronized independently through a
// configurable shift-register chain.
//////////////////////////////////////////////////////////

reg [NUM_STAGES-1:0] sync_reg [BUS_WIDTH-1:0];

integer i;

//////////////////////////////////////////////////////////
// Multi-Stage Synchronization Logic
// On every destination clock edge:
// 1. Sample asynchronous input.
// 2. Shift data through synchronizer stages.
// 3. Reduce metastability propagation probability.
//////////////////////////////////////////////////////////

always @(posedge CLK or negedge RST)
begin
    if(!RST)
    begin
        for(i = 0; i < BUS_WIDTH; i = i + 1)
        begin
            sync_reg[i] <= 'b0;
        end
    end
    else
    begin
        for(i = 0; i < BUS_WIDTH; i = i + 1)
        begin
            sync_reg[i] <=
            {
                sync_reg[i][NUM_STAGES-2:0],
                ASYNC[i]
            };
        end
    end
end

//////////////////////////////////////////////////////////
// Output Assignment
// The synchronized value is taken from the final stage
// of each synchronizer chain.
//////////////////////////////////////////////////////////

genvar j;

generate

    for(j = 0; j < BUS_WIDTH; j = j + 1)
    begin : SYNC_ASSIGN

        assign SYNC[j] =
               sync_reg[j][NUM_STAGES-1];

    end
endgenerate
endmodule

//----------------------------------------------------------------------------
// Description: Storage element of the Asynchronous FIFO.
//
// Responsibilities:
// - Stores incoming write data.
// - Provides data corresponding to the current read address.
// - Prevents writes when the FIFO is FULL.
//
// Notes:
// - Memory depth is controlled by F_DEPTH.
// - Write operation is synchronous to w_clk.
// - Read operation is combinational.
// - Read and write pointers are generated externally by the
//   write-side and read-side control logic.
//
//---------------------------------------------------------------------------------

module fifo_mem #(
parameter D_SIZE  = 16,
parameter F_DEPTH = 8,
parameter P_SIZE  = 4 )(
input                       w_clk,
input                       w_rstn,
input                       w_full,
input                       w_inc,


input      [P_SIZE-2:0]     w_addr,
input      [P_SIZE-2:0]     r_addr,

input      [D_SIZE-1:0]     w_data,

  output     [D_SIZE-1:0]     r_data );

////////////////////////////////////////////////////////////
// FIFO Memory Array
// Stores FIFO payload data.
// Address width is derived from the FIFO pointer size.
//////////////////////////////////////////////////////////

reg [D_SIZE-1:0] FIFO_MEM [F_DEPTH-1:0];

integer i;

//////////////////////////////////////////////////////////
// Write Logic
// Data is written only when:
// 1. Write increment request is asserted.
// 2. FIFO is not FULL.
//
// During reset, the entire memory is cleared to provide
// deterministic simulation behavior.
//////////////////////////////////////////////////////////

always @(posedge w_clk or negedge w_rstn)
begin

    if(!w_rstn)
    begin

        for(i = 0; i < F_DEPTH; i = i + 1)
        begin
            FIFO_MEM[i] <= {D_SIZE{1'b0}};
        end

    end
    else if(w_inc && !w_full)
    begin

        FIFO_MEM[w_addr] <= w_data;

    end

end

//////////////////////////////////////////////////////////
// Read Logic
// The current read address directly selects the output
// data from the FIFO memory array.
//
// This implementation uses combinational read access.
//////////////////////////////////////////////////////////

assign r_data = FIFO_MEM[r_addr];

endmodule

//------------------------------------------------------------------------------
// Description: Read-side control logic for the Asynchronous FIFO.
//
// Responsibilities:
// - Maintains binary read pointer.
// - Generates Gray-coded read pointer.
// - Generates FIFO EMPTY status.
// - Provides memory read address.
//
// Clock Domain: r_clk
// Notes:
// - Read pointer advances only on a valid read operation.
// - Gray-coded pointer is synchronized into the write domain
//   for FULL flag generation.
// - EMPTY is asserted when the synchronized write pointer
//   matches the current Gray-coded read pointer.
//
//-------------------------------------------------------------------------------------
module fifo_rd #(
parameter P_SIZE = 4 )(
input  wire                  r_clk,
input  wire                  r_rstn,
input  wire                  r_inc,

input  wire [P_SIZE-1:0]     sync_wr_ptr,

output wire [P_SIZE-2:0]     rd_addr,
output wire                  empty,

output reg  [P_SIZE-1:0]     rd_ptr,
output reg  [P_SIZE-1:0]     gray_rd_ptr );


//////////////////////////////////////////////////////////
// Next-State Signals
// Used to compute the next binary and Gray-coded read
// pointers before updating the registers.
//////////////////////////////////////////////////////////

reg [P_SIZE-1:0] rd_ptr_next;
reg [P_SIZE-1:0] gray_rd_ptr_next;

//////////////////////////////////////////////////////////
// Next Pointer Logic
// The read pointer advances only when:
// 1. Read request is asserted.
// 2. FIFO is not EMPTY.
//
// Gray code is generated from the next binary pointer.
//////////////////////////////////////////////////////////

always @(*)
begin

    // Hold current state by default
    rd_ptr_next      = rd_ptr;
    gray_rd_ptr_next = gray_rd_ptr;

    // Valid read operation
    if(r_inc && !empty)
    begin

        rd_ptr_next = rd_ptr + 1'b1;

        gray_rd_ptr_next = (rd_ptr_next >> 1) ^ rd_ptr_next;

    end

end

//////////////////////////////////////////////////////////
// Binary and Gray Pointer Registers
// Registers are updated in the read clock domain.
//////////////////////////////////////////////////////////

always @(posedge r_clk or negedge r_rstn)
begin

    if(!r_rstn)
    begin

        rd_ptr      <= {P_SIZE{1'b0}};
        gray_rd_ptr <= {P_SIZE{1'b0}};

    end
    else
    begin

        rd_ptr      <= rd_ptr_next;
        gray_rd_ptr <= gray_rd_ptr_next;

    end

end

//////////////////////////////////////////////////////////
// Read Address
// The lower pointer bits are used as the memory address.
// The extra MSB is reserved for FIFO status generation.
//////////////////////////////////////////////////////////

assign rd_addr = rd_ptr[P_SIZE-2:0];

//////////////////////////////////////////////////////////
// Empty Detection
// FIFO is EMPTY when the synchronized Gray-coded write
// pointer matches the current Gray-coded read pointer.
//////////////////////////////////////////////////////////

assign empty = (sync_wr_ptr == gray_rd_ptr);


endmodule

//------------------------------------------------------------------------------
// Description:  Write-side control logic for the Asynchronous FIFO.
//
// Responsibilities:
// - Maintains binary write pointer.
// - Generates Gray-coded write pointer.
// - Generates FIFO FULL status.
// - Provides memory write address.
//
// Clock Domain:  w_clk
// Notes:
// - Write pointer advances only on a valid write operation.
// - Gray-coded pointer is synchronized into the read domain
//   for EMPTY flag generation.
// - FULL detection follows the standard Gray-pointer method
//   used in CDC-safe asynchronous FIFOs.
//
//-------------------------------------------------------------------------------

module fifo_wr #(
parameter P_SIZE = 4 )(
input  wire                  w_clk,
input  wire                  w_rstn,
input  wire                  w_inc,

input  wire [P_SIZE-1:0]     sync_rd_ptr,

output wire [P_SIZE-2:0]     w_addr,

output reg  [P_SIZE-1:0]     w_ptr,
output reg  [P_SIZE-1:0]     gray_w_ptr,

output wire                  full );

//////////////////////////////////////////////////////////
// Next-State Candidates
// Used for FULL detection before updating the actual
// write pointer registers.
//////////////////////////////////////////////////////////

wire [P_SIZE-1:0] w_ptr_succ;
wire [P_SIZE-1:0] gray_w_ptr_succ;

//////////////////////////////////////////////////////////
// Next Binary Write Pointer
// Candidate pointer value if a write operation occurs.
//////////////////////////////////////////////////////////

assign w_ptr_succ = w_ptr + 1'b1;

//////////////////////////////////////////////////////////
// Next Gray Write Pointer
// Gray code is generated from the candidate binary
// pointer to support CDC-safe synchronization.
//////////////////////////////////////////////////////////

assign gray_w_ptr_succ = (w_ptr_succ >> 1) ^ w_ptr_succ;

//////////////////////////////////////////////////////////////////////////////
// Full Detection
// FIFO becomes FULL when the next Gray-coded write pointer 
// matches the synchronized Gray-coded read pointer with the two MSBs inverted.
//
// This is the standard CDC-safe Async FIFO full detection technique.
////////////////////////////////////////////////////////////////////////////////

  assign full =  ( gray_w_ptr_succ == { ~sync_rd_ptr[P_SIZE-1:P_SIZE-2], sync_rd_ptr[P_SIZE-3:0]});

//////////////////////////////////////////////////////////
// Write Pointer Registers
//
// Update pointers only on a successful write operation.
// Pointer values remain unchanged when the FIFO is FULL.
//////////////////////////////////////////////////////////

always @(posedge w_clk or negedge w_rstn)
begin

    if(!w_rstn)
    begin

        w_ptr      <= {P_SIZE{1'b0}};
        gray_w_ptr <= {P_SIZE{1'b0}};

    end
    else if(w_inc && !full)
    begin

        w_ptr      <= w_ptr_succ;
        gray_w_ptr <= gray_w_ptr_succ;

    end

end

//////////////////////////////////////////////////////////
// Write Address
// Lower pointer bits are used as the memory write address.
//  The additional MSB is reserved for FIFO status generation.
//////////////////////////////////////////////////////////

assign w_addr = w_ptr[P_SIZE-2:0];

endmodule

//-------------------------------------------------------------------------
// Description: CDC-safe Asynchronous FIFO using Gray-coded pointers and
// multi-stage synchronizers.
//
// Architecture:
//   +------------+      +------------+      +------------+
//   |  fifo_wr   | ---> |  fifo_mem  | ---> |  fifo_rd   |
//   +------------+      +------------+      +------------+
//
// Pointer Synchronization:
//   Gray Write Pointer --> Read Clock Domain
//   Gray Read Pointer  --> Write Clock Domain
//
// Features:
// - Independent read and write clocks
// - Full flag generation
// - Empty flag generation
// - Gray-code CDC synchronization
// - Parameterized data width and FIFO depth
//
//---------------------------------------------------------------------------

module Async_fifo #(
parameter D_SIZE  = 16,
parameter F_DEPTH = 8,
parameter P_SIZE  = 4 )(
input                    w_clk,
input                    i_w_rstn,
input                    i_w_inc,

input                    r_clk,
input                    i_r_rstn,
input                    i_r_inc,

input  [D_SIZE-1:0]      i_w_data,

output [D_SIZE-1:0]      o_r_data,
output                   o_full,
output                   o_empty );
 
////////////////////////////////////////////////////////////////////////////
// Internal Signals
//
// Address signals: Used for FIFO memory access.
//
// Pointer signals:
//   Binary and Gray-coded pointers generated by the
//   write-side and read-side control logic.
//
// Synchronization signals: Gray-coded pointers synchronized across clock domains.
////////////////////////////////////////////////////////////////////////////////

wire [P_SIZE-2:0] w_addr;
wire [P_SIZE-2:0] r_addr;

wire [P_SIZE-1:0] w_ptr;
wire [P_SIZE-1:0] rd_ptr;

wire [P_SIZE-1:0] gray_w_ptr;
wire [P_SIZE-1:0] gray_rd_ptr;

wire [P_SIZE-1:0] w2r_ptr;
wire [P_SIZE-1:0] r2w_ptr;

//////////////////////////////////////////////////////////
// FIFO Memory
// Stores payload data written by the write domain and
// provides data to the read domain.
//////////////////////////////////////////////////////////

fifo_mem #(
    .D_SIZE (D_SIZE),
    .F_DEPTH(F_DEPTH),
    .P_SIZE (P_SIZE) )
u_fifo_mem (

    .w_clk  (w_clk),
    .w_rstn (i_w_rstn),

    .w_full (o_full),
    .w_inc  (i_w_inc),

    .w_addr (w_addr),
    .r_addr (r_addr),

    .w_data (i_w_data),
  .r_data (o_r_data) );

//////////////////////////////////////////////////////////
// Read-Side Control Logic
//
// Generates:
// - Binary read pointer
// - Gray-coded read pointer
// - Empty flag
// - Memory read address
//////////////////////////////////////////////////////////

fifo_rd #(
    .P_SIZE(P_SIZE))
u_fifo_rd (

    .r_clk       (r_clk),
    .r_rstn      (i_r_rstn),
    .r_inc       (i_r_inc),

    .sync_wr_ptr (w2r_ptr),

    .rd_addr     (r_addr),

    .empty       (o_empty),

    .rd_ptr      (rd_ptr),
    .gray_rd_ptr (gray_rd_ptr));

//////////////////////////////////////////////////////////
// Write-Side Control Logic
//
// Generates:
// - Binary write pointer
// - Gray-coded write pointer
// - Full flag
// - Memory write address
//////////////////////////////////////////////////////////

fifo_wr #(
    .P_SIZE(P_SIZE))
u_fifo_wr (

    .w_clk       (w_clk),
    .w_rstn      (i_w_rstn),
    .w_inc       (i_w_inc),

    .sync_rd_ptr (r2w_ptr),

    .w_addr      (w_addr),

    .w_ptr       (w_ptr),
    .gray_w_ptr  (gray_w_ptr),

    .full        (o_full));

//////////////////////////////////////////////////////////
// Write-to-Read Pointer Synchronization
//
// Synchronizes the Gray-coded write pointer into the
// read clock domain for EMPTY flag generation.
//////////////////////////////////////////////////////////

BIT_SYNC #(
    .NUM_STAGES(2),
    .BUS_WIDTH(P_SIZE))
u_w2r_sync (

    .CLK   (r_clk),
    .RST   (i_r_rstn),

    .ASYNC (gray_w_ptr),
    .SYNC  (w2r_ptr));

//////////////////////////////////////////////////////////
// Read-to-Write Pointer Synchronization
//
// Synchronizes the Gray-coded read pointer into the
// write clock domain for FULL flag generation.
//////////////////////////////////////////////////////////

BIT_SYNC #(
    .NUM_STAGES(2),
    .BUS_WIDTH(P_SIZE))
u_r2w_sync (

    .CLK   (w_clk),
    .RST   (i_w_rstn),

    .ASYNC (gray_rd_ptr),
    .SYNC  (r2w_ptr));

endmodule
