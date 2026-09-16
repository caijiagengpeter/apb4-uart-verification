`ifndef UART_RX_MONITOR_SV
`define UART_RX_MONITOR_SV

class uart_rx_monitor extends uvm_monitor;

    localparam int CLKS_PER_BIT       = 50_000_000 / 115_200; // 434
    localparam int HALF_CLKS_PER_BIT  = CLKS_PER_BIT / 2;     // 217

    `uvm_component_utils(uart_rx_monitor)

    virtual uart_if.MONITOR vif;

    uvm_analysis_port #(uart_item) uaprx;
    uvm_analysis_port #(uart_item) uap_rx_start;

    // Monitor configuration
    bit parity_en = 1'b0;

    function new(
        string name = "uart_rx_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);

        uaprx = new("uaprx", this);
        uap_rx_start = new("uap_rx_start", this);
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
                "UART_RX_MONITOR",
                "Failed to get virtual interface"
            )

        end

        // Default remains parity disabled.
        // Parity-enabled tests can override this through config_db.
        if (!uvm_config_db#(bit)::get(
                this,
                "",
                "parity_en",
                parity_en
            )) begin

            parity_en = 1'b0;

        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        uart_item req;
        bit frame_valid;

        forever begin

            wait(vif.rst_n === 1'b1);

            req = uart_item::type_id::create("req");

            wait_start_bit();

            // RX transaction has started
            uap_rx_start.write(req);

            // Sample 8 data bits
            sample_data_bits(req);

            // If parity mode is enabled, consume one parity bit
            // before checking the stop bit.
            if (parity_en) begin
                sample_parity_bit(req);
            end

            // Sample and validate stop bit
            sample_stop_bit(req, frame_valid);

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


    task wait_start_bit();

        forever begin

            @(negedge vif.rx);

            repeat (HALF_CLKS_PER_BIT)
                @(posedge vif.clk);

            if (vif.rx === 1'b0) begin
                return;
            end

            `uvm_warning(
                "UART_RX_MONITOR",
                "False start bit detected"
            )

        end

    endtask


    task sample_data_bits(uart_item req);

        for (int i = 0; i < 8; i++) begin

            repeat (CLKS_PER_BIT)
                @(posedge vif.clk);

            req.data[i] = vif.rx;

        end

    endtask


    task sample_parity_bit(uart_item req);

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

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


    task sample_stop_bit(
        uart_item req,
        output bit frame_valid
    );

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

        if (vif.rx !== 1'b1) begin

            frame_valid = 1'b0;

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