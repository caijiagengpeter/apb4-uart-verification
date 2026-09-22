`ifndef UART_TX_MONITOR_SV
`define UART_TX_MONITOR_SV

class uart_tx_monitor extends uvm_monitor;

    localparam int CLKS_PER_BIT       = 50_000_000 / 115_200;
    localparam int HALF_CLKS_PER_BIT  = CLKS_PER_BIT / 2;

    `uvm_component_utils(uart_tx_monitor)

    virtual uart_if.MONITOR vif;

    uvm_analysis_port #(uart_item) uap;
    uvm_analysis_port #(uart_item) uap_start;


    function new(
        string name = "uart_tx_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);

        uap       = new("uap", this);
        uap_start = new("uap_start", this);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.MONITOR)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "UART_TX_MONITOR",
                "Failed to get virtual interface"
            )

        end

    endfunction


    // ============================================================
    // Wait N clocks, but abort immediately if reset is observed.
    // ============================================================

    task wait_clks_or_reset(
        input  int num_clks,
        output bit success
    );

        success = 1'b1;

        for (int i = 0; i < num_clks; i++) begin

            @(posedge vif.clk);

            if (vif.rst_n !== 1'b1) begin
                success = 1'b0;
                return;
            end

        end

    endtask


    // ============================================================
    // Main monitor
    // ============================================================

    virtual task run_phase(uvm_phase phase);

        uart_item req;
        bit       frame_valid;

        forever begin

            // Wait until DUT is out of reset.
            wait(vif.rst_n === 1'b1);

            req = uart_item::type_id::create("req");

            // ----------------------------------------------------
            // 1. Detect UART start bit
            // ----------------------------------------------------

            wait_start_bit(frame_valid);

            if (!frame_valid) begin

                `uvm_info(
                    "UART_TX_MONITOR",
                    "Reset detected while waiting for UART start bit",
                    UVM_MEDIUM
                )

                continue;

            end


            // DUT has started consuming one TX byte.
            uap_start.write(req);


            // ----------------------------------------------------
            // 2. Sample data bits
            // ----------------------------------------------------

            sample_data_bits(
                req,
                frame_valid
            );

            if (!frame_valid) begin

                `uvm_info(
                    "UART_TX_MONITOR",
                    "UART TX frame aborted by reset during data bits",
                    UVM_LOW
                )

                // IMPORTANT:
                // Do not publish partial UART transaction.
                continue;

            end


            // ----------------------------------------------------
            // 3. Sample stop bit
            // ----------------------------------------------------

            sample_stop_bit(frame_valid);

            if (!frame_valid) begin

                `uvm_info(
                    "UART_TX_MONITOR",
                    "UART TX frame aborted by reset during stop bit",
                    UVM_LOW
                )

                continue;

            end


            // ----------------------------------------------------
            // 4. Only complete frames reach scoreboard
            // ----------------------------------------------------

            `uvm_info(
                "UART_TX_MONITOR",
                $sformatf(
                    "Monitoring UART with data: 0x%02h",
                    req.data
                ),
                UVM_MEDIUM
            )

            uap.write(req);

        end

    endtask


    // ============================================================
    // Detect confirmed UART start bit
    // ============================================================

    task wait_start_bit(
        output bit success
    );

        bit timing_ok;

        success = 1'b0;

        forever begin

            // We enter this task only when reset is high,
            // but check again to protect against races.
            if (vif.rst_n !== 1'b1)
                return;


            // Wait for either:
            //   1. TX falling edge -> possible UART start
            //   2. reset assertion
            fork : WAIT_START_OR_RESET

                begin
                    @(negedge vif.tx);
                end

                begin
                    @(negedge vif.rst_n);
                end

            join_any

            disable WAIT_START_OR_RESET;


            // Reset won the race.
            if (vif.rst_n !== 1'b1)
                return;


            // Move to middle of start bit.
            wait_clks_or_reset(
                HALF_CLKS_PER_BIT,
                timing_ok
            );

            if (!timing_ok)
                return;


            if (vif.tx === 1'b0) begin

                success = 1'b1;
                return;

            end


            `uvm_warning(
                "UART_TX_MONITOR",
                "False start bit detected"
            )

        end

    endtask


    // ============================================================
    // Sample 8 UART data bits
    // ============================================================

    task sample_data_bits(
        uart_item req,
        output bit success
    );

        bit timing_ok;

        success = 1'b1;

        for (int i = 0; i < 8; i++) begin

            wait_clks_or_reset(
                CLKS_PER_BIT,
                timing_ok
            );

            if (!timing_ok) begin
                success = 1'b0;
                return;
            end

            req.data[i] = vif.tx;

        end

    endtask


    // ============================================================
    // Sample UART stop bit
    // ============================================================

    task sample_stop_bit(
        output bit success
    );

        bit timing_ok;

        success = 1'b1;

        wait_clks_or_reset(
            CLKS_PER_BIT,
            timing_ok
        );

        if (!timing_ok) begin
            success = 1'b0;
            return;
        end


        if (vif.tx !== 1'b1) begin

            `uvm_error(
                "UART_TX_MONITOR",
                "Invalid stop bit"
            )

        end

    endtask

endclass

`endif