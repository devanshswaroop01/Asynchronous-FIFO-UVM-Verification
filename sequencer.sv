
//-------------------------------------------------------------------------------------------------

// Description:UVM sequencer responsible for forwarding transaction items from sequences to the driver.
//
// Responsibilities:
// - Receives sequence items from active sequences.
// - Arbitrates sequence execution if multiple sequences exist.
// - Provides transactions to the driver through the
//   seq_item_port / seq_item_export connection.
//
// Notes:
// - This project uses a standard UVM sequencer.
// - No custom arbitration or sequencing logic is required.
//
//-------------------------------------------------------------------------------------------------

class sequencer extends uvm_sequencer #(sequence_item);

    //////////////////////////////////////////////////////////
    // Factory Registration
    //////////////////////////////////////////////////////////

    `uvm_component_utils(sequencer)

    //////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////

    function new(
        string name = "sequencer",
        uvm_component parent = null );

        super.new(name, parent);

    endfunction

endclass
