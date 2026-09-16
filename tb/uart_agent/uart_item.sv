`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

    rand logic [7:0] data;

    rand logic parity_en;
    rand logic parity_odd;

    rand bit inject_frame_error;
    rand bit inject_parity_error;

    logic parity_bit;   // monitor实际采到的parity bit

    constraint c_default_frame_error {
        soft inject_frame_error == 1'b0;
    }

    constraint c_default_parity_error {
        soft inject_parity_error == 1'b0;
    }

    constraint c_default_parity {
        soft parity_en  == 1'b0;
        soft parity_odd == 1'b0;
    }


    `uvm_object_utils(uart_item)

    function new(string name = "uart_item");
        super.new(name);
    endfunction

endclass

`endif
