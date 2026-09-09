`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

class uart_sequence extends uvm_sequence #(uart_item);

    `uvm_object_utils(uart_sequence)

    function new(string name = "uart_sequence");
        super.new(name);
    endfunction

    task send_uart(input logic [7:0] data);

        uart_item req;

        req = uart_item::type_id::create("req");

        start_item(req);

        req.data = data;

        finish_item(req);

    endtask

    task body();
    ///////////////////
    endtask

endclass

`endif