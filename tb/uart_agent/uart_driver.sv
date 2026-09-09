`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);

    `uvm_component_utils(uart_driver)

    virtual uart_if.DRIVER vif;

    localparam int CLKS_PER_BIT = 50_000_000 / 115_200;

    function new(
        string name = "uart_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.DRIVER)::get(
                this, "", "vif", vif)) begin

            `uvm_fatal(
                "UART_DRIVER",
                "Failed to get virtual interface"
            )

        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        uart_item req;

        // UART idle state
        vif.rx <= 1'b1;

        forever begin

            wait(vif.rst_n === 1'b1);

            seq_item_port.get_next_item(req);

            drive_uart(req);

            seq_item_port.item_done();

        end

    endtask


    task drive_uart(uart_item req);

        // idle
        vif.rx <= 1'b1;

        // start bit
        vif.rx <= 1'b0;
        wait_bit_time();

        // 8 data bits, LSB first
        for (int i = 0; i < 8; i++) begin
            vif.rx <= req.data[i];
            wait_bit_time();
        end

        // stop bit
        vif.rx <= 1'b1;
        wait_bit_time();

        `uvm_info(
            "UART_DRIVER",
            $sformatf(
                "Driving UART with data: 0x%02h",
                req.data
            ),
            UVM_MEDIUM
        )

    endtask


    task wait_bit_time();

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

    endtask

endclass

`endif