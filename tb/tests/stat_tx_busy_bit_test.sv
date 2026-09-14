`ifndef STAT_TX_BUSY_BIT_TEST_SV
`define STAT_TX_BUSY_BIT_TEST_SV

class stat_tx_busy_bit_test extends tb_base_test;

    `uvm_component_utils(stat_tx_busy_bit_test)

    function new(
        string name = "stat_tx_busy_bit_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    task run_phase(uvm_phase phase);

        uart_tx_multi_sequence seq1;
        apb_enable             seq_en;
        apb_read_stat          seq_stat;
        apb_tx_enable          tx_en;

        phase.raise_objection(this);

        seq_en   = apb_enable::type_id::create("seq_en");
        seq1     = uart_tx_multi_sequence::type_id::create("seq1");
        seq_stat = apb_read_stat::type_id::create("seq_stat");
        tx_en    = apb_tx_enable::type_id::create("tx_en");


        // ------------------------------------------------
        // 1. Idle state: TX_BUSY should be 0
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);

        seq_stat.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 2. Put one byte into TX FIFO
        // ------------------------------------------------
        assert(
            seq1.randomize() with {
                num_bytes == 1;
            }
        )
        else begin
            `uvm_fatal(
                "STAT_TX_BUSY_BIT_TEST",
                "1-byte sequence randomization failed"
            )
        end

        seq1.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 3. Enable TX
        // ------------------------------------------------
        tx_en.start(env.apb_agt.sequencer);

        // Wait until transmission is clearly in progress
        #20us;

        seq_stat.start(env.apb_agt.sequencer);

        #100us;

        seq_stat.start(env.apb_agt.sequencer);

        #20us
        phase.drop_objection(this);

    endtask

endclass

`endif