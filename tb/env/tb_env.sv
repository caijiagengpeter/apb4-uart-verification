`ifndef TB_ENV_SV
`define TB_ENV_SV

class tb_env extends uvm_env;

    `uvm_component_utils(tb_env)

    apb_agent  apb_agt;
    uart_agent uart_agt;
    tb_scoreboard scoreboard;
    uart_coverage uart_cov;

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
        uart_cov = uart_coverage::type_id::create("uart_cov",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        apb_agt.monitor.ap.connect(scoreboard.apb_imp);
        uart_agt.tx_monitor.uap.connect(scoreboard.uart_imp_tx);
        uart_agt.rx_monitor.uaprx.connect(scoreboard.uart_imp_rx);
        uart_agt.tx_monitor.uap_start.connect(scoreboard.uart_imp_tx_start);
        uart_agt.rx_monitor.uap_rx_start.connect(scoreboard.uart_imp_rx_start);
        uart_agt.rx_monitor.uaprx.connect(uart_cov.analysis_export);

    endfunction

endclass

`endif