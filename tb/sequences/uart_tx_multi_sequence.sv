`ifndef UART_TX_MULTI_SEQUENCE_SV
`define UART_TX_MULTI_SEQUENCE_SV

class uart_tx_multi_sequence extends apb_sequence;

    `uvm_object_utils(uart_tx_multi_sequence)

    rand int unsigned num_bytes;
    rand logic [7:0] tx_data[];

    constraint c_num_bytes {
        num_bytes inside {[1:8]};
    }

    constraint c_data_size {
        tx_data.size() == num_bytes;
    }


    function new(string name = "uart_tx_multi_sequence");
        super.new(name);
    endfunction

    virtual task body();

        `uvm_info(
            "UART_TX_MULTI_SEQ",
            "Starting randomized UART TX multi sequence",
            UVM_MEDIUM
        )

        // Enable UART + TX
        apb_write(
            8'h00,
            32'h0000_0003,
            4'b0001
        );

        foreach (tx_data[i]) begin

            `uvm_info(
                "UART_TX_MULTI_SEQ",
                $sformatf("TX[%0d] = 0x%02h", i, tx_data[i]),
                UVM_MEDIUM
            )

            apb_write(
                8'h08,
                {24'h0, tx_data[i]},
                4'b0001
            );

        end

    endtask

endclass

`endif
