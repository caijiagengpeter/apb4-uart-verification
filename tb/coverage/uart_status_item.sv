`ifndef UART_STATUS_ITEM
`define UART_STATUS_ITEM

class uart_status_item extends uvm_sequence_item;

    logic overrun_error;

    logic tx_empty_irq;
    logic rx_full_irq;

    `uvm_object_utils(uart_status_item)

    function new(string name = "uart_status_item");
        super.new(name);

        overrun_error = 1'b0;
        tx_empty_irq  = 1'b0;
        rx_full_irq   = 1'b0;
    endfunction

endclass

`endif