`ifndef APB_REGISTER_ACCESS_TEST_SV
`define APB_REGISTER_ACCESS_TEST_SV

class apb_register_access_test extends tb_base_test;

    `uvm_component_utils(apb_register_access_test)

    function new(
        string name = "apb_register_access_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);

        apb_register_access_sequence seq;

        phase.raise_objection(this);

        seq = apb_register_access_sequence::type_id::create(
            "seq"
        );

        seq.start(env.apb_agt.sequencer);

        #10us;

        phase.drop_objection(this);

    endtask

endclass

`endif