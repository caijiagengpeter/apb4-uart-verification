`ifndef UART_TX_PARITY_TEST_SV
`define UART_TX_PARITY_TEST_SV

class uart_tx_parity_test extends tb_base_test;

    `uvm_component_utils(uart_tx_parity_test)

    function new(
        string name = "uart_tx_parity_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    task run_phase(uvm_phase phase);

        uart_tx_multi_sequence seq1;
        apb_enable             seq_en;
        apb_tx_enable          tx_en;
        apb_read_stat          seq_stat;

        phase.raise_objection(this);

        `uvm_info(
            "UART_TX_PARITY_TEST",
            "Starting TX parity-enabled transmission test",
            UVM_LOW
        )

        // ------------------------------------------------
        // Create sequences
        // ------------------------------------------------
        seq_en   = apb_enable::type_id::create("seq_en");
        tx_en    = apb_tx_enable::type_id::create("tx_en");
        seq1     = uart_tx_multi_sequence::type_id::create("seq1");
        seq_stat = apb_read_stat::type_id::create("seq_stat");


        // ------------------------------------------------
        // 1. UART enable, TX disabled first
        // CTRL = 0x01
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 2. Put one byte into TX FIFO
        // ------------------------------------------------
        assert(
            seq1.randomize() with {
                num_bytes == 1;
            }
        )
        else
            `uvm_fatal(
                "UART_TX_PARITY_TEST",
                "1-byte TX sequence randomization failed"
            )

        seq1.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 3. Enable TX
        // CTRL = 0x03
        // ------------------------------------------------
        tx_en.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 4. Wait for parity-enabled UART frame to complete
        //
        // PARITY_ENABLE is NOT controlled dynamically here.
        // It comes from tb_top compile-time configuration:
        //
        // +define+UART_PARITY_EVEN
        // or
        // +define+UART_PARITY_ODD
        // ------------------------------------------------
        #500us;


        // ------------------------------------------------
        // 5. Optional STAT read
        // ------------------------------------------------
        seq_stat.start(env.apb_agt.sequencer);


        `uvm_info(
            "UART_TX_PARITY_TEST",
            "TX parity-enabled transmission test completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif