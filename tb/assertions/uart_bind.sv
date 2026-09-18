`ifndef UART_BIND_SV
`define UART_BIND_SV

bind uart_controller uart_assertions uart_assertions_inst (

    .pclk_i              (pclk_i),
    .presetn_i           (presetn_i),

    // RX overrun
    .uart_rx_done        (uart_rx_done),
    .rx_fifo_full        (rx_fifo_full),
    .stat_overrun_err    (stat_overrun_err),

    // RX frame error
    .uart_rx_frame_err   (uart_rx_frame_err),
    .stat_frame_err      (stat_frame_err),

    // RX parity error
    .uart_rx_parity_err  (uart_rx_parity_err),
    .stat_parity_err     (stat_parity_err),

    // TX empty IRQ
    .tx_fifo_empty       (tx_fifo_empty),
    .ctrl_tx_enable      (ctrl_tx_enable),
    .int_tx_empty_en     (int_tx_empty_en),
    .irq_tx_empty_o      (irq_tx_empty_o),
    
    // RX full IRQ
    .ctrl_rx_enable     (ctrl_rx_enable),
    .int_rx_full_en     (int_rx_full_en),
    .irq_rx_full_o      (irq_rx_full_o)

);

`endif