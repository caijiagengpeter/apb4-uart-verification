`ifndef APB_TX_RX_ENABLE_SV
`define APB_TX_RX_ENABLE_SV

class apb_tx_rx_enable extends apb_sequence;

    `uvm_object_utils(apb_tx_rx_enable)

    function new(string name = "apb_tx_rx_enable");
        super.new(name);
    endfunction

    virtual task body();

        `uvm_info(
            "APB_TX_RX_ENABLE",
            "Enabling UART TX and RX simultaneously",
            UVM_MEDIUM
        )

        // CTRL:
        // bit 0 = global enable
        // bit 1 = TX enable
        // bit 2 = RX enable
        apb_write(
            8'h00,
            32'h0000_0007,
            4'b0001,
            3'b000
        );

    endtask

endclass

`endif