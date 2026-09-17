`ifndef APB_INT_TX_EMPTY_ENABLE_SV
`define APB_INT_TX_EMPTY_ENABLE_SV

class apb_int_tx_empty_enable extends apb_sequence;

    `uvm_object_utils(apb_int_tx_empty_enable)

    function new(string name = "apb_int_tx_empty_enable");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "APB_INT_TX_EMPTY_ENABLE",
            "Starting APB INT TX_EMPTY enable sequence",
            UVM_MEDIUM
        )

        apb_write(
            8'h18,
            32'h0000_0001,
            4'b0001,
            3'b000
        );

    endtask

endclass

`endif