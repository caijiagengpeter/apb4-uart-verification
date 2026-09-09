`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;

localparam int CLKS_PER_BIT      = 50_000_000 / 115_200; // 434
localparam int HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;     // 217

    `uvm_component_utils(uart_monitor)

    virtual uart_if.MONITOR vif;

    uvm_analysis_port #(uart_item) uap;

    function new(string name = "uart_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        uap = new("uap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual uart_if.MONITOR)::get(this, "", "vif", vif)) begin
            `uvm_fatal("UART_MONITOR", "Failed to get virtual interface")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        uart_item req;

        forever begin

            wait(vif.rst_n === 1'b1);

            req = uart_item::type_id::create("req");

            wait_start_bit();
            sample_data_bits(req);
            sample_stop_bit();

            `uvm_info(
                "UART_MONITOR",
                $sformatf("Monitoring UART with data: 0x%02h", req.data),
                UVM_MEDIUM
            )

            uap.write(req);

        end

    endtask
///////////////////////////////////////////////////////////////////////////////////////////
    task wait_start_bit();
    
        forever begin
        
            @(negedge vif.tx);
    
            repeat (HALF_CLKS_PER_BIT)
                @(posedge vif.clk);
    
            if (vif.tx === 1'b0) begin
                return;  // 确认真 start，退出 task
            end
    
            `uvm_warning(
                "UART_MONITOR",
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

            req.data[i] = vif.tx;

        end

    endtask


    task sample_stop_bit();

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

        if (vif.tx !== 1'b1) begin
            `uvm_error(
                "UART_MONITOR",
                "Invalid stop bit"
            )
        end

    endtask
endclass

`endif