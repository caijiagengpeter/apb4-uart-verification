module tb_top;

    //============================================================
    // Clock / Reset
    //============================================================
    logic pclk;
    logic presetn;

    //============================================================
    // APB4 Interface
    //============================================================
    logic [7:0]  paddr;
    logic [31:0] pwdata;
    logic        pwrite;
    logic        penable;
    logic        psel;

    logic [3:0]  pstrb;
    logic [2:0]  pprot;

    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;

    //============================================================
    // UART Interface
    //============================================================
    logic rxd;
    logic txd;

    //============================================================
    // Interrupts
    //============================================================
    logic irq_tx_empty;
    logic irq_rx_full;

    //============================================================
    // Clock Generation
    // 50 MHz -> 20 ns period
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
    // Initial Signal Values
    //============================================================
    initial begin
        paddr   = 8'h00;
        pwdata  = 32'h0000_0000;
        pwrite  = 1'b0;
        penable = 1'b0;
        psel    = 1'b0;

        // APB4
        pstrb   = 4'b0000;
        pprot   = 3'b000;

        // UART idle state = logic 1
        rxd     = 1'b1;
    end

    //============================================================
    // DUT
    //============================================================
    uart_controller dut (
        // Clock / Reset
        .pclk_i         (pclk),
        .presetn_i      (presetn),

        // APB4
        .psel_i         (psel),
        .penable_i      (penable),
        .pwrite_i       (pwrite),
        .paddr_i        (paddr),
        .pwdata_i       (pwdata),
        .pstrb_i        (pstrb),
        .pprot_i        (pprot),

        .prdata_o       (prdata),
        .pready_o       (pready),
        .pslverr_o      (pslverr),

        // UART
        .uart_tx_o      (txd),
        .uart_rx_i      (rxd),

        // Interrupts
        .irq_tx_empty_o (irq_tx_empty),
        .irq_rx_full_o  (irq_rx_full)
    );

    //============================================================
    // Simulation Control
    //============================================================
    initial begin

        $display("========================================");
        $display(" UART RTL MINIMUM TEST START");
        $display("========================================");

        #500;

        $display("========================================");
        $display(" UART RTL MINIMUM TEST END");
        $display("========================================");

        $finish;
    end

endmodule