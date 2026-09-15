module tb_top;

    import uvm_pkg::*;
    import apb_pkg::*;

    `include "uvm_macros.svh"

    // ============================================================
    // Clock
    // ============================================================

    logic pclk;


    // ============================================================
    // IRQ
    // ============================================================

    logic irq_tx_empty;
    logic irq_rx_full;


    // ============================================================
    // Interfaces
    // ============================================================

    apb_if  apb_vif(pclk);
    uart_if uart_vif(pclk);

    assign uart_vif.rst_n = apb_vif.PRESETn;


    // ============================================================
    // FSDB waveform dump
    // ============================================================

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_top);
    end


    // ============================================================
    // Clock generation
    // 50 MHz
    // ============================================================

    initial begin

        pclk = 1'b0;

        forever #10 pclk = ~pclk;

    end


    // ============================================================
    // Reset
    // ============================================================

    initial begin

        apb_vif.PRESETn = 1'b0;

        repeat (5)
            @(posedge pclk);

        apb_vif.PRESETn = 1'b1;

        uvm_root::get().set_timeout(1ms, 0);

    end


    // ============================================================
    // DUT
    // ============================================================

    uart_controller dut (

        .pclk_i          (pclk),
        .presetn_i       (apb_vif.PRESETn),

        .psel_i          (apb_vif.PSEL),
        .penable_i       (apb_vif.PENABLE),
        .pwrite_i        (apb_vif.PWRITE),

        .paddr_i         (apb_vif.PADDR),
        .pwdata_i        (apb_vif.PWDATA),

        .pstrb_i         (apb_vif.PSTRB),
        .pprot_i         (apb_vif.PPROT),

        .prdata_o        (apb_vif.PRDATA),
        .pready_o        (apb_vif.PREADY),
        .pslverr_o       (apb_vif.PSLVERR),

        .uart_tx_o       (uart_vif.tx),
        .uart_rx_i       (uart_vif.rx),

        .irq_tx_empty_o  (irq_tx_empty),
        .irq_rx_full_o   (irq_rx_full)

    );


    // ============================================================
    // UVM configuration
    // ============================================================

    initial begin

        // APB Driver
        uvm_config_db#(virtual apb_if.DRIVER)::set(
            null,
            "uvm_test_top.env.apb_agt.driver",
            "vif",
            apb_vif
        );

        // APB Monitor
        uvm_config_db#(virtual apb_if.MONITOR)::set(
            null,
            "uvm_test_top.env.apb_agt.monitor",
            "vif",
            apb_vif
        );

        // UART Driver
        uvm_config_db#(virtual uart_if.DRIVER)::set(
            null,
            "uvm_test_top.env.uart_agt.driver",
            "vif",
            uart_vif
        );

        // UART TX Monitor
        uvm_config_db#(virtual uart_if.MONITOR)::set(
            null,
            "uvm_test_top.env.uart_agt.tx_monitor",
            "vif",
            uart_vif
        );

        // UART RX Monitor
        uvm_config_db#(virtual uart_if.MONITOR)::set(
            null,
            "uvm_test_top.env.uart_agt.rx_monitor",
            "vif",
            uart_vif
        );

        run_test("stat_frame_error_test");

    end

endmodule