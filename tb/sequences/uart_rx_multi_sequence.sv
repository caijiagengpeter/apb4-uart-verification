`ifndef UART_RX_MULTI_SEQUENCE_SV
`define UART_RX_MULTI_SEQUENCE_SV

class uart_rx_multi_sequence extends uart_sequence;

    `uvm_object_utils(uart_rx_multi_sequence)

    rand int unsigned num_bytes;
    rand logic [7:0] rx_data[];

    constraint c_num_bytes {
        num_bytes inside {[1:20]};
    }

    constraint c_data_size {
        rx_data.size() == num_bytes;
    }

////////////////////////////////////////////////////////////////////
    function new(string name = "uart_rx_multi_sequence");
        super.new(name);
    endfunction

    virtual task body();

        `uvm_info(
            "UART_RX_MULTI_SEQ",
            "Starting randomized UART RX multi sequence",
            UVM_MEDIUM
        )

        foreach (rx_data[i]) begin

            `uvm_info(
                "UART_RX_MULTI_SEQ",
                $sformatf("RX[%0d] = 0x%02h", i, rx_data[i]),
                UVM_MEDIUM
            )

            send_uart(rx_data[i]);
        end

    endtask

endclass

`endif
