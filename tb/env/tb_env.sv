`ifndef TB_ENV_SV
`define TB_ENV_SV

class tb_env extends uvm_env;

    `uvm_component_utils(tb_env)

    apb_agent  apb_agt;
    uart_agent uart_agt;

    function new(
        string name = "tb_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        apb_agt = apb_agent::type_id::create(
            "apb_agt",
            this
        );

        uart_agt = uart_agent::type_id::create(
            "uart_agt",
            this
        );

    endfunction

endclass

`endif