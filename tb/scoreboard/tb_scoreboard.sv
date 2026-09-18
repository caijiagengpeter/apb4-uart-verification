/*
write_apb()
    ├─ TXDATA model
    ├─ RXDATA compare
    └─ STAT compare

write_uart_tx_start()
    └─ TX FIFO dequeue / TX_BUSY=1

write_uart_tx()
    └─ TX data compare / TX_BUSY=0

write_uart_rx_start()
    └─ RX_BUSY=1

write_uart_rx()
    ├─ parity reference check
    ├─ RX FIFO model push
    └─ RX_BUSY=0

check_phase()
    └─ end-of-test consistency
*/

`ifndef TB_SCOREBOARD_SV
`define TB_SCOREBOARD_SV

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)
`uvm_analysis_imp_decl(_uart_tx_start)
`uvm_analysis_imp_decl(_uart_rx_start)

class tb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(tb_scoreboard)

    // ============================================================
    // Expected data queues
    // ============================================================
    logic [7:0] expected_tx_queue[$];
    logic [7:0] expected_rx_queue[$];
    logic       expected_tx_full;
    logic       expected_rx_empty;

    // ============================================================
    // FIFO reference model
    // ============================================================
    localparam int FIFO_DEPTH = 16;

    // TX will be modeled more accurately later
    int unsigned tx_fifo_count = 0;

    // RX occupancy model
    int unsigned rx_fifo_count = 0;

    // STAT model
    int unsigned stat_check_count = 0;

    // STAT bit[0] for TX
    logic expected_tx_busy = 1'b0;

    // STAT bit[1] for RX
    logic expected_rx_busy = 1'b0;

    //STAT bit[4] for RX
    int unsigned parity_good_count = 0;
    int unsigned parity_error_count = 0;

    // STAT CHECK switch
    bit require_stat_check = 1'b0;

    // ============================================================
    // Analysis implementations
    // ============================================================
    uvm_analysis_imp_apb #(
        apb_item,
        tb_scoreboard
    ) apb_imp;

    uvm_analysis_imp_uart_tx #(
        uart_item,
        tb_scoreboard
    ) uart_imp_tx;

    uvm_analysis_imp_uart_rx #(
        uart_item,
        tb_scoreboard
    ) uart_imp_rx;

    uvm_analysis_imp_uart_tx_start #(
        uart_item,
        tb_scoreboard
    ) uart_imp_tx_start;

    uvm_analysis_imp_uart_rx_start #(
        uart_item,
        tb_scoreboard
    ) uart_imp_rx_start;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "tb_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        apb_imp     = new("apb_imp", this);
        uart_imp_tx = new("uart_imp_tx", this);
        uart_imp_rx = new("uart_imp_rx", this);
        uart_imp_tx_start = new("uart_imp_tx_start", this);
        uart_imp_rx_start = new("uart_imp_rx_start", this);

    endfunction


    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(bit)::get(
            this,
            "",
            "require_stat_check",
            require_stat_check
        ));

    endfunction




    // ============================================================
    // APB transactions
    // ============================================================
    function void write_apb(apb_item tr);

    logic [7:0] expected_data;

    // ========================================================
    // TX: APB write TXDATA
    // ========================================================
        if (tr.write &&
            (tr.addr == 8'h08) &&
            tr.strb[0]) begin

            if (tx_fifo_count < FIFO_DEPTH) begin

                expected_tx_queue.push_back(tr.wdata[7:0]);
                tx_fifo_count++;

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX FIFO model push: data=0x%02h count=%0d",
                        tr.wdata[7:0],
                        tx_fifo_count
                    ),
                    UVM_HIGH
                )

            end
            else begin

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX FIFO model full: reject data=0x%02h",
                        tr.wdata[7:0]
                    ),
                    UVM_MEDIUM
                )

            end

        end


    // ========================================================
    // RX: APB read RXDATA
    // ========================================================
        if (!tr.write &&
            (tr.addr == 8'h0C)) begin

            if (rx_fifo_count == 0) begin

                `uvm_error(
                    "TB_SCOREBOARD",
                    "RXDATA read while RX FIFO model is empty"
                )

            end
            else begin

                expected_data = expected_rx_queue.pop_front();

                rx_fifo_count--;

                if (tr.rdata[7:0] !== expected_data) begin

                    `uvm_error(
                        "TB_SCOREBOARD",
                        $sformatf(
                            "RX data mismatch: expected 0x%02h, got 0x%02h",
                            expected_data,
                            tr.rdata[7:0]
                        )
                    )

                end
                else begin

                    `uvm_info(
                        "TB_SCOREBOARD",
                        $sformatf(
                            "RX data match: 0x%02h, RX FIFO count=%0d",
                            tr.rdata[7:0],
                            rx_fifo_count
                        ),
                        UVM_MEDIUM
                    )

                end

            end

        end

    // ========================================================
    // APB Check the expected_tx_full and expected_rx_empty
    // ========================================================
    if (!tr.write && tr.addr == 8'h04) begin

        stat_check_count++;// count check

        expected_tx_full  = (tx_fifo_count == FIFO_DEPTH);
        expected_rx_empty = (rx_fifo_count == 0);

        if (tr.rdata[2] !== expected_tx_full) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "TX_FULL mismatch: expected=%0b actual=%0b tx_count=%0d",
                    expected_tx_full,
                    tr.rdata[2],
                    tx_fifo_count
                )
            )
        end

        if (tr.rdata[3] !== expected_rx_empty) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "RX_EMPTY mismatch: expected=%0b actual=%0b rx_count=%0d",
                    expected_rx_empty,
                    tr.rdata[3],
                    rx_fifo_count
                )
            )
        end



      if (tr.rdata[0] !== expected_tx_busy) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "TX_BUSY mismatch: expected=%0b actual=%0b",
                    expected_tx_busy,
                    tr.rdata[0]
                )
            )
        end

        if (tr.rdata[1] !== expected_rx_busy) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "RX_BUSY mismatch: expected=%0b actual=%0b",
                    expected_rx_busy,
                    tr.rdata[1]
                )
            )
        end

    end
    endfunction

    // ============================================================
    // UART RX monitor callback
    // ============================================================

    function void write_uart_tx(uart_item tr);

        logic [7:0] expected_data;

        if (expected_tx_queue.size() == 0) begin

            `uvm_error(
                "TB_SCOREBOARD",
                "UART TX completed but expected TX queue is empty"
            )

        end
        else begin

            expected_data = expected_tx_queue.pop_front();

            if (tr.data !== expected_data) begin

                `uvm_error(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX data mismatch: expected=0x%02h actual=0x%02h",
                        expected_data,
                        tr.data
                    )
                )

            end
            else begin

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX data match: 0x%02h",
                        tr.data
                    ),
                    UVM_MEDIUM
                )

            end

        end

        expected_tx_busy = 1'b0;

    endfunction

    // ============================================================
    // UART RX monitor callback
    // ============================================================
    function void write_uart_rx(uart_item tr);

        bit expected_parity;

        // ========================================================
        // 1. Parity reference checking
        // ========================================================
        if (tr.parity_en) begin

            if(tr.parity_odd) begin
                expected_parity = ~^tr.data;
            end
            // 8E1: even parity
            else begin
                expected_parity = ^tr.data;
            end

            if (tr.parity_bit !== expected_parity) begin

                parity_error_count++;

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "RX parity error: data=0x%02h expected=%0b actual=%0b error_count=%0d",
                        tr.data,
                        expected_parity,
                        tr.parity_bit,
                        parity_error_count
                    ),
                    UVM_MEDIUM
                )

            end
            else begin

                parity_good_count++;

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "RX parity correct: data=0x%02h parity=%0b good_count=%0d",
                        tr.data,
                        tr.parity_bit,
                        parity_good_count
                    ),
                    UVM_MEDIUM
                )

            end

        end


        // ========================================================
        // 2. RX FIFO reference model
        //
        // Current DUT behavior:
        // parity error does NOT drop received data.
        // ========================================================
        if (rx_fifo_count < FIFO_DEPTH) begin

            expected_rx_queue.push_back(tr.data);
            rx_fifo_count++;

            `uvm_info(
                "TB_SCOREBOARD",
                $sformatf(
                    "RX FIFO model push: data=0x%02h count=%0d",
                    tr.data,
                    rx_fifo_count
                ),
                UVM_HIGH
            )

        end
        else begin

            `uvm_info(
                "TB_SCOREBOARD",
                $sformatf(
                    "RX FIFO model full: drop data=0x%02h",
                    tr.data
                ),
                UVM_MEDIUM
            )

        end


        // ========================================================
        // 3. RX frame completed
        // ========================================================
        expected_rx_busy = 1'b0;

    endfunction
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////


        function void write_uart_tx_start(uart_item tr);
            expected_tx_busy = 1'b1;

            if (tx_fifo_count == 0) begin

                `uvm_error(
                    "TB_SCOREBOARD",
                    "UART TX started while TX FIFO model is empty"
                )

            end
            else begin

                tx_fifo_count--;

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX FIFO model pop at frame start: count=%0d",
                        tx_fifo_count
                    ),
                    UVM_HIGH
                )

            end

        endfunction

    // ============================================================
    // UART RX monitor callback
    // ============================================================

//////////////////////////////////////////////////////////////////function receive the start, means the rx_busy = 1'b1;
    function void write_uart_rx_start(uart_item tr);
        expected_rx_busy = 1'b1;
    endfunction




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================================================
    // End-of-test checks
    // ============================================================
    function void check_phase(uvm_phase phase);

        super.check_phase(phase);

        // --------------------------------------------------------
        // TX expected queue must be empty
        // --------------------------------------------------------
        if (expected_tx_queue.size() != 0) begin

            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "Unmatched TX data remains in queue: %0d item(s)",
                    expected_tx_queue.size()
                )
            )

        end


        // --------------------------------------------------------
        // RX expected queue must be empty
        // --------------------------------------------------------
        if (expected_rx_queue.size() != 0) begin

            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "Unmatched RX data remains in queue: %0d item(s)",
                    expected_rx_queue.size()
                )
            )

        end


        // --------------------------------------------------------
        // RX FIFO model should also be empty
        // --------------------------------------------------------
        if (rx_fifo_count != 0) begin

            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "RX FIFO model count is not zero at end of test: %0d",
                    rx_fifo_count
                )
            )

        end

        if (tx_fifo_count != 0) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "TX FIFO model count is not zero at end of test: %0d",
                    tx_fifo_count
                )
            )
        end

        if (require_stat_check && (stat_check_count == 0)) begin

            `uvm_error(
                "TB_SCOREBOARD",
                "No STAT register check was performed"
            )

        end

    endfunction

endclass

`endif