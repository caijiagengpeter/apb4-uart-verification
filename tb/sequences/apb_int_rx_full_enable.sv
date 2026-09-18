`ifndef APB_INT_RX_FULL_ENABLE_SV
`define APB_INT_RX_FULL_ENABLE_SV

class apb_int_rx_full_enable extends apb_sequence;

    `uvm_object_utils(apb_int_rx_full_enable)

    function new(string name = "apb_int_rx_full_enable");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "APB_INT_RX_FULL_ENABLE",
            "Starting APB INT RX_FULL enable sequence",
            UVM_MEDIUM
        )

        apb_write(
            8'h18,
            32'h0000_0002,
            4'b0001,
            3'b000
        );

    endtask

endclass

`endif