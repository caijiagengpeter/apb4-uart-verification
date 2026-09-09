`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(uart_scoreboard)

    function new(
        string name = "uart_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

endclass

`endif