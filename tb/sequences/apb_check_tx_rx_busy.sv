`ifndef APB_CHECK_TX_RX_BUSY_SV
`define APB_CHECK_TX_RX_BUSY_SV

class apb_check_tx_rx_busy extends apb_sequence;

    `uvm_object_utils(apb_check_tx_rx_busy)

    function new(string name = "apb_check_tx_rx_busy");
        super.new(name);
    endfunction

    virtual task body();

        logic [31:0] rdata;
        logic        slverr;

        apb_read(
            8'h04,
            rdata,
            slverr
        );

        if (slverr) begin

            `uvm_error(
                "TX_RX_BUSY_CHECK",
                "STAT read unexpectedly returned PSLVERR"
            )

        end

        // STAT[0] = TX_BUSY
        // STAT[1] = RX_BUSY
        if (rdata[1:0] !== 2'b11) begin

            `uvm_error(
                "TX_RX_BUSY_CHECK",
                $sformatf(
                    "TX/RX were not simultaneously busy: TX_BUSY=%0b RX_BUSY=%0b STAT=0x%08h",
                    rdata[0],
                    rdata[1],
                    rdata
                )
            )

        end
        else begin

            `uvm_info(
                "TX_RX_BUSY_CHECK",
                "Confirmed simultaneous TX_BUSY=1 and RX_BUSY=1",
                UVM_LOW
            )

        end

    endtask

endclass

`endif