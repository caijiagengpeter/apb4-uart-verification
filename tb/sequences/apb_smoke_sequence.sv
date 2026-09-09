`ifndef APB_SMOKE_SEQUENCE_SV
`define APB_SMOKE_SEQUENCE_SV

class apb_smoke_sequence extends apb_sequence;

    `uvm_object_utils(apb_smoke_sequence)

    function new(string name = "apb_smoke_sequence");
        super.new(name);
    endfunction


    task body();

        logic [31:0] rdata;
        logic        slverr;

        // ============================================================
        // 1. Write CTRL = 0x00000003
        //    bit0 = enable
        //    bit1 = tx_enable
        // ============================================================

        `uvm_info(
            "APB_SMOKE_SEQ",
            "Writing CTRL = 0x00000003",
            UVM_LOW
        )

        apb_write(
            8'h00,
            32'h0000_0003,
            4'h1,
            3'h0
        );


        // ============================================================
        // 2. Read CTRL
        //    Expected = 0x00000003
        // ============================================================

        apb_read(
            8'h00,
            rdata,
            slverr,
            3'h0
        );

        if (slverr !== 1'b0) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                "CTRL read returned unexpected PSLVERR"
            )
        end

        if (rdata !== 32'h0000_0003) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                $sformatf(
                    "CTRL mismatch: expected=0x00000003 actual=0x%08h",
                    rdata
                )
            )
        end

        `uvm_info(
            "APB_SMOKE_SEQ",
            $sformatf(
                "Read CTRL: data=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_LOW
        )


        // ============================================================
        // 3. Read STAT
        //    Current expected value = 0x00000008
        //    bit3 = RX_EMPTY
        // ============================================================

        apb_read(
            8'h04,
            rdata,
            slverr,
            3'h0
        );

        if (slverr !== 1'b0) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                "STAT read returned unexpected PSLVERR"
            )
        end

        if (rdata !== 32'h0000_0008) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                $sformatf(
                    "STAT mismatch: expected=0x00000008 actual=0x%08h",
                    rdata
                )
            )
        end

        `uvm_info(
            "APB_SMOKE_SEQ",
            $sformatf(
                "Read STAT: data=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_LOW
        )


        // ============================================================
        // 4. Write BAUD = 0x12345678
        // ============================================================

        `uvm_info(
            "APB_SMOKE_SEQ",
            "Writing BAUD = 0x12345678",
            UVM_LOW
        )

        apb_write(
            8'h10,
            32'h1234_5678,
            4'hF,
            3'h0
        );


        // ============================================================
        // 5. Read BAUD
        //    Expected = 0x12345678
        // ============================================================

        apb_read(
            8'h10,
            rdata,
            slverr,
            3'h0
        );

        if (slverr !== 1'b0) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                "BAUD read returned unexpected PSLVERR"
            )
        end

        if (rdata !== 32'h1234_5678) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                $sformatf(
                    "BAUD mismatch: expected=0x12345678 actual=0x%08h",
                    rdata
                )
            )
        end

        `uvm_info(
            "APB_SMOKE_SEQ",
            $sformatf(
                "Read BAUD: data=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_LOW
        )

        // ============================================================
        // 6. PSTRB test
        //    Current BAUD = 0x12345678
        //    Write only byte[0] with 0xAA
        //    Expected BAUD = 0x123456AA
        // ============================================================

        `uvm_info(
            "APB_SMOKE_SEQ",
            "Testing PSTRB: BAUD byte[0] = 0xAA",
            UVM_LOW
        )

        apb_write(
            8'h10,
            32'h0000_00AA,
            4'b0001,
            3'h0
        );

        apb_read(
            8'h10,
            rdata,
            slverr,
            3'h0
        );

        if (slverr !== 1'b0) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                "PSTRB BAUD read returned unexpected PSLVERR"
            )
        end

        if (rdata !== 32'h1234_56AA) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                $sformatf(
                    "PSTRB mismatch: expected=0x123456AA actual=0x%08h",
                    rdata
                )
            )
        end

        `uvm_info(
            "APB_SMOKE_SEQ",
            $sformatf(
                "PSTRB test: expected=0x123456AA actual=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_LOW
        )

        // ============================================================
        // 7. Invalid address test
        //    0x80 is not a valid UART register address
        //    Expected PSLVERR = 1
        // ============================================================

        `uvm_info(
            "APB_SMOKE_SEQ",
            "Testing invalid address 0x80, expecting PSLVERR=1",
            UVM_LOW
        )

        apb_read(
            8'h80,
            rdata,
            slverr,
            3'h0
        );

        if (slverr !== 1'b1) begin
            `uvm_error(
                "APB_SMOKE_SEQ",
                $sformatf(
                    "Invalid address test failed: expected PSLVERR=1 actual=%0b",
                    slverr
                )
            )
        end

        `uvm_info(
            "APB_SMOKE_SEQ",
            $sformatf(
                "Invalid address test: ADDR=0x80 PSLVERR=%0b",
                slverr
            ),
            UVM_LOW
        )
    endtask

endclass

`endif