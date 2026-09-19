`ifndef APB_REGISTER_ACCESS_SEQUENCE_SV
`define APB_REGISTER_ACCESS_SEQUENCE_SV

class apb_register_access_sequence extends apb_sequence;

    `uvm_object_utils(apb_register_access_sequence)

    function new(string name = "apb_register_access_sequence");
        super.new(name);
    endfunction

    task body();

        logic [31:0] rdata;
        logic        slverr;

        `uvm_info(
            "APB_REGISTER_ACCESS_SEQ",
            "Starting APB register access coverage sequence",
            UVM_MEDIUM
        )

        // ------------------------------------------------
        // CTRL 0x00
        // write with PSTRB[0] = 1
        // ------------------------------------------------
        apb_write(
            8'h00,
            32'h0000_0001,
            4'b0001,
            3'b000
        );

        // read CTRL
        apb_read(
            8'h00,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // BAUD 0x10
        // hit PSTRB true / false branches
        // ------------------------------------------------
        apb_write(
            8'h10,
            32'h0000_0010,
            4'b0001,
            3'b000
        );

        apb_write(
            8'h10,
            32'h0000_0020,
            4'b0000,
            3'b000
        );

        apb_read(
            8'h10,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // FIFO 0x14
        // ------------------------------------------------
        apb_write(
            8'h14,
            32'h0000_000F,
            4'b0001,
            3'b000
        );

        apb_write(
            8'h14,
            32'h0000_000A,
            4'b0000,
            3'b000
        );

        apb_read(
            8'h14,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // INT 0x18
        // ------------------------------------------------
        apb_write(
            8'h18,
            32'h0000_0003,
            4'b0001,
            3'b000
        );

        apb_write(
            8'h18,
            32'h0000_0000,
            4'b0000,
            3'b000
        );

        apb_read(
            8'h18,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // STAT 0x04 read
        // ------------------------------------------------
        apb_read(
            8'h04,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // RXDATA 0x0C read
        // empty-read corner if FIFO is empty
        // ------------------------------------------------
        apb_read(
            8'h0C,
            rdata,
            slverr
        );


        // ------------------------------------------------
        // Illegal address write
        // should exercise default write branch
        // ------------------------------------------------
        apb_write(
            8'hFC,
            32'hDEAD_BEEF,
            4'b0001,
            3'b000
        );


        // ------------------------------------------------
        // Illegal address read
        // should exercise default read branch
        // ------------------------------------------------
        apb_read(
            8'hFC,
            rdata,
            slverr
        );

        // ============================================================
        // Remaining PSTRB branch coverage
        // ============================================================

        // CTRL: exercise PSTRB[0] = 0
        apb_write(
            8'h00,
            32'h0000_0001,
            4'b0010,
            3'b000
        );


        // TXDATA: exercise PSTRB[0] = 0
        // Should NOT update TXDATA / enqueue TX FIFO
        apb_write(
            8'h08,
            32'h0000_00A5,
            4'b0010,
            3'b000
        );


        // ------------------------------------------------------------
        // BAUD: exercise byte lanes 1, 2, 3
        // ------------------------------------------------------------

        apb_write(
            8'h10,
            32'h0000_AA00,
            4'b0010,
            3'b000
        );

        apb_write(
            8'h10,
            32'h00BB_0000,
            4'b0100,
            3'b000
        );

        apb_write(
            8'h10,
            32'hCC00_0000,
            4'b1000,
            3'b000
        );


        // ------------------------------------------------------------
        // FIFO: exercise byte lanes 1, 2, 3
        // ------------------------------------------------------------

        apb_write(
            8'h14,
            32'h0000_1100,
            4'b0010,
            3'b000
        );

        apb_write(
            8'h14,
            32'h0022_0000,
            4'b0100,
            3'b000
        );

        apb_write(
            8'h14,
            32'h3300_0000,
            4'b1000,
            3'b000
        );


        `uvm_info(
            "APB_REGISTER_ACCESS_SEQ",
            "APB register access coverage sequence completed",
            UVM_MEDIUM
        )

    endtask

endclass

`endif