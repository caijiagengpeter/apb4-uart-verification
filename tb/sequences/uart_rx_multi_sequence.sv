`ifndef UART_RX_MULTI_SEQUENCE_SV
`define UART_RX_MULTI_SEQUENCE_SV

class uart_rx_multi_sequence extends uart_sequence;

    `uvm_object_utils(uart_rx_multi_sequence)

    rand int unsigned num_bytes;
    rand logic [7:0] rx_data[];
    rand bit inject_frame_error;
    rand bit inject_parity_error;
    rand logic parity_en;
    rand logic parity_odd;

    constraint c_default_frame_error {
        soft inject_frame_error == 1'b0;
    }

    constraint c_num_bytes {
        num_bytes inside {[1:20]};
    }

    constraint c_data_size {
        rx_data.size() == num_bytes;
    }

    constraint c_default_parity_error {
        soft inject_parity_error == 1'b0;
    }

    constraint c_default_parity {
        soft parity_en  == 1'b0;
        soft parity_odd == 1'b0;
    }

    constraint c_parity_error_requires_parity {
        inject_parity_error -> parity_en;
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
            $sformatf(
                "RX[%0d]=0x%02h frame_error=%0b parity_en=%0b parity_odd=%0b parity_error=%0b",
                i,
                rx_data[i],
                inject_frame_error,
                parity_en,
                parity_odd,
                inject_parity_error
            ),
            UVM_MEDIUM
        )

        send_uart(
            rx_data[i],
            inject_frame_error,
            inject_parity_error,
            parity_en, 
            parity_odd
        );

        end
        
    endtask

endclass

`endif
