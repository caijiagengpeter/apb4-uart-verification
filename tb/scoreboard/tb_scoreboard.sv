`ifndef TB_SCOREBOARD_SV
`define TB_SCOREBOARD_SV

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)

class tb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(tb_scoreboard)

    // ============================================================
    // Expected data queues
    // ============================================================
    logic [7:0] expected_tx_queue[$];
    logic [7:0] expected_rx_queue[$];

    // ============================================================
    // FIFO reference model
    // ============================================================
    localparam int FIFO_DEPTH = 16;

    // TX will be modeled more accurately later
    int unsigned tx_fifo_count = 0;

    // RX occupancy model
    int unsigned rx_fifo_count = 0;

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

    endfunction


    // ============================================================
    // APB transactions
    // ============================================================
    function void write_apb(apb_item tr);

        logic [7:0] expected_data;

        // --------------------------------------------------------
        // TX path
        //
        // APB write TXDATA -> expected UART TX
        //
        // Temporary model:
        // accept only first FIFO_DEPTH bytes.
        // TX occupancy will be modeled more accurately later.
        // --------------------------------------------------------
        if (tr.write &&
            (tr.addr == 8'h08) &&
            tr.strb[0]) begin

            if (expected_tx_queue.size() < FIFO_DEPTH) begin

                expected_tx_queue.push_back(
                    tr.wdata[7:0]
                );

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX expected push: data=0x%02h queue_size=%0d",
                        tr.wdata[7:0],
                        expected_tx_queue.size()
                    ),
                    UVM_HIGH
                )

            end
            else begin

                `uvm_info(
                    "TB_SCOREBOARD",
                    $sformatf(
                        "TX FIFO model full: ignore TXDATA write data=0x%02h",
                        tr.wdata[7:0]
                    ),
                    UVM_MEDIUM
                )

            end

        end


        // --------------------------------------------------------
        // RX path
        //
        // APB read RXDATA -> compare against UART RX expected data
        // --------------------------------------------------------
        if (!tr.write &&
            (tr.addr == 8'h0C)) begin

            if (rx_fifo_count == 0) begin

                `uvm_error(
                    "TB_SCOREBOARD",
                    "RXDATA read while RX FIFO model is empty"
                )

            end
            else begin

                expected_data =
                    expected_rx_queue.pop_front();

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
                            "RX data match: 0x%02h, RX FIFO model count=%0d",
                            tr.rdata[7:0],
                            rx_fifo_count
                        ),
                        UVM_MEDIUM
                    )

                end

            end

        end

    endfunction


    // ============================================================
    // UART TX monitor callback
    // ============================================================
    function void write_uart_tx(uart_item tr);

        logic [7:0] expected_data;

        if (expected_tx_queue.size() == 0) begin

            `uvm_error(
                "TB_SCOREBOARD",
                "Unexpected UART transmission"
            )

            return;

        end

        expected_data =
            expected_tx_queue.pop_front();

        if (tr.data !== expected_data) begin

            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "UART TX data mismatch: expected 0x%02h, got 0x%02h",
                    expected_data,
                    tr.data
                )
            )

        end
        else begin

            `uvm_info(
                "TB_SCOREBOARD",
                $sformatf(
                    "UART TX data match: 0x%02h",
                    tr.data
                ),
                UVM_MEDIUM
            )

        end

    endfunction


    // ============================================================
    // UART RX monitor callback
    // ============================================================
    function void write_uart_rx(uart_item tr);

        // DUT RX FIFO still has space
        if (rx_fifo_count < FIFO_DEPTH) begin

            expected_rx_queue.push_back(
                tr.data
            );

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

        // DUT RX FIFO already full
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

    endfunction


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

    endfunction

endclass

`endif