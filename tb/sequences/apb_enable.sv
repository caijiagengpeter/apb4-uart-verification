`ifndef APB_ENABLE_SV
`define APB_ENABLE_SV

class apb_enable extends apb_sequence;

    `uvm_object_utils(apb_enable)

    function new(string name = "apb_enable");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "APB_ENABLE",
            "Starting APB enable sequence (without TX or RX Enable)",
            UVM_MEDIUM
        )

        // Enable UART without RX or TX
        apb_write(
            8'h00,
            32'h0000_0001,
            4'b0001,
            3'b000
        );
        
    endtask

endclass

`endif