`ifndef APB_CHECK_TX_BUSY_SEQUENCE_SV
`define APB_CHECK_TX_BUSY_SEQUENCE_SV

class apb_check_tx_busy_sequence extends apb_sequence;

    `uvm_object_utils(apb_check_tx_busy_sequence)

    bit expected_busy;


    function new(string name = "apb_check_tx_busy_sequence");
        super.new(name);
        expected_busy = 1'b0;
    endfunction


    virtual task body();

        logic [31:0] rdata;
        logic        slverr;

        // STAT register = 0x04
        apb_read(
            8'h04,
            rdata,
            slverr
        );


        if (slverr) begin

            `uvm_error(
                "TX_BUSY_CHECK",
                "STAT read unexpectedly returned PSLVERR"
            )

        end


        if (rdata[0] !== expected_busy) begin

            `uvm_error(
                "TX_BUSY_CHECK",
                $sformatf(
                    "Unexpected TX_BUSY: expected=%0b actual=%0b STAT=0x%08h",
                    expected_busy,
                    rdata[0],
                    rdata
                )
            )

        end
        else begin

            `uvm_info(
                "TX_BUSY_CHECK",
                $sformatf(
                    "TX_BUSY correctly observed as %0b, STAT=0x%08h",
                    expected_busy,
                    rdata
                ),
                UVM_LOW
            )

        end

    endtask

endclass

`endif