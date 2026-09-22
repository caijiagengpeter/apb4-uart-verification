`ifndef APB_UNSUPPORTED_ACCESS_TEST_SV
`define APB_UNSUPPORTED_ACCESS_TEST_SV

class apb_unsupported_access_test extends tb_base_test;

    `uvm_component_utils(apb_unsupported_access_test)

    function new(
        string name = "apb_unsupported_access_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);

        apb_unsupported_access_sequence seq;

        phase.raise_objection(this);

        seq = apb_unsupported_access_sequence::type_id::create("seq");

        seq.start(env.apb_agt.sequencer);

        phase.drop_objection(this);

    endtask

endclass

`endif