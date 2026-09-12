`ifndef UART_TX_TEST_SV
`define UART_TX_TEST_SV

class uart_tx_test extends tb_base_test;

    `uvm_component_utils(uart_tx_test)

    function new(
        string name = "uart_tx_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);

        uart_tx_multi_sequence seq;

        phase.raise_objection(this);

        seq = uart_tx_multi_sequence::type_id::create("seq");

        assert(seq.randomize())
        else
            `uvm_fatal("UART_TX_TEST", "Sequence randomization failed")

        seq.start(env.apb_agt.sequencer);

        #1000us;

        phase.drop_objection(this);

    endtask

endclass

`endif