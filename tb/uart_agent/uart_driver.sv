`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);

    `uvm_component_utils(uart_driver)

    virtual uart_if.DRIVER vif;
    localparam int CLKS_PER_BIT = 50_000_000 / 115_200;
///////////////////////////////////////////////conner case

    int unsigned inter_frame_gap_bits = 1;

////////////////////////////////////////////////////////////////////
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
    
        bit parity_bit;
    
        // ------------------------------------------------
        // Calculate parity bit
        // ------------------------------------------------
        parity_bit = req.parity_odd
                   ? ~^req.data
                   :  ^req.data;
    
        if (req.inject_parity_error)
            parity_bit = ~parity_bit;
    
    
        // ------------------------------------------------
        // UART start bit
        // ------------------------------------------------
        vif.rx <= 1'b0;
        wait_bit_time();
    
    
        // ------------------------------------------------
        // UART data bits
        // ------------------------------------------------
        for (int i = 0; i < 8; i++) begin
        
            vif.rx <= req.data[i];
            wait_bit_time();
    
        end
    
    
        // ------------------------------------------------
        // Optional parity bit
        // ------------------------------------------------
        if (req.parity_en) begin
        
            vif.rx <= parity_bit;
            wait_bit_time();
    
        end
    
    
        // ------------------------------------------------
        // Stop bit
        // ------------------------------------------------
        vif.rx <= !req.inject_frame_error;
        wait_bit_time();
    
    
        // ------------------------------------------------
        // Return UART line to idle
        // ------------------------------------------------
        vif.rx <= 1'b1;
    
    
        `uvm_info(
            "UART_DRIVER",
            $sformatf(
                "Driving UART data=0x%02h parity_en=%0b parity_odd=%0b parity_bit=%0b parity_error=%0b frame_error=%0b",
                req.data,
                req.parity_en,
                req.parity_odd,
                parity_bit,
                req.inject_parity_error,
                req.inject_frame_error
            ),
            UVM_MEDIUM
        )
    
    
        // ------------------------------------------------
        // Extra idle gap between frames
        // ------------------------------------------------
        repeat (CLKS_PER_BIT * inter_frame_gap_bits)
            @(posedge vif.clk);
    
    endtask

    task wait_bit_time();

        repeat (CLKS_PER_BIT)
            @(posedge vif.clk);

    endtask

endclass

`endif