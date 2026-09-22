`ifndef APB_UNSUPPORTED_ACCESS_SEQUENCE_SV
`define APB_UNSUPPORTED_ACCESS_SEQUENCE_SV

class apb_unsupported_access_sequence extends apb_sequence;

    `uvm_object_utils(apb_unsupported_access_sequence)

    // The byte that should already exist in RX FIFO.
    logic [7:0] expected_rx_data = 8'h5A;

    function new(
        string name = "apb_unsupported_access_sequence"
    );
        super.new(name);
    endfunction


    virtual task body();

        logic [31:0] rdata;
        logic        slverr;

        ////////////////////////////////////////////////////////////
        // Case 1:
        // Unsupported READ from TXDATA
        ////////////////////////////////////////////////////////////

        `uvm_info(
            "APB_UNSUPPORTED",
            "Case 1: Read from TXDATA (0x08)",
            UVM_LOW
        )

        apb_read(
            8'h08,
            rdata,
            slverr
        );

        if (!slverr) begin

            `uvm_error(
                "APB_UNSUPPORTED",
                "Read from TXDATA did not return PSLVERR"
            )

        end
        else begin

            `uvm_info(
                "APB_UNSUPPORTED",
                "Read from TXDATA correctly returned PSLVERR",
                UVM_LOW
            )

        end


        ////////////////////////////////////////////////////////////
        // Case 2:
        // Unsupported WRITE to RXDATA
        //
        // RX FIFO should already contain expected_rx_data.
        ////////////////////////////////////////////////////////////

        `uvm_info(
            "APB_UNSUPPORTED",
            "Case 2: Write to RXDATA (0x0C)",
            UVM_LOW
        )

        apb_write_resp(
            8'h0C,
            32'h0000_00A5,
            slverr
        );

        if (!slverr) begin

            `uvm_error(
                "APB_UNSUPPORTED",
                "Write to RXDATA did not return PSLVERR"
            )

        end
        else begin

            `uvm_info(
                "APB_UNSUPPORTED",
                "Write to RXDATA correctly returned PSLVERR",
                UVM_LOW
            )

        end


        ////////////////////////////////////////////////////////////
        // Case 3:
        // Legal READ from RXDATA
        //
        // This proves that the illegal write above did NOT modify
        // or destroy the byte already stored in the RX FIFO.
        ////////////////////////////////////////////////////////////

        `uvm_info(
            "APB_UNSUPPORTED",
            "Case 3: Read RXDATA to check for illegal-write side effects",
            UVM_LOW
        )

        apb_read(
            8'h0C,
            rdata,
            slverr
        );

        // RXDATA read itself should be legal.
        if (slverr) begin

            `uvm_error(
                "APB_UNSUPPORTED",
                "Legal read from RXDATA unexpectedly returned PSLVERR"
            )

        end


        // Check that the original UART RX data is still present.
        if (rdata[7:0] != expected_rx_data) begin

            `uvm_error(
                "APB_UNSUPPORTED",
                $sformatf(
                    "RXDATA corrupted after unsupported write: expected=0x%02h actual=0x%02h",
                    expected_rx_data,
                    rdata[7:0]
                )
            )

        end
        else begin

            `uvm_info(
                "APB_UNSUPPORTED",
                $sformatf(
                    "RXDATA preserved correctly after unsupported write: 0x%02h",
                    rdata[7:0]
                ),
                UVM_LOW
            )

        end

    endtask

endclass

`endif