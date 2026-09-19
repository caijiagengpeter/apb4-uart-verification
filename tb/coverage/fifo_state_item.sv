`ifndef FIFO_STATE_ITEM
`define FIFO_STATE_ITEM

class fifo_state_item extends uvm_sequence_item;

    int unsigned tx_count;
    int unsigned rx_count;

    `uvm_object_utils(fifo_state_item)

    function new(string name = "fifo_state_item");
        super.new(name);
    endfunction

endclass

`endif