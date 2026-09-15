`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);

    `uvm_component_utils(uart_driver)

    virtual uart_if.DRIVER vif;
///////////////////////////////////////////////conner case
    int unsigned inter_frame_gap_bits = 1;
///////////////////////////////////////////////
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
                this, "", "vif", vif))
            `uvm_fatal("UART_DRIVER", "Failed to get virtual interface")

        if (!uvm_config_db#(int unsigned)::get(
                this,
                "",
                "inter_frame_gap_bits",
                inter_frame_gap_bits
            )) begin

            inter_frame_gap_bits = 1;

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

        vif.rx <= 1'b1;

        // start
        vif.rx <= 1'b0;
        wait_bit_time();

        // data
        for (int i = 0; i < 8; i++) begin
            vif.rx <= req.data[i];
            wait_bit_time();
        end

        // stop

        vif.rx <= !req.inject_frame_error;
        wait_bit_time();
        
        // return UART line to idle
        vif.rx <= 1'b1;
        
        // extra idle gap, only between frames
        repeat (CLKS_PER_BIT * inter_frame_gap_bits)
        @(posedge vif.clk);
            `uvm_info(
                "UART_DRIVER",
                $sformatf(
                    "Driving UART data=0x%02h frame_error=%0b",
                    req.data,
                    req.inject_frame_error
                ),
                UVM_MEDIUM
            )



        // extra idle gap, only between frames
        repeat (CLKS_PER_BIT * inter_frame_gap_bits)
            @(posedge vif.clk);

    endtask

    task wait_bit_time();

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

    endtask

endclass

`endif