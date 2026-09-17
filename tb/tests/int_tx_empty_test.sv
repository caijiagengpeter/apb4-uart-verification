`ifndef INT_TX_EMPTY_TEST_SV
`define INT_TX_EMPTY_TEST_SV

class int_tx_empty_test extends tb_base_test;
    `uvm_component_utils(int_tx_empty_test)

    function new(
        string name = "int_tx_empty_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    task run_phase(uvm_phase phase);

        uart_tx_multi_sequence seq2;
        apb_enable             seq_en;
        apb_read_stat          seq_stat;
        apb_tx_enable          tx_en;
        apb_int_tx_empty_enable     int_enable;

        phase.raise_objection(this);

        seq_en   = apb_enable::type_id::create("seq_en");
        seq2     = uart_tx_multi_sequence::type_id::create("seq2");
        seq_stat = apb_read_stat::type_id::create("seq_stat");
        tx_en    = apb_tx_enable::type_id::create("tx_en");
        int_enable = apb_int_tx_empty_enable::type_id::create("int_enable");

        // ------------------------------------------------
        // 1. Idle state: TX_BUSY should be 0
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);
        tx_en.start(env.apb_agt.sequencer);
        int_enable.start(env.apb_agt.sequencer);
        //check point 1

///////////////////////////////////////////////////////////////////////empty

        // ------------------------------------------------
        // 2. Put 2 byte into TX FIFO
        // ------------------------------------------------
        assert(
            seq2.randomize() with {
                num_bytes == 2;
            }
        )
        else begin
            `uvm_fatal(
                "INT_TX_EMPTY_TEST",
                "2-byte sequence randomization failed"
            )
        end

        //check point 2

////////////////////////////////////////////////////////////////////full
        seq2.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 3. Enable TX
        // ------------------------------------------------
        tx_en.start(env.apb_agt.sequencer);

        // Wait until transmission is clearly in progress


        #200us;
////////////////////////////////////////////////////////////////////empty
        //check point 3
        seq_stat.start(env.apb_agt.sequencer);

        #20us
        phase.drop_objection(this);

    endtask

endclass

`endif