`ifndef TB_BASE_TEST_SV
`define TB_BASE_TEST_SV

class tb_base_test extends uvm_test;

    `uvm_component_utils(tb_base_test)

    tb_env env;

    function new(string name = "tb_base_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = tb_env::type_id::create("env", this);
    endfunction

endclass

`endif