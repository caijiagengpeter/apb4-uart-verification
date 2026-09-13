`ifndef UART_RX_GAP1_TEST_SV
`define UART_RX_GAP1_TEST_SV

class uart_rx_gap1_test extends uart_rx_test;

    `uvm_component_utils(uart_rx_gap1_test)

    function new(
        string name = "uart_rx_gap1_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);

    rx_num_bytes = 4;

        uvm_config_db#(int unsigned)::set(
            this,
            "env.uart_agt.driver",
            "inter_frame_gap_bits",
            1///// here to change the inter_frame_gap_bits, default is 1, if you want to test the corner case, you can set it to 0 or more
        );

        super.build_phase(phase);

    endfunction



endclass

`endif