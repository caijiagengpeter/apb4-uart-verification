`ifndef UART_ASSERTIONS_SV
`define UART_ASSERTIONS_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


module uart_assertions (

    input logic pclk_i,
    input logic presetn_i,

    // RX overrun
    input logic uart_rx_done,
    input logic rx_fifo_full,
    input logic stat_overrun_err,

    // RX frame error
    input logic uart_rx_frame_err,
    input logic stat_frame_err,

    // RX parity error
    input logic uart_rx_parity_err,
    input logic stat_parity_err

);


    // ============================================================
    // Counters
    // ============================================================

    int unsigned rx_overrun_hit_count   = 0;
    int unsigned rx_overrun_fail_count  = 0;

    int unsigned rx_error_hit_count     = 0;
    int unsigned rx_error_fail_count    = 0;

    int unsigned rx_parity_hit_count    = 0;
    int unsigned rx_parity_fail_count   = 0;


    // ============================================================
    // RX overrun assertions
    // ============================================================

    property p_rx_overrun_assert;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (uart_rx_done && rx_fifo_full)
        |-> stat_overrun_err;

    endproperty


    a_rx_overrun_assert:
        assert property (p_rx_overrun_assert)

        else begin

            rx_overrun_fail_count++;

            `uvm_error(
                "SVA_RX_OVERRUN",
                $sformatf(
                    "RX overrun assertion failed, fail_count=%0d",
                    rx_overrun_fail_count
                )
            )

        end


    // ------------------------------------------------------------
    // No spurious overrun status
    // ------------------------------------------------------------

    property p_rx_overrun_no_spurious;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        stat_overrun_err
        |-> (uart_rx_done && rx_fifo_full);

    endproperty


    a_rx_overrun_no_spurious:
        assert property (p_rx_overrun_no_spurious)

        else begin

            rx_overrun_fail_count++;

            `uvm_error(
                "SVA_RX_OVERRUN_NO_SPURIOUS",
                $sformatf(
                    "stat_overrun_err asserted without uart_rx_done && rx_fifo_full, fail_count=%0d",
                    rx_overrun_fail_count
                )
            )

        end


    // ============================================================
    // RX frame error assertions
    // ============================================================

    property p_rx_error_assert;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        uart_rx_frame_err
        |-> stat_frame_err;

    endproperty


    a_rx_error_assert:
        assert property (p_rx_error_assert)

        else begin

            rx_error_fail_count++;

            `uvm_error(
                "SVA_RX_FRAME_ERROR",
                $sformatf(
                    "RX frame error propagation failed, fail_count=%0d",
                    rx_error_fail_count
                )
            )

        end


    // ------------------------------------------------------------
    // No spurious frame error status
    // ------------------------------------------------------------

    property p_rx_error_no_spurious;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        stat_frame_err
        |-> uart_rx_frame_err;

    endproperty


    a_rx_error_no_spurious:
        assert property (p_rx_error_no_spurious)

        else begin

            rx_error_fail_count++;

            `uvm_error(
                "SVA_RX_FRAME_ERROR_NO_SPURIOUS",
                $sformatf(
                    "stat_frame_err asserted without uart_rx_frame_err, fail_count=%0d",
                    rx_error_fail_count
                )
            )

        end


    // ------------------------------------------------------------
    // Frame error must not generate RX done
    // ------------------------------------------------------------

    property p_rx_frame_error_no_done;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        uart_rx_frame_err
        |-> !uart_rx_done;

    endproperty


    a_rx_frame_error_no_done:
        assert property (p_rx_frame_error_no_done)

        else begin

            rx_error_fail_count++;

            `uvm_error(
                "SVA_RX_FRAME_ERROR_NO_DONE",
                $sformatf(
                    "RX frame error occurred but uart_rx_done was also asserted, fail_count=%0d",
                    rx_error_fail_count
                )
            )

        end


    // ============================================================
    // RX parity error assertions
    // ============================================================

    property p_rx_parity_error_assert;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        uart_rx_parity_err
        |-> stat_parity_err;

    endproperty


    a_rx_parity_error_assert:
        assert property (p_rx_parity_error_assert)

        else begin

            rx_parity_fail_count++;

            `uvm_error(
                "SVA_RX_PARITY_ERROR",
                $sformatf(
                    "RX parity error propagation failed, fail_count=%0d",
                    rx_parity_fail_count
                )
            )

        end


    // ------------------------------------------------------------
    // No spurious parity error status
    // ------------------------------------------------------------

    property p_rx_parity_error_no_spurious;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        stat_parity_err
        |-> uart_rx_parity_err;

    endproperty


    a_rx_parity_error_no_spurious:
        assert property (p_rx_parity_error_no_spurious)

        else begin

            rx_parity_fail_count++;

            `uvm_error(
                "SVA_RX_PARITY_ERROR_NO_SPURIOUS",
                $sformatf(
                    "stat_parity_err asserted without uart_rx_parity_err, fail_count=%0d",
                    rx_parity_fail_count
                )
            )

        end


    // ============================================================
    // Cover: RX overrun
    // ============================================================

    c_rx_overrun_seen:
        cover property (

            @(posedge pclk_i)
            disable iff (!presetn_i)

            (uart_rx_done && rx_fifo_full)

        )

        begin

            rx_overrun_hit_count++;

            `uvm_info(
                "SVA_RX_OVERRUN",
                $sformatf(
                    "RX overrun condition observed, hit_count=%0d",
                    rx_overrun_hit_count
                ),
                UVM_MEDIUM
            )

        end


    // ============================================================
    // Cover: RX frame error
    // ============================================================

    c_rx_error_seen:
        cover property (

            @(posedge pclk_i)
            disable iff (!presetn_i)

            uart_rx_frame_err

        )

        begin

            rx_error_hit_count++;

            `uvm_info(
                "SVA_RX_FRAME_ERROR",
                $sformatf(
                    "RX frame error observed, hit_count=%0d",
                    rx_error_hit_count
                ),
                UVM_MEDIUM
            )

        end


    // ============================================================
    // Cover: RX parity error
    // ============================================================

    c_rx_parity_error_seen:
        cover property (

            @(posedge pclk_i)
            disable iff (!presetn_i)

            uart_rx_parity_err

        )

        begin

            rx_parity_hit_count++;

            `uvm_info(
                "SVA_RX_PARITY_ERROR",
                $sformatf(
                    "RX parity error observed, hit_count=%0d",
                    rx_parity_hit_count
                ),
                UVM_MEDIUM
            )

        end


    // ============================================================
    // Confirm assertion module is active
    // ============================================================

    initial begin

        $display(
            "[%0t] uart_assertions module active",
            $time
        );

    end


    // ============================================================
    // SVA summary
    // ============================================================

    final begin

        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "RX overrun SVA: hits=%0d fails=%0d",
                rx_overrun_hit_count,
                rx_overrun_fail_count
            ),
            UVM_LOW
        )


        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "RX frame error SVA: hits=%0d fails=%0d",
                rx_error_hit_count,
                rx_error_fail_count
            ),
            UVM_LOW
        )


        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "RX parity error SVA: hits=%0d fails=%0d",
                rx_parity_hit_count,
                rx_parity_fail_count
            ),
            UVM_LOW
        )

    end


endmodule

`endif