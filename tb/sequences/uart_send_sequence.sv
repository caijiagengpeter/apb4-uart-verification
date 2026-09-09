`ifndef UART_SEND_SEQUENCE_SV
`define UART_SEND_SEQUENCE_SV

class uart_send_sequence extends uart_sequence;

    `uvm_object_utils(uart_send_sequence)

    logic [7:0] data;

    function new(string name = "uart_send_sequence");
        super.new(name);
    endfunction

    task body();

    data = 8'h44;// Send 0x44 into TX FIFO

    send_uart(data);

    endtask

endclass

`endif