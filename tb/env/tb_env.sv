`ifndef TB_ENV_SV
`define TB_ENV_SV

class tb_env extends uvm_env;

    `uvm_component_utils(tb_env)

    apb_agent      apb_agt;
    uart_agent     uart_agt;
    tb_scoreboard  scoreboard;
    uart_coverage  uart_cov;
    uart_status_monitor status_mon;

    function new(
        string name = "tb_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        apb_agt    = apb_agent::type_id::create("apb_agt", this);
        uart_agt   = uart_agent::type_id::create("uart_agt", this);
        scoreboard = tb_scoreboard::type_id::create("scoreboard", this);
        uart_cov   = uart_coverage::type_id::create("uart_cov", this);
        status_mon = uart_status_monitor::type_id::create("status_mon",this);


    endfunction


    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        apb_agt.monitor.ap.connect(scoreboard.apb_imp);

        uart_agt.tx_monitor.uap.connect(
            scoreboard.uart_imp_tx
        );

        uart_agt.rx_monitor.uaprx.connect(
            scoreboard.uart_imp_rx
        );

        uart_agt.tx_monitor.uap_start.connect(
            scoreboard.uart_imp_tx_start
        );

        uart_agt.rx_monitor.uap_rx_start.connect(
            scoreboard.uart_imp_rx_start
        );

        // Normal RX transactions -> coverage
        uart_agt.rx_monitor.uaprx.connect(
            uart_cov.analysis_export
        );

        // Frame-error events -> coverage
        uart_agt.rx_monitor.uap_frame_error.connect(
            uart_cov.frame_error_imp
        );

        // Overrun-error events -> coverage
        status_mon.ap.connect(
            uart_cov.overrun_imp
        );

        // FIFO coverage Scoreboard -> coverage
        scoreboard.fifo_state_ap.connect(
            uart_cov.fifo_state_imp
        );

        // FIFO Conner case Scoreboard -> coverage
        scoreboard.fifo_corner_ap.connect(
            uart_cov.fifo_corner_imp
        );

        // IRQ event -> coverage
        status_mon.ap.connect(
            uart_cov.irq_imp
        );

    endfunction

endclass

`endif