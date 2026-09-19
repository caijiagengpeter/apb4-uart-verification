`ifndef UART_STATUS_MONITOR_SV
`define UART_STATUS_MONITOR_SV

class uart_status_monitor extends uvm_monitor;

    `uvm_component_utils(uart_status_monitor)

    virtual uart_status_if.MONITOR vif;

    uvm_analysis_port #(uart_status_item) ap;

    bit prev_tx_empty_irq;
    bit prev_rx_full_irq;


    function new(
        string name = "uart_status_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

        prev_tx_empty_irq = 1'b0;
        prev_rx_full_irq  = 1'b0;

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(
                virtual uart_status_if.MONITOR
            )::get(this, "", "vif", vif)) begin

            `uvm_fatal(
                "UART_STATUS_MONITOR",
                "Failed to get uart_status_if"
            )

        end

    endfunction


    task run_phase(uvm_phase phase);

        uart_status_item tr;

        forever begin

            @(posedge vif.clk);

            // --------------------------------------------
            // Reset
            // --------------------------------------------
            if (!vif.rst_n) begin

                prev_tx_empty_irq = 1'b0;
                prev_rx_full_irq  = 1'b0;

                continue;

            end


            // --------------------------------------------
            // RX overrun event
            // --------------------------------------------
            if (vif.stat_overrun_err) begin

                tr = uart_status_item::type_id::create(
                    "overrun_tr"
                );

                tr.overrun_error = 1'b1;

                ap.write(tr);

            end


            // --------------------------------------------
            // TX EMPTY IRQ rising edge
            // --------------------------------------------
            if (vif.irq_tx_empty &&
                !prev_tx_empty_irq) begin

                tr = uart_status_item::type_id::create(
                    "tx_empty_irq_tr"
                );

                tr.tx_empty_irq = 1'b1;

                ap.write(tr);

            end


            // --------------------------------------------
            // RX FULL IRQ rising edge
            // --------------------------------------------
            if (vif.irq_rx_full &&
                !prev_rx_full_irq) begin

                tr = uart_status_item::type_id::create(
                    "rx_full_irq_tr"
                );

                tr.rx_full_irq = 1'b1;

                ap.write(tr);

            end


            // --------------------------------------------
            // Save previous IRQ values
            // --------------------------------------------
            prev_tx_empty_irq = vif.irq_tx_empty;
            prev_rx_full_irq  = vif.irq_rx_full;

        end

    endtask

endclass

`endif