`ifndef APB_TEST_SV
`define APB_TEST_SV

class apb_test extends tb_base_test;

    `uvm_component_utils(apb_test)

    function new(
        string name = "apb_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    task run_phase(uvm_phase phase);

        uart_tx_smoke_sequence seq;

        phase.raise_objection(this);

        seq = uart_tx_smoke_sequence::type_id::create("seq");

        seq.start(env.apb_agt.sequencer);

        #120us;

        phase.drop_objection(this);

    endtask

endclass

`endif