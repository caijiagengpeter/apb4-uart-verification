module tb_top;

    //============================================================
    // Parameters
    //============================================================
    localparam int CLOCK_FREQUENCY = 50_000_000;
    localparam int BAUD_RATE       = 115_200;

    // 50 MHz / 115200 ≈ 434 clock cycles
    // 1 bit ≈ 8680 ns
    localparam time BIT_TIME = 8680;

    //============================================================
    // APB4 signals
    //============================================================
    logic        pclk;
    logic        presetn;

    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [7:0]  paddr;
    logic [31:0] pwdata;
    logic [3:0]  pstrb;
    logic [2:0]  pprot;

    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;

    //============================================================
    // UART signals
    //============================================================
    logic        rxd;
    logic        txd;

    //============================================================
    // Interrupts
    //============================================================
    logic        irq_tx_empty;
    logic        irq_rx_full;

    //============================================================
    // DUT
    //============================================================
    uart_controller #(
        .CLOCK_FREQUENCY (CLOCK_FREQUENCY),
        .BAUD_RATE       (BAUD_RATE),
        .FIFO_DEPTH      (16),
        .DATA_WIDTH      (8),
        .STOP_BITS       (1),
        .PARITY_ENABLE   (1'b0),
        .PARITY_TYPE     ("even")
    ) dut (
        .pclk_i             (pclk),
        .presetn_i          (presetn),

        .psel_i             (psel),
        .penable_i          (penable),
        .pwrite_i           (pwrite),
        .paddr_i            (paddr),
        .pwdata_i           (pwdata),
        .pstrb_i            (pstrb),
        .pprot_i            (pprot),

        .prdata_o           (prdata),
        .pready_o           (pready),
        .pslverr_o          (pslverr),

        .uart_tx_o          (txd),
        .uart_rx_i          (rxd),

        .irq_tx_empty_o     (irq_tx_empty),
        .irq_rx_full_o      (irq_rx_full)
    );

    //============================================================
    // Clock
    // 50 MHz -> period = 20 ns
    //============================================================
    initial begin
        pclk = 1'b0;

        forever begin
            #10 pclk = ~pclk;
        end
    end

    //============================================================
    // Reset
    //============================================================
    initial begin
        presetn = 1'b0;

        #100;

        presetn = 1'b1;
    end

    //============================================================
    // Initial signal values
    //============================================================
    initial begin
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h00;
        pwdata  = 32'h0000_0000;
        pstrb   = 4'b0000;
        pprot   = 3'b000;

        // UART RX idle state must be HIGH
        rxd = 1'b1;
    end


    //################################################################
    // APB WRITE TASK
    //################################################################
    task automatic apb_write(
        input logic [7:0]  addr,
        input logic [31:0] data,
        input logic [3:0]  strb
    );
    begin

        $display("");
        $display("================================================");
        $display("[%0t] APB WRITE START", $time);
        $display("      ADDR = 0x%02h", addr);
        $display("      DATA = 0x%08h", data);
        $display("      STRB = %b", strb);
        $display("================================================");

        //========================================================
        // SETUP phase
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: ENTER SETUP", $time);

        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b1;
        paddr   = addr;
        pwdata  = data;
        pstrb   = strb;
        pprot   = 3'b000;

        //========================================================
        // ACCESS phase
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: ENTER ACCESS", $time);

        penable = 1'b1;

        // Wait for PREADY
        @(posedge pclk);

        $display(
            "[%0t] TB: ACCESS, PREADY=%b PSLVERR=%b",
            $time,
            pready,
            pslverr
        );

        while (!pready) begin

            @(posedge pclk);

            $display(
                "[%0t] TB: WAIT, PREADY=%b PSLVERR=%b",
                $time,
                pready,
                pslverr
            );

        end

        //========================================================
        // Return to IDLE
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: RETURN TO IDLE", $time);

        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h00;
        pwdata  = 32'h0000_0000;
        pstrb   = 4'b0000;
        pprot   = 3'b000;

        $display("[%0t] APB WRITE DONE", $time);

    end
    endtask


    //################################################################
    // APB READ TASK
    //################################################################
    task automatic apb_read(
        input  logic [7:0] addr,
        output logic [31:0] data
    );
    begin

        $display("");
        $display("================================================");
        $display("[%0t] APB READ START", $time);
        $display("      ADDR = 0x%02h", addr);
        $display("================================================");

        //========================================================
        // SETUP phase
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: ENTER READ SETUP", $time);

        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = addr;
        pwdata  = 32'h0000_0000;
        pstrb   = 4'b0000;
        pprot   = 3'b000;

        //========================================================
        // ACCESS phase
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: ENTER READ ACCESS", $time);

        penable = 1'b1;

        @(posedge pclk);

        $display(
            "[%0t] TB: READ ACCESS PREADY=%b PSLVERR=%b PRDATA=0x%08h",
            $time,
            pready,
            pslverr,
            prdata
        );

        while (!pready) begin

            @(posedge pclk);

            $display(
                "[%0t] TB: READ WAIT PREADY=%b PRDATA=0x%08h",
                $time,
                pready,
                prdata
            );

        end

        //========================================================
        // IMPORTANT:
        //
        // prdata_o is updated in DUT's always_ff at posedge.
        // Give NBA update a chance to complete.
        //========================================================
        #1;

        data = prdata;

        $display(
            "[%0t] TB: READ DATA = 0x%08h",
            $time,
            data
        );

        //========================================================
        // Return to IDLE
        //========================================================
        @(negedge pclk);

        $display("[%0t] TB: RETURN TO IDLE", $time);

        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h00;
        pwdata  = 32'h0000_0000;
        pstrb   = 4'b0000;
        pprot   = 3'b000;

        $display("[%0t] APB READ DONE", $time);

    end
    endtask


    //################################################################
    // UART TRANSMIT TASK
    //
    // TB acts as an external UART transmitter.
    //
    // Format:
    //
    //       IDLE START D0 D1 D2 D3 D4 D5 D6 D7 STOP
    //        1     0   ...                ...     1
    //
    // 8N1
    //################################################################
    task automatic uart_send_byte(
    input logic [7:0] data
);
begin
    $display("");
    $display("================================================");
    $display("[%0t] UART RX TEST: SEND BYTE", $time);
    $display("      DATA = 0x%02h", data);
    $display("================================================");

    // UART idle
    rxd = 1'b1;

    // START BIT
    rxd = 1'b0;
    $display("[%0t] UART TX: START = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 0
    rxd = data[0];
    $display("[%0t] UART TX: DATA[0] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 1
    rxd = data[1];
    $display("[%0t] UART TX: DATA[1] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 2
    rxd = data[2];
    $display("[%0t] UART TX: DATA[2] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 3
    rxd = data[3];
    $display("[%0t] UART TX: DATA[3] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 4
    rxd = data[4];
    $display("[%0t] UART TX: DATA[4] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 5
    rxd = data[5];
    $display("[%0t] UART TX: DATA[5] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 6
    rxd = data[6];
    $display("[%0t] UART TX: DATA[6] = %b", $time, rxd);
    #(BIT_TIME);

    // DATA BIT 7
    rxd = data[7];
    $display("[%0t] UART TX: DATA[7] = %b", $time, rxd);
    #(BIT_TIME);

    // STOP BIT
    rxd = 1'b1;
    $display("[%0t] UART TX: STOP = %b", $time, rxd);
    #(BIT_TIME);

    // IDLE
    rxd = 1'b1;

    $display("[%0t] UART TX: FRAME COMPLETE", $time);
end
endtask


    //################################################################
    // RX INTERNAL DEBUG
    //################################################################

    // Receiver state
    /*
always @(posedge pclk) begin

    if (presetn) begin

        $display("[%0t] RX DEBUG: rxd=%b rx_sync=%b state=%0d frame_cnt=%0d rx_data_reg=0x%02h rx_data=0x%02h done=%b busy=%b fifo_wr=%b fifo_empty=%b",
            $time,
            rxd,
            dut.uart_rx_inst.rx_sync,
            dut.uart_rx_inst.rx_state,
            dut.uart_rx_inst.frame_counter,
            dut.uart_rx_inst.rx_data_reg,
            dut.uart_rx_data,
            dut.uart_rx_done,
            dut.uart_rx_busy,
            dut.rx_fifo_wr_en,
            dut.rx_fifo_empty
        );

    end

end

    //################################################################
    // RX DONE MONITOR
    //################################################################
    always @(posedge pclk) begin

        if (presetn && dut.uart_rx_done) begin

            $display("");
            $display("************************************************");
            $display(
                "[%0t] RX DONE!",
                $time
            );
            $display(
                "      uart_rx_data = 0x%02h",
                dut.uart_rx_data
            );
            $display(
                "      rx_fifo_wr_en = %b",
                dut.rx_fifo_wr_en
            );
            $display("************************************************");
            $display("");

        end

    end

*/
    //################################################################
    // RX FIFO DEBUG
    //################################################################
    always @(posedge pclk) begin

        if (presetn && dut.rx_fifo_wr_en) begin

            $display("");
            $display(
                "[%0t] RX FIFO WRITE",
                $time
            );

            $display(
                "      data_in = 0x%02h",
                dut.rx_fifo_data_in
            );

            $display(
                "      empty   = %b",
                dut.rx_fifo_empty
            );

            $display(
                "      full    = %b",
                dut.rx_fifo_full
            );

            $display("");

        end

    end


    //################################################################
    // RX FIFO READ DEBUG
    //################################################################
    always @(posedge pclk) begin

        if (presetn && dut.rx_fifo_rd_en) begin

            $display("");
            $display(
                "[%0t] RX FIFO READ",
                $time
            );

            $display(
                "      data_out = 0x%02h",
                dut.rx_fifo_data_out
            );

            $display(
                "      empty    = %b",
                dut.rx_fifo_empty
            );

            $display("");

        end

    end


    //################################################################
    // MAIN TEST
    //################################################################
    initial begin : main_test

        logic [31:0] read_data;

        //========================================================
        // Wait for reset
        //========================================================
        @(posedge presetn);

        $display("");
        $display("");
        $display("################################################");
        $display("#                                              #");
        $display("#          UART RX SMOKE TEST START           #");
        $display("#                                              #");
        $display("################################################");
        $display("");

        //========================================================
        // Wait a little after reset
        //========================================================
        #100;

        //========================================================
        // STEP 1
        //
        // CTRL[0] = enable
        // CTRL[2] = RX enable
        //
        // CTRL = 0b0000_0101 = 0x05
        //========================================================
        $display("");
        $display("-----------------------------------------------");
        $display("STEP 1: ENABLE UART RX");
        $display("-----------------------------------------------");

        apb_write(
            8'h00,
            32'h0000_0005,
            4'b0001
        );

        //========================================================
        // Check CTRL register internally
        //========================================================
        #20;

        $display(
            "[%0t] CTRL REG = 0x%08h",
            $time,
            dut.ctrl_reg
        );

        $display(
            "[%0t] ctrl_enable=%b",
            $time,
            dut.ctrl_enable
        );

        $display(
            "[%0t] ctrl_rx_enable=%b",
            $time,
            dut.ctrl_rx_enable
        );

        //========================================================
        // STEP 2
        //
        // Send UART 0xA3
        //
        // 0xA3 = 1010_0011
        //
        // UART order:
        //
        // START = 0
        // D0    = 1
        // D1    = 1
        // D2    = 0
        // D3    = 0
        // D4    = 0
        // D5    = 1
        // D6    = 0
        // D7    = 1
        // STOP  = 1
        //========================================================
        $display("");
        $display("-----------------------------------------------");
        $display("STEP 2: SEND UART BYTE 0xA3");
        $display("-----------------------------------------------");

        uart_send_byte(8'hA3);

        //========================================================
        // Give RX FIFO some time to update
        //========================================================
        #(BIT_TIME * 2);

        //========================================================
        // STEP 3
        //
        // Check RX FIFO status
        //========================================================
        $display("");
        $display("-----------------------------------------------");
        $display("STEP 3: CHECK RX FIFO");
        $display("-----------------------------------------------");

        $display(
            "[%0t] rx_fifo_empty = %b",
            $time,
            dut.rx_fifo_empty
        );

        $display(
            "[%0t] rx_fifo_full  = %b",
            $time,
            dut.rx_fifo_full
        );

        //========================================================
        // STEP 4
        //
        // APB READ RXDATA = 0x0C
        //========================================================
        $display("");
        $display("-----------------------------------------------");
        $display("STEP 4: READ RXDATA");
        $display("-----------------------------------------------");

        apb_read(
            8'h0C,
            read_data
        );

        //========================================================
        // STEP 5
        //
        // Check received data
        //========================================================
        $display("");
        $display("-----------------------------------------------");
        $display("STEP 5: CHECK RESULT");
        $display("-----------------------------------------------");

        if (read_data[7:0] == 8'hA3) begin

            $display("");
            $display("===============================================");
            $display("             RX SMOKE TEST PASS");
            $display("===============================================");
            $display(
                "Expected = 0xA3"
            );
            $display(
                "Actual   = 0x%02h",
                read_data[7:0]
            );
            $display("===============================================");
            $display("");

        end
        else begin

            $display("");
            $display("===============================================");
            $display("             RX SMOKE TEST FAIL");
            $display("===============================================");
            $display(
                "Expected = 0xA3"
            );
            $display(
                "Actual   = 0x%02h",
                read_data[7:0]
            );
            $display("===============================================");
            $display("");

        end

        //========================================================
        // End simulation
        //========================================================
        #1000;

        $display("");
        $display("################################################");
        $display("#              SIMULATION END                 #");
        $display("################################################");
        $display("");

        $finish;

    end

endmodule