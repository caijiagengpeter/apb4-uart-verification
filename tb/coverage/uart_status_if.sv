interface uart_status_if(
    input logic clk,
    input logic rst_n
);

    logic stat_overrun_err;

    logic irq_tx_empty;
    logic irq_rx_full;

    modport MONITOR(
        input clk,
        input rst_n,
        input stat_overrun_err,
        input irq_tx_empty,
        input irq_rx_full
    );

endinterface