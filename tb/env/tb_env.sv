`ifndef TB_ENV_SV
`define TB_ENV_SV

class tb_env extends uvm_env;

    `uvm_component_utils(tb_env)

    apb_agent  apb_agt;
    uart_agent uart_agt;
    tb_scoreboard scoreboard;

    function new(
        string name = "tb_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        apb_agt   = apb_agent::type_id::create("apb_agt", this);
        uart_agt  = uart_agent::type_id::create("uart_agt", this);
        scoreboard = tb_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        apb_agt.monitor.ap.connect(scoreboard.apb_imp);
        uart_agt.tx_monitor.uap.connect(scoreboard.uart_imp_tx);
        uart_agt.rx_monitor.uaprx.connect(scoreboard.uart_imp_rx);
        uart_agt.tx_monitor.uap_start.connect(scoreboard.uart_imp_tx_start);
    endfunction

endclass

`endif