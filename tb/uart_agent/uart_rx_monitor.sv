`ifndef UART_RX_MONITOR_SV
`define UART_RX_MONITOR_SV

class uart_rx_monitor extends uvm_monitor;

    localparam int CLKS_PER_BIT      = 50_000_000 / 115_200;
    localparam int HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;

    `uvm_component_utils(uart_rx_monitor)

    virtual uart_if.MONITOR vif;

    uvm_analysis_port #(uart_item) uaprx;
    uvm_analysis_port #(uart_item) uap_rx_start;
    uvm_analysis_port #(uart_item) uap_frame_error;

    bit parity_en  = 1'b0;
    bit parity_odd = 1'b0;


    function new(
        string name = "uart_rx_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);

        uaprx           = new("uaprx", this);
        uap_rx_start    = new("uap_rx_start", this);
        uap_frame_error = new("uap_frame_error", this);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.MONITOR)::get(
                this, "", "vif", vif
            )) begin

            `uvm_fatal(
                "UART_RX_MONITOR",
                "Failed to get virtual interface"
            )

        end

        if (!uvm_config_db#(bit)::get(
                this, "", "parity_en", parity_en
            ))
            parity_en = 1'b0;

        if (!uvm_config_db#(bit)::get(
                this, "", "parity_odd", parity_odd
            ))
            parity_odd = 1'b0;

    endfunction


    // ============================================================
    // Wait clocks, but abort if reset happens
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
        bit       sample_ok;
        bit       frame_valid;

        forever begin

            wait(vif.rst_n === 1'b1);

            req = uart_item::type_id::create("req");

            // ----------------------------------------------------
            // 1. Start bit
            // ----------------------------------------------------

            wait_start_bit(sample_ok);

            if (!sample_ok) begin

                `uvm_info(
                    "UART_RX_MONITOR",
                    "Reset detected while waiting for RX start bit",
                    UVM_MEDIUM
                )

                continue;

            end


            req.parity_en  = parity_en;
            req.parity_odd = parity_odd;

            // Receiver has started observing a UART frame.
            uap_rx_start.write(req);


            // ----------------------------------------------------
            // 2. Data bits
            // ----------------------------------------------------

            sample_data_bits(
                req,
                sample_ok
            );

            if (!sample_ok) begin

                `uvm_info(
                    "UART_RX_MONITOR",
                    "UART RX frame aborted by reset during data bits",
                    UVM_LOW
                )

                continue;

            end


            // ----------------------------------------------------
            // 3. Optional parity
            // ----------------------------------------------------

            if (parity_en) begin

                sample_parity_bit(
                    req,
                    sample_ok
                );

                if (!sample_ok) begin

                    `uvm_info(
                        "UART_RX_MONITOR",
                        "UART RX frame aborted by reset during parity bit",
                        UVM_LOW
                    )

                    continue;

                end

            end


            // ----------------------------------------------------
            // 4. Stop bit
            // ----------------------------------------------------

            sample_stop_bit(
                req,
                frame_valid,
                sample_ok
            );

            if (!sample_ok) begin

                `uvm_info(
                    "UART_RX_MONITOR",
                    "UART RX frame aborted by reset during stop bit",
                    UVM_LOW
                )

                continue;

            end


            if (frame_valid) begin

                `uvm_info(
                    "UART_RX_MONITOR",
                    $sformatf(
                        "Monitoring valid UART frame: data=0x%02h parity_en=%0b parity_bit=%0b",
                        req.data,
                        parity_en,
                        req.parity_bit
                    ),
                    UVM_MEDIUM
                )

            end

        end

    endtask


    // ============================================================
    // Start bit
    // ============================================================

    task wait_start_bit(
        output bit success
    );

        bit timing_ok;

        success = 1'b0;

        forever begin

            if (vif.rst_n !== 1'b1)
                return;


            fork : WAIT_RX_START_OR_RESET

                begin
                    @(negedge vif.rx);
                end

                begin
                    @(negedge vif.rst_n);
                end

            join_any

            disable WAIT_RX_START_OR_RESET;


            if (vif.rst_n !== 1'b1)
                return;


            wait_clks_or_reset(
                HALF_CLKS_PER_BIT,
                timing_ok
            );

            if (!timing_ok)
                return;


            if (vif.rx === 1'b0) begin
                success = 1'b1;
                return;
            end


            `uvm_warning(
                "UART_RX_MONITOR",
                "False start bit detected"
            )

        end

    endtask


    // ============================================================
    // Data bits
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

            req.data[i] = vif.rx;

        end

    endtask


    // ============================================================
    // Parity
    // ============================================================

    task sample_parity_bit(
        uart_item req,
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

        req.parity_bit = vif.rx;

        `uvm_info(
            "UART_RX_MONITOR",
            $sformatf(
                "Observed UART parity bit=%0b",
                req.parity_bit
            ),
            UVM_HIGH
        )

    endtask


    // ============================================================
    // Stop bit
    // ============================================================

    task sample_stop_bit(
        uart_item req,
        output bit frame_valid,
        output bit success
    );

        bit timing_ok;

        success     = 1'b1;
        frame_valid = 1'b0;


        wait_clks_or_reset(
            CLKS_PER_BIT,
            timing_ok
        );

        if (!timing_ok) begin
            success = 1'b0;
            return;
        end


        if (vif.rx !== 1'b1) begin

            frame_valid = 1'b0;

            uap_frame_error.write(req);

            `uvm_info(
                "UART_RX_MONITOR",
                "Invalid stop bit observed, dropping frame",
                UVM_MEDIUM
            )

        end
        else begin

            frame_valid = 1'b1;

            uaprx.write(req);

        end

    endtask

endclass

`endif