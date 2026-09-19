`ifndef FIFO_CORNER_ITEM
`define FIFO_CORNER_ITEM

class fifo_corner_item extends uvm_sequence_item;

    bit tx_write_full   = 0;
    bit rx_receive_full = 0;
    bit rx_read_empty   = 0;

    `uvm_object_utils(fifo_corner_item)

    function new(string name = "fifo_corner_item");
        super.new(name);
    endfunction

endclass

`endif