`ifndef UART_RX_SMOKE_SEQUENCE_SV
`define UART_RX_SMOKE_SEQUENCE_SV

class uart_rx_smoke_sequence extends apb_sequence;

    `uvm_object_utils(uart_rx_smoke_sequence)

    function new(string name = "uart_rx_smoke_sequence");
        super.new(name);
    endfunction

    task body();

        `uvm_info(
            "UART_RX_SMOKE_SEQ",
            "Starting UART RX smoke sequence",
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