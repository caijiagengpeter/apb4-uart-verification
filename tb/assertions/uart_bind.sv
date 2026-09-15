`ifndef UART_BIND_SV
`define UART_BIND_SV

bind uart_controller uart_assertions uart_assertions_inst (
    .pclk_i             (pclk_i),
    .presetn_i          (presetn_i),
    .uart_rx_done       (uart_rx_done),
    .rx_fifo_full       (rx_fifo_full),
    .stat_overrun_err   (stat_overrun_err),
    .uart_rx_frame_err  (uart_rx_frame_err),
    .stat_frame_err     (stat_frame_err)
);

`endif