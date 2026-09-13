`ifndef TB_SCOREBOARD_SV
`define TB_SCOREBOARD_SV

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)

class tb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(tb_scoreboard)

    logic [7:0] expected_tx_queue[$];
    logic [7:0] expected_rx_queue[$];

    uvm_analysis_imp_apb  #(apb_item,  tb_scoreboard) apb_imp;
    uvm_analysis_imp_uart_tx #(uart_item, tb_scoreboard) uart_imp_tx;
    uvm_analysis_imp_uart_rx #(uart_item, tb_scoreboard) uart_imp_rx;

    function new(string name = "tb_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);

        apb_imp  = new("apb_imp", this);
        uart_imp_tx = new("uart_imp_tx", this);
        uart_imp_rx = new("uart_imp_rx", this);
    endfunction

///////////////////////////////////////////////////////////////
 function void write_apb(apb_item tr);

        // TX: APB write TXDATA → expected TX
        if (tr.write &&
            (tr.addr == 8'h08) &&
            tr.strb[0]) begin
            if(expected_tx_queue.size() < 16)begin
                expected_tx_queue.push_back(tr.wdata[7:0]);
            end
        end
//////////////////////////////////////////////////////////////////////////////
        // RX: APB read RXDATA → actual RX
        else if (!tr.write &&
                 (tr.addr == 8'h0C)) begin

            logic [7:0] expected_data;

            if (expected_rx_queue.size() == 0) begin
                `uvm_error(
                    "TB_SCOREBOARD",
                    "Unexpected APB RXDATA read"
                )
                return;
            end

            expected_data = expected_rx_queue.pop_front();

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
                        "RX data match: 0x%02h",
                        tr.rdata[7:0]
                    ),
                    UVM_MEDIUM
                )
            end

        end

    endfunction

//////////////////////////////////////////////////////////////

    function void write_uart_tx(uart_item tr);

        logic [7:0] expected_data;

        if (expected_tx_queue.size() == 0) begin
            `uvm_error("TB_SCOREBOARD", "Unexpected UART transmission")
            return;
        end

        expected_data = expected_tx_queue.pop_front();

        if (tr.data !== expected_data) begin
            `uvm_error("TB_SCOREBOARD",
                $sformatf("UART data mismatch: expected 0x%02h, got 0x%02h",
                          expected_data, tr.data))
        end
        else begin
            `uvm_info("TB_SCOREBOARD",
                $sformatf("UART data match: 0x%02h", tr.data),
                UVM_MEDIUM)
        end

    endfunction
///////////////////////////////////////////////////////////////
    function void write_uart_rx(uart_item tr);

        expected_rx_queue.push_back(tr.data);

    endfunction

////////////////////////////////////////////////////////////////


    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        if (expected_tx_queue.size() != 0) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "Unmatched TX data remains in queue: %0d item(s)",
                    expected_tx_queue.size()
                )
            )
        end

        if (expected_rx_queue.size() != 0) begin
            `uvm_error(
                "TB_SCOREBOARD",
                $sformatf(
                    "Unmatched RX data remains in queue: %0d item(s)",
                    expected_rx_queue.size()
                )
            )
        end

    endfunction

//////////////////////////////////////////////////////////////
endclass

`endif
