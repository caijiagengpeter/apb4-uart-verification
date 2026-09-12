`ifndef UART_RX_TEST_SV
`define UART_RX_TEST_SV

class uart_rx_test extends tb_base_test;

    `uvm_component_utils(uart_rx_test)

    function new(
        string name = "uart_rx_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);

        uvm_config_db#(int unsigned)::set(
            this,
            "env.uart_agt.driver",
            "inter_frame_gap_bits",
            0///////////////////////////////////////////////////////// here to change the inter_frame_gap_bits, default is 1, if you want to test the corner case, you can set it to 0 or more
        );

        super.build_phase(phase);

    endfunction

    task run_phase(uvm_phase phase);

        apb_rx_enable         apb_rx_seq;
        uart_rx_multi_sequence rx_seq;
        apb_read_sequence     apb_seq;

        phase.raise_objection(this);

        apb_rx_seq = apb_rx_enable::type_id::create("apb_rx_seq");
        rx_seq     = uart_rx_multi_sequence::type_id::create("rx_seq");

        assert(rx_seq.randomize() with {num_bytes == 4;})
        else
            `uvm_fatal(
                "UART_RX_TEST",
                "Sequence randomization failed"
            )

        // 1. Enable UART RX
        apb_rx_seq.start(env.apb_agt.sequencer);

        #10us;

        // 2. Send all randomized RX bytes
        rx_seq.start(env.uart_agt.sequencer);

        // 3. Wait until DUT has received them
        #1000us;

        // 4. Read RXDATA once for each byte
        for (int i = 0; i < rx_seq.num_bytes; i++) begin

            apb_seq = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_seq.start(env.apb_agt.sequencer);

        end

        #100us;

        phase.drop_objection(this);

    endtask

endclass

`endif