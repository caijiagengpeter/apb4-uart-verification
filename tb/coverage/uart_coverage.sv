/*
有没有跑 parity disabled / enabled？
有没有跑 even / odd？
实际 parity bit 有没有出现 0 / 1？
*/

`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber #(uart_item);

    `uvm_component_utils(uart_coverage)

    uart_item tr;

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

        cross_parity_mode: cross cp_parity_en, cp_parity_odd {

            ignore_bins parity_disabled_odd =
                binsof(cp_parity_en) intersect {0} &&
                binsof(cp_parity_odd) intersect {1};

        }

    endgroup


    function new(
        string name = "uart_coverage",
        uvm_component parent = null
    );
        super.new(name, parent);

        uart_rx_cg = new();
    endfunction


    function void write(uart_item t);

        tr = t;

        uart_rx_cg.sample();

        `uvm_info(
            "UART_COVERAGE",
            $sformatf(
                "Sampling RX coverage: data=0x%02h parity_en=%0b parity_odd=%0b parity_bit=%0b",
                t.data,
                t.parity_en,
                t.parity_odd,
                t.parity_bit
            ),
            UVM_HIGH
        )

    endfunction

endclass

`endif