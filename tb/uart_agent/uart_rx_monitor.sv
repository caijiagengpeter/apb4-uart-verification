`ifndef UART_RX_MONITOR_SV
`define UART_RX_MONITOR_SV

class uart_rx_monitor extends uvm_monitor;

localparam int CLKS_PER_BIT      = 50_000_000 / 115_200; // 434
localparam int HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;     // 217

    `uvm_component_utils(uart_rx_monitor)

    virtual uart_if.MONITOR vif;

    uvm_analysis_port #(uart_item) uaprx;
    uvm_analysis_port #(uart_item) uap_rx_start;

    function new(string name = "uart_rx_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        uaprx = new("uaprx", this);
        uap_rx_start = new("uap_rx_start", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual uart_if.MONITOR)::get(this, "", "vif", vif)) begin
            `uvm_fatal("UART_RX_MONITOR", "Failed to get virtual interface")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        uart_item req;

        forever begin

            wait(vif.rst_n === 1'b1);

            req = uart_item::type_id::create("req");

            wait_start_bit();

            uap_rx_start.write(req);

            sample_data_bits(req);
            sample_stop_bit();

            `uvm_info(
                "UART_RX_MONITOR",
                $sformatf("Monitoring UART with data: 0x%02h", req.data),
                UVM_MEDIUM
            )

            uaprx.write(req);

        end

    endtask
///////////////////////////////////////////////////////////////////////////////////////////
    task wait_start_bit();

        forever begin

            @(negedge vif.rx);

            repeat (HALF_CLKS_PER_BIT)
                @(posedge vif.clk);

            if (vif.rx === 1'b0) begin
                return;  // 确认真 start，退出 task
            end

            `uvm_warning(
                "UART_RX_MONITOR",
                "False start bit detected"
            )

            // 不 return
            // forever 自动回去继续等下一个 negedge
        end

    endtask


    task sample_data_bits(uart_item req);

        for (int i = 0; i < 8; i++) begin

            repeat (CLKS_PER_BIT)
                @(posedge vif.clk);

            req.data[i] = vif.rx;

        end

    endtask


    task sample_stop_bit();

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

        if (vif.rx !== 1'b1) begin
            `uvm_error(
                "UART_RX_MONITOR",
                "Invalid stop bit"
            )
        end

    endtask
endclass

`endif