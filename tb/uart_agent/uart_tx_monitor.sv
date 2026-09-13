`ifndef UART_TX_MONITOR_SV
`define UART_TX_MONITOR_SV

class uart_tx_monitor extends uvm_monitor;

localparam int CLKS_PER_BIT      = 50_000_000 / 115_200; // 434
localparam int HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;     // 217

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
        if(!uvm_config_db#(virtual uart_if.MONITOR)::get(this, "", "vif", vif)) begin
            `uvm_fatal("UART_TX_MONITOR", "Failed to get virtual interface")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
    
        uart_item req;
    
        forever begin
        
            wait(vif.rst_n === 1'b1);
    
            req = uart_item::type_id::create("req");
    
            // ------------------------------------------------
            // 1. Detect confirmed frame start
            // ------------------------------------------------
            wait_start_bit();
    
            // Notify scoreboard:
            // DUT TX FIFO has effectively started consuming one byte
            uap_start.write(req);
    
            // ------------------------------------------------
            // 2. Decode actual UART frame
            // ------------------------------------------------
            sample_data_bits(req);
            sample_stop_bit();
    
            `uvm_info(
                "UART_TX_MONITOR",
                $sformatf(
                    "Monitoring UART with data: 0x%02h",
                    req.data
                ),
                UVM_MEDIUM
            )
    
            // ------------------------------------------------
            // 3. Complete frame -> data comparison
            // ------------------------------------------------
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
                "UART_TX_MONITOR",
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
                "UART_TX_MONITOR",
                "Invalid stop bit"
            )
        end

    endtask
endclass

`endif