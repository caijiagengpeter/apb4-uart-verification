`ifndef APB_POST_RESET_CHECK_SEQUENCE_SV
`define APB_POST_RESET_CHECK_SEQUENCE_SV

class apb_post_reset_check_sequence extends apb_sequence;

    `uvm_object_utils(apb_post_reset_check_sequence)

    function new(
        string name = "apb_post_reset_check_sequence"
    );
        super.new(name);
    endfunction


    virtual task body();

        logic [31:0] rdata;
        logic        slverr;


        ////////////////////////////////////////////////////////////
        // Check CTRL reset state
        ////////////////////////////////////////////////////////////

        apb_read(
            8'h00,
            rdata,
            slverr
        );

        if (slverr) begin
            `uvm_error(
                "APB_RESET_CHECK",
                "CTRL read returned PSLVERR after reset"
            )
        end

        if (rdata != 32'h0000_0000) begin
            `uvm_error(
                "APB_RESET_CHECK",
                $sformatf(
                    "CTRL did not return to reset value: 0x%08h",
                    rdata
                )
            )
        end
        else begin
            `uvm_info(
                "APB_RESET_CHECK",
                "CTRL correctly returned to reset value",
                UVM_LOW
            )
        end


        ////////////////////////////////////////////////////////////
        // Check INT reset state
        ////////////////////////////////////////////////////////////

        apb_read(
            8'h18,
            rdata,
            slverr
        );

        if (slverr) begin
            `uvm_error(
                "APB_RESET_CHECK",
                "INT read returned PSLVERR after reset"
            )
        end

        if (rdata != 32'h0000_0000) begin
            `uvm_error(
                "APB_RESET_CHECK",
                $sformatf(
                    "INT did not return to reset value: 0x%08h",
                    rdata
                )
            )
        end
        else begin
            `uvm_info(
                "APB_RESET_CHECK",
                "INT correctly returned to reset value",
                UVM_LOW
            )
        end


        ////////////////////////////////////////////////////////////
        // Check APB-visible UART/FIFO status
        //
        // STAT:
        // bit 0 TX_BUSY      -> 0
        // bit 1 RX_BUSY      -> 0
        // bit 2 TX_FULL      -> 0
        // bit 3 RX_EMPTY     -> 1
        // bit 4 PARITY_ERR   -> 0
        // bit 5 FRAME_ERR    -> 0
        // bit 6 OVERRUN_ERR  -> 0
        ////////////////////////////////////////////////////////////

        apb_read(
            8'h04,
            rdata,
            slverr
        );

        if (slverr) begin
            `uvm_error(
                "APB_RESET_CHECK",
                "STAT read returned PSLVERR after reset"
            )
        end

        if (rdata[6:0] != 7'b0001000) begin
            `uvm_error(
                "APB_RESET_CHECK",
                $sformatf(
                    "Unexpected STAT after reset: STAT[6:0]=0x%02h",
                    rdata[6:0]
                )
            )
        end
        else begin
            `uvm_info(
                "APB_RESET_CHECK",
                "STAT indicates idle UART and empty RX FIFO after reset",
                UVM_LOW
            )
        end


        ////////////////////////////////////////////////////////////
        // Post-reset recovery
        //
        // Write a new value and read it back.
        // This proves the APB slave still works after reset.
        ////////////////////////////////////////////////////////////

        apb_write(
            8'h10,
            32'h1234_5678,
            4'b1111,
            3'b000
        );

        apb_read(
            8'h10,
            rdata,
            slverr
        );

        if (slverr) begin
            `uvm_error(
                "APB_RESET_CHECK",
                "BAUD read returned PSLVERR during post-reset recovery"
            )
        end

        if (rdata != 32'h1234_5678) begin
            `uvm_error(
                "APB_RESET_CHECK",
                $sformatf(
                    "Post-reset APB recovery failed: expected=0x12345678 actual=0x%08h",
                    rdata
                )
            )
        end
        else begin
            `uvm_info(
                "APB_RESET_CHECK",
                "Post-reset APB write/read recovery passed",
                UVM_LOW
            )
        end

    endtask

endclass

`endif