`ifndef APB_RX_ENABLE_SV
`define APB_RX_ENABLE_SV

class apb_rx_enable extends apb_sequence;

    `uvm_object_utils(apb_rx_enable)

    function new(string name = "apb_rx_enable");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "APB_RX_ENABLE",
            "Starting APB RX enable sequence",
            UVM_MEDIUM
        )

        // Enable UART + RX
        apb_write(
            8'h00,
            32'h0000_0005,
            4'b0001,
            3'b000
        );
        
    endtask

endclass

`endif