//---------------------------------------------------------------------------------------
// Description: UVM interface for the Asynchronous FIFO DUT.
//
// Purpose:
// - Encapsulates all DUT signals.
// - Provides clocking blocks for race-free stimulus driving.
// - Provides clocking blocks for synchronized monitoring.
// - Defines DUT and Testbench access through modports.
//
// Architecture:
//   Write Domain (w_clk)
//      ├─ Write Driver Clocking Block
//      └─ Write Monitor Clocking Block
//
//   Read Domain (r_clk)
//      ├─ Read Driver Clocking Block
//      └─ Read Monitor Clocking Block
//
// Notes:
// - Separate clocking blocks are used because the FIFO
//   operates with independent write and read clocks.
// - Driver clocking blocks provide synchronized stimulus.
// - Monitor clocking blocks provide stable signal sampling.
//
//-------------------------------------------------------------------------------------

interface fifo_if #(
parameter D_SIZE  = 16,
parameter P_SIZE  = 4,
parameter F_DEPTH = 8 );

//////////////////////////////////////////////////////////
// Clock and Reset Signals
// Independent clock domains used by the asynchronous FIFO.
//////////////////////////////////////////////////////////

logic w_clk;
logic r_clk;

logic i_w_rstn;
logic i_r_rstn;

/////////////////////////////////////////////////////////////////////////
// Write Domain Signals
  
// Driven by the write-side UVM driver and sampled by the DUT on w_clk.
////////////////////////////////////////////////////////////////////////

logic              i_w_inc;
logic [D_SIZE-1:0] i_w_data;

////////////////////////////////////////////////////////////////////////
// Read Domain Signals
//
// Driven by the read-side UVM driver and sampled by the DUT on r_clk.
////////////////////////////////////////////////////////////////////////

logic              i_r_inc;

//////////////////////////////////////////////////////////////////////////////////
// DUT Outputs
//
// Status and data signals observed by the monitor and scoreboard infrastructure.
//////////////////////////////////////////////////////////////////////////////////

logic [D_SIZE-1:0] o_r_data;

logic              o_full;
logic              o_empty;

///////////////////////////////////////////////////////////////////
// Write Driver Clocking Block
//
// Provides race-free stimulus driving in the writeclock domain.
//////////////////////////////////////////////////////////////////

clocking wr_drv_cb @(posedge w_clk);

    default input #1step output #1step;

    // Signals driven toward the DUT
    output i_w_rstn;
    output i_w_inc;
    output i_w_data;

    // Status sampled from the DUT
    input  o_full;

endclocking

/////////////////////////////////////////////////////////////////
// Read Driver Clocking Block
//
// Provides race-free stimulus driving in the read clock domain.
/////////////////////////////////////////////////////////////////

clocking rd_drv_cb @(posedge r_clk);

    default input #1step output #1step;

    // Signals driven toward the DUT
    output i_r_rstn;
    output i_r_inc;

    // Status/data sampled from the DUT
    input  o_empty;
    input  o_r_data;

endclocking

//////////////////////////////////////////////////////////
// Write Monitor Clocking Block
//
// Used by the monitor to capture write-domain activity.
//////////////////////////////////////////////////////////

clocking wr_mon_cb @(posedge w_clk);

    default input #1step output #1step;

    input i_w_rstn;
    input i_w_inc;
    input i_w_data;

    input o_full;

endclocking

//////////////////////////////////////////////////////////
// Read Monitor Clocking Block
//
// Used by the monitor to capture read-domain activity.
//////////////////////////////////////////////////////////

clocking rd_mon_cb @(posedge r_clk);

    default input #1step output #1step;

    input i_r_rstn;
    input i_r_inc;

    input o_empty;
    input o_r_data;

endclocking

//////////////////////////////////////////////////////////
// DUT Modport
//
// Restricts DUT visibility to only the required signals.
//////////////////////////////////////////////////////////

modport DUT (

    input  w_clk,
    input  r_clk,

    input  i_w_rstn,
    input  i_r_rstn,

    input  i_w_inc,
    input  i_w_data,

    input  i_r_inc,

    output o_r_data,
    output o_full,
    output o_empty );

///////////////////////////////////////////////////////////////////////////////
// Testbench Modport
//
// Provides access to clocking blocks used by UVM driver and monitor components.
////////////////////////////////////////////////////////////////////////////////

modport TB (

    clocking wr_drv_cb,
    clocking rd_drv_cb,

    clocking wr_mon_cb,
    clocking rd_mon_cb,

    input w_clk,
    input r_clk );

endinterface

//////////////////////////////////////////////////////////////////////////////////
