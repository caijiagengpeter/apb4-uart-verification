`ifndef UART_TX_SMOKE_SEQUENCE_SV
`define UART_TX_SMOKE_SEQUENCE_SV

class uart_tx_smoke_sequence extends apb_sequence;

    `uvm_object_utils(uart_tx_smoke_sequence)

    function new(string name = "uart_tx_smoke_sequence");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "UART_TX_SMOKE_SEQ",
            "Starting UART TX smoke sequence",
            UVM_MEDIUM
        )

        // Enable UART + TX
        apb_write(
            8'h00,
            32'h0000_0003,
            4'b0001,
            3'b000
        );

        // Send 0x55 into TX FIFO
        apb_write(
            8'h08,
            32'h0000_0055,
            4'b0001,
            3'b000
        );

    endtask

endclass

`endif