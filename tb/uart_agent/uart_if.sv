`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if(input logic clk);

    logic rst_n;
    logic tx;
    logic rx;

    modport DRIVER (
        input  clk,
        input  rst_n,
        output rx
    );

    modport MONITOR (
        input clk,
        input rst_n,
        input tx
    );

endinterface

`endif