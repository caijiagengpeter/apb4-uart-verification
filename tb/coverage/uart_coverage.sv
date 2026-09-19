`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV


`uvm_analysis_imp_decl(_frame_error)
`uvm_analysis_imp_decl(_overrun)
`uvm_analysis_imp_decl(_fifo_state)
`uvm_analysis_imp_decl(_fifo_corner)
`uvm_analysis_imp_decl(_irq)

class uart_coverage extends uvm_subscriber #(uart_item);

    `uvm_component_utils(uart_coverage)

    // 后面继续声明各种 analysis imp / covergroup / 变量
    uart_item tr;


    localparam int FIFO_DEPTH = 16;
    bit parity_error_sample;
    bit frame_error_sample;
    bit overrun_error_sample = 1'b0;
    int unsigned tx_fifo_count_sample;
    int unsigned rx_fifo_count_sample;
    bit tx_write_full_event;
    bit rx_receive_full_event;
    bit rx_read_empty_event;

    uvm_analysis_imp_frame_error #(
        uart_item,
        uart_coverage
    ) frame_error_imp;

    uvm_analysis_imp_overrun #(
        uart_status_item,
        uart_coverage
    ) overrun_imp;

    uvm_analysis_imp_fifo_state #(
        fifo_state_item,
        uart_coverage
    ) fifo_state_imp;

    uvm_analysis_imp_fifo_corner #(
        fifo_corner_item,
        uart_coverage
    ) fifo_corner_imp;

    uvm_analysis_imp_irq #(
        uart_status_item,
        uart_coverage
    ) irq_imp;


    bit tx_empty_irq_sample = 1'b0;
    bit rx_full_irq_sample  = 1'b0;

    // ============================================================
    // RX functional coverage
    // ============================================================
    covergroup uart_rx_cg;

        cp_parity_en: coverpoint tr.parity_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_parity_odd: coverpoint tr.parity_odd {
            bins even = {0};
            bins odd  = {1};
        }

        cp_parity_bit: coverpoint tr.parity_bit {
            bins zero = {0};
            bins one  = {1};
        }

        cp_parity_error: coverpoint parity_error_sample
                         iff (tr.parity_en) {
            bins good  = {0};
            bins error = {1};
        }

        cross_parity_mode:
            cross cp_parity_en, cp_parity_odd {
                ignore_bins parity_disabled_odd =
                    binsof(cp_parity_en) intersect {0} &&
                    binsof(cp_parity_odd) intersect {1};
            }

        cross_parity_mode_error:
            cross cp_parity_odd, cp_parity_error
            iff (tr.parity_en);

    endgroup


    // ============================================================
    // RX error coverage
    // ============================================================
    covergroup uart_error_cg;

        cp_frame_error: coverpoint frame_error_sample {
            bins error = {1};
        }

        cp_overrun_error: coverpoint overrun_error_sample {
            bins error = {1};
        }

    endgroup

    // ============================================================
    // FIFO coverage
    // ============================================================

    covergroup uart_fifo_cg;

        cp_tx_fifo_count: coverpoint tx_fifo_count_sample {
            bins empty  = {0};
            bins middle = {[1:FIFO_DEPTH-1]};
            bins full   = {FIFO_DEPTH};
        }

        cp_rx_fifo_count: coverpoint rx_fifo_count_sample {
            bins empty  = {0};
            bins middle = {[1:FIFO_DEPTH-1]};
            bins full   = {FIFO_DEPTH};
        }

    endgroup

    covergroup uart_fifo_corner_cg;

        cp_tx_write_full: coverpoint tx_write_full_event {
            bins hit = {1};
        }

        cp_rx_receive_full: coverpoint rx_receive_full_event {
            bins hit = {1};
        }

        cp_rx_read_empty: coverpoint rx_read_empty_event {
            bins hit = {1};
        }

    endgroup


    // ============================================================
    // IRQ coverage
    // ============================================================

    covergroup uart_irq_cg;

        cp_tx_empty_irq: coverpoint tx_empty_irq_sample {
            bins asserted = {1};
        }

        cp_rx_full_irq: coverpoint rx_full_irq_sample {
            bins asserted = {1};
        }

    endgroup

    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "uart_coverage",
        uvm_component parent = null
    );
        super.new(name, parent);

        frame_error_imp = new("frame_error_imp", this);
        overrun_imp     = new("overrun_imp", this);
        fifo_state_imp  = new("fifo_state_imp", this);
        fifo_corner_imp = new("fifo_corner_imp", this);
        irq_imp         = new("irq_imp", this);

        uart_rx_cg          = new();
        uart_error_cg       = new();
        uart_fifo_cg        = new();
        uart_fifo_corner_cg = new();
        uart_irq_cg         = new();
    endfunction

    // ============================================================
    // Normal RX transaction
    // ============================================================
    function void write(uart_item t);

        tr = t;

        if (tr.parity_en) begin

            if (tr.parity_odd)
                parity_error_sample =
                    (tr.parity_bit !== ~^tr.data);
            else
                parity_error_sample =
                    (tr.parity_bit !== ^tr.data);

        end
        else begin

            parity_error_sample = 1'b0;

        end

        uart_rx_cg.sample();

    endfunction


    // ============================================================
    // Frame error event
    // ============================================================
    function void write_frame_error(uart_item t);

        frame_error_sample = 1'b1;

        uart_error_cg.sample();

    endfunction

    // ============================================================
    // Overrun error event
    // ============================================================

    function void write_overrun(uart_status_item t);

        if (!t.overrun_error)
            return;

        overrun_error_sample = t.overrun_error;

        uart_error_cg.sample();

    endfunction

    // ============================================================
    // FIFO test event
    // ============================================================

    function void write_fifo_state(fifo_state_item t);

        tx_fifo_count_sample = t.tx_count;
        rx_fifo_count_sample = t.rx_count;

        uart_fifo_cg.sample();

    endfunction

    function void write_fifo_corner(fifo_corner_item t);

        tx_write_full_event   = t.tx_write_full;
        rx_receive_full_event = t.rx_receive_full;
        rx_read_empty_event   = t.rx_read_empty;

        uart_fifo_corner_cg.sample();

    endfunction

    function void write_irq(uart_status_item t);

        if (!t.tx_empty_irq &&
            !t.rx_full_irq)
            return;

        tx_empty_irq_sample = t.tx_empty_irq;
        rx_full_irq_sample  = t.rx_full_irq;

        uart_irq_cg.sample();

    endfunction

endclass

`endif