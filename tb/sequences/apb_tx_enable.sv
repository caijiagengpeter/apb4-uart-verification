`ifndef APB_TX_ENABLE_SV
`define APB_TX_ENABLE_SV

class apb_tx_enable extends apb_sequence;

    `uvm_object_utils(apb_tx_enable)

    function new(string name = "apb_tx_enable");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "APB_TX_ENABLE",
            "Starting APB TX enable sequence",
            UVM_MEDIUM
        )

        // Enable UART + TX
        apb_write(
            8'h00,
            32'h0000_0003,
            4'b0001,
            3'b000
        );
        
    endtask

endclass

`endif