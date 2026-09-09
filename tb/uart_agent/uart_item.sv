`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

    rand logic [7:0] data;

    rand logic       parity_en;
    rand logic       parity_odd;

    `uvm_object_utils(uart_item)

    function new(string name = "uart_item");
        super.new(name);
    endfunction

endclass

`endif