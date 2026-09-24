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
    input logic stat_parity_err,

    // TX FIFO Empty error
    input logic tx_fifo_empty,
    input logic ctrl_tx_enable,
    input logic int_tx_empty_en,
    input logic irq_tx_empty_o,

    // RX FIFO Full error
    //input logic rx_fifo_full, //already have above
    input logic ctrl_rx_enable,
    input logic int_rx_full_en,
    input logic irq_rx_full_o,

/*s    // APB signals
    input logic       psel_i,
    input logic       penable_i,
    input logic       pwrite_i,
    input logic [7:0] paddr_i,
*/
    // RX FIFO empty-read check
    input logic rx_fifo_empty,
    input logic rx_fifo_rd_en,

    // ------------------------------------------------------------
    // APB
    // ------------------------------------------------------------
    //input logic        pclk_i,
    //input logic        presetn_i,

    input logic        psel_i,
    input logic        penable_i,
    input logic        pwrite_i,

    input logic [7:0]  paddr_i,
    input logic [31:0] pwdata_i,

    input logic [3:0]  pstrb_i,
    input logic [2:0]  pprot_i,

    input logic        pready_o,
    input logic        pslverr_o

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

    int unsigned tx_fifo_empty_hit_count  = 0;
    int unsigned tx_fifo_empty_fail_count = 0;
    int unsigned tx_fifo_not_empty_hit_count = 0;

    int unsigned rx_full_irq_high_hit_count = 0;
    int unsigned rx_full_irq_low_hit_count  = 0;
    int unsigned rx_full_irq_fail_count     = 0;

    // APB protocol assertion failures
    int unsigned apb_protocol_fail_count = 0;

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
    // TX FIFO empty assertions
    // ============================================================

    property p_tx_empty_irq_assert;
        @(posedge pclk_i) disable iff (!presetn_i)
        (tx_fifo_empty &&
         ctrl_tx_enable &&
         int_tx_empty_en)
        |-> irq_tx_empty_o;
    endproperty

    a_tx_empty_irq_assert:
        assert property (p_tx_empty_irq_assert)
        else begin
            tx_fifo_empty_fail_count++;

            `uvm_error(
                "SVA_TX_EMPTY_IRQ",
                $sformatf(
                    "TX_EMPTY IRQ assertion failed, fail_count=%0d",
                    tx_fifo_empty_fail_count
                )
            )
        end


    property p_tx_empty_irq_no_spurious;
        @(posedge pclk_i) disable iff (!presetn_i)
        irq_tx_empty_o
        |->
        (tx_fifo_empty &&
         ctrl_tx_enable &&
         int_tx_empty_en);
    endproperty

    a_tx_empty_irq_no_spurious:
        assert property (p_tx_empty_irq_no_spurious)
        else begin
            tx_fifo_empty_fail_count++;

            `uvm_error(
                "SVA_TX_EMPTY_IRQ",
                $sformatf(
                    "Spurious TX_EMPTY IRQ detected, fail_count=%0d",
                    tx_fifo_empty_fail_count
                )
            )
        end

    // ============================================================
    // RX FIFO full assertions
    // ============================================================

    property p_rx_full_irq_assert;
        @(posedge pclk_i) disable iff (!presetn_i)
        (rx_fifo_full &&
         ctrl_rx_enable &&
         int_rx_full_en)
        |-> irq_rx_full_o;
    endproperty


    a_rx_full_irq_assert:
        assert property (p_rx_full_irq_assert)
        else begin

            rx_full_irq_fail_count++;

            `uvm_error(
                "SVA_RX_FULL_IRQ",
                $sformatf(
                    "RX_FULL IRQ was not asserted when RX FIFO was full, fail_count=%0d",
                    rx_full_irq_fail_count
                )
            )

        end

    property p_rx_full_irq_no_spurious;
        @(posedge pclk_i) disable iff (!presetn_i)
        irq_rx_full_o
        |->
        (rx_fifo_full &&
         ctrl_rx_enable &&
         int_rx_full_en);
    endproperty


    a_rx_full_irq_no_spurious:
        assert property (p_rx_full_irq_no_spurious)
        else begin

            rx_full_irq_fail_count++;

            `uvm_error(
                "SVA_RX_FULL_IRQ",
                $sformatf(
                    "Spurious RX_FULL IRQ detected, fail_count=%0d",
                    rx_full_irq_fail_count
                )
            )

        end

    // ============================================================
    // RX FIFO empty and reading it
    // ============================================================

        property p_no_rx_fifo_read_when_empty;
            @(posedge pclk_i)
            disable iff (!presetn_i)

            (psel_i &&
             penable_i &&
             !pwrite_i &&
             (paddr_i == 8'h0C) &&
             rx_fifo_empty)
            |-> !rx_fifo_rd_en;
        endproperty

        a_no_rx_fifo_read_when_empty:
            assert property (p_no_rx_fifo_read_when_empty)
            else begin
                `uvm_error(
                    "UART_SVA",
                    "RX FIFO read enable asserted while FIFO empty"
                )
            end

    // ============================================================
    // APB4 PROTOCOL ASSERTIONS
    // ============================================================
    //
    // These assertions check APB protocol sequencing and signaling.
    //
    // Note:
    //   p_apb_zero_wait_response is DUT-specific.
    //   APB4 itself allows wait states, but this UART slave is
    //   implemented as a zero-wait-state APB slave.
    // ============================================================


    // ============================================================
    // 1. SETUP must be followed by ACCESS
    //
    // SETUP:
    //   PSEL    = 1
    //   PENABLE = 0
    //
    // Next cycle:
    //
    // ACCESS:
    //   PSEL    = 1
    //   PENABLE = 1
    // ============================================================

    property p_apb_setup_to_access;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (psel_i && !penable_i)
        |=>
        (psel_i && penable_i);

    endproperty


    a_apb_setup_to_access:
    assert property (p_apb_setup_to_access)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_SETUP_ACCESS",
            $sformatf(
                "APB protocol violation: SETUP phase was not followed by ACCESS phase, fail_count=%0d",
                apb_protocol_fail_count
            )
        )

    end


    // ============================================================
    // 2. First ACCESS cycle must have a previous SETUP cycle
    //
    // We only check the first ACCESS cycle.
    //
    // In a wait-state transfer PENABLE may remain high for several
    // cycles, so later ACCESS cycles do not require a new SETUP.
    // ============================================================

    property p_apb_access_has_setup;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (
            psel_i &&
            penable_i &&
            !$past(penable_i)
        )
        |->
        $past(psel_i && !penable_i);

    endproperty


    a_apb_access_has_setup:
    assert property (p_apb_access_has_setup)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_ACCESS_SETUP",
            $sformatf(
                "APB protocol violation: ACCESS phase entered without previous SETUP phase, fail_count=%0d",
                apb_protocol_fail_count
            )
        )

    end


    // ============================================================
    // 3. Address/control/data must remain stable during wait state
    //
    // ACCESS + PREADY=0 means the slave extends the transfer.
    //
    // The master must hold:
    //   PADDR
    //   PWRITE
    //   PWDATA
    //   PSTRB
    //   PPROT
    //
    // stable until the transfer progresses.
    //
    // Current DUT is zero-wait, so this antecedent is normally
    // unreachable in the present UART implementation.
    // ============================================================

    property p_apb_stable_during_wait;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (
            psel_i &&
            penable_i &&
            !pready_o
        )
        |=>
        (
            psel_i &&
            penable_i &&

            $stable({
                paddr_i,
                pwrite_i,
                pwdata_i,
                pstrb_i,
                pprot_i
            })
        );

    endproperty


    a_apb_stable_during_wait:
    assert property (p_apb_stable_during_wait)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_WAIT_STABLE",
            $sformatf(
                "APB protocol violation: address/control/data changed during wait state, fail_count=%0d",
                apb_protocol_fail_count
            )
        )

    end


    // ============================================================
    // 4. Completed ACCESS must exit ACCESS next cycle
    //
    // Transfer completion:
    //   PSEL    = 1
    //   PENABLE = 1
    //   PREADY  = 1
    //
    // Next cycle must be either:
    //
    //   IDLE
    //
    // or:
    //
    //   SETUP for next transfer
    //
    // Therefore PENABLE must be LOW next cycle.
    // PSEL is allowed to remain HIGH for back-to-back transfers.
    // ============================================================

    property p_apb_complete_exits_access;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (
            psel_i &&
            penable_i &&
            pready_o
        )
        |=>
        (!penable_i);

    endproperty


    a_apb_complete_exits_access:
    assert property (p_apb_complete_exits_access)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_COMPLETE_EXIT",
            $sformatf(
                "APB protocol violation: PENABLE remained asserted after transfer completion, fail_count=%0d",
                apb_protocol_fail_count
            )
        )

    end


    // ============================================================
    // 5. PSTRB must be inactive during APB reads
    //
    // APB4 PSTRB is meaningful for write transfers.
    //
    // Read:
    //   PWRITE = 0
    //
    // Expected:
    //   PSTRB = 0000
    // ============================================================

    property p_apb_read_pstrb_zero;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (
            psel_i &&
            !pwrite_i
        )
        |->
        (pstrb_i == 4'b0000);

    endproperty


    a_apb_read_pstrb_zero:
    assert property (p_apb_read_pstrb_zero)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_READ_PSTRB",
            $sformatf(
                "APB4 protocol violation: PSTRB active during read transfer, PSTRB=0x%0h fail_count=%0d",
                pstrb_i,
                apb_protocol_fail_count
            )
        )

    end

    // ============================================================
    // 7. DUT-specific zero-wait response
    //
    // IMPORTANT:
    //   This is NOT a general APB4 requirement.
    //
    // APB4 permits:
    //
    //   PREADY = 0
    //
    // to insert wait states.
    //
    // This UART DUT is specifically implemented as zero-wait:
    //
    //   ACCESS -> PREADY = 1
    //
    // Therefore every ACCESS cycle should immediately see PREADY.
    // ============================================================

    property p_apb_zero_wait_response;

        @(posedge pclk_i)
        disable iff (!presetn_i)

        (
            psel_i &&
            penable_i
        )
        |->
        pready_o;

    endproperty


    a_apb_zero_wait_response:
    assert property (p_apb_zero_wait_response)
    else begin

        apb_protocol_fail_count++;

        `uvm_error(
            "SVA_APB_ZERO_WAIT",
            $sformatf(
                "APB DUT violation: zero-wait slave did not assert PREADY during ACCESS, fail_count=%0d",
                apb_protocol_fail_count
            )
        )

    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cover part
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Cover
        // ============================================================================
        // APB4 PROTOCOL COVERAGE
        //
        // Purpose:
        //   Assertions answer: "Did the protocol ever violate a rule?"
        //   Cover properties answer: "Did this scenario actually occur?"
        //
        // NOTE:
        //   This UART implements a zero-wait APB slave:
        //       ACCESS -> PREADY = 1
        //
        //   Therefore:
        //       apb_wait_state_hits == 0
        //
        //   is EXPECTED for the current DUT.
        // ============================================================================


        // ----------------------------------------------------------------------------
        // Coverage hit counters
        // ----------------------------------------------------------------------------

        int unsigned apb_setup_hits             = 0;
        int unsigned apb_access_hits            = 0;
        int unsigned apb_setup_access_hits      = 0;

        int unsigned apb_complete_hits          = 0;
        int unsigned apb_read_complete_hits     = 0;
        int unsigned apb_write_complete_hits    = 0;

        int unsigned apb_back_to_back_hits      = 0;
        int unsigned apb_wait_state_hits        = 0;

        int unsigned apb_pslverr_hits           = 0;

        int unsigned apb_write_strobe_hits      = 0;
        int unsigned apb_partial_strobe_hits    = 0;


        // ============================================================================
        // 1. APB SETUP phase observed
        //
        // SETUP:
        //     PSEL    = 1
        //     PENABLE = 0
        // ============================================================================

        c_apb_setup_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i && !penable_i
        )
        begin
            apb_setup_hits++;
        end


        // ============================================================================
        // 2. APB ACCESS phase observed
        //
        // ACCESS:
        //     PSEL    = 1
        //     PENABLE = 1
        // ============================================================================

        c_apb_access_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i && penable_i
        )
        begin
            apb_access_hits++;
        end


        // ============================================================================
        // 3. Complete SETUP -> ACCESS sequence observed
        //
        //         cycle N       cycle N+1
        //         SETUP   ->     ACCESS
        //
        // PSEL      1              1
        // PENABLE   0              1
        // ============================================================================

        c_apb_setup_to_access_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            (psel_i && !penable_i)
            ##1
            (psel_i && penable_i)
        )
        begin
            apb_setup_access_hits++;
        end


        // ============================================================================
        // 4. Completed APB transfer observed
        //
        // Transfer completion:
        //     PSEL    = 1
        //     PENABLE = 1
        //     PREADY  = 1
        // ============================================================================

        c_apb_transfer_complete_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i &&
            penable_i &&
            pready_o
        )
        begin
            apb_complete_hits++;
        end


        // ============================================================================
        // 5. Completed APB READ observed
        // ============================================================================

        c_apb_read_complete_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i     &&
            penable_i  &&
            pready_o   &&
            !pwrite_i
        )
        begin
            apb_read_complete_hits++;
        end


        // ============================================================================
        // 6. Completed APB WRITE observed
        // ============================================================================

        c_apb_write_complete_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i     &&
            penable_i  &&
            pready_o   &&
            pwrite_i
        )
        begin
            apb_write_complete_hits++;
        end


        // ============================================================================
        // 7. Back-to-back APB transfer observed
        //
        // Transfer #1 completes:
        //
        //     PSEL=1 PENABLE=1 PREADY=1
        //
        // Next cycle immediately becomes SETUP for transfer #2:
        //
        //     PSEL=1 PENABLE=0
        //
        // PSEL is allowed to stay HIGH.
        // PENABLE must return LOW for the next SETUP.
        // ============================================================================

        c_apb_back_to_back_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            (
                psel_i &&
                penable_i &&
                pready_o
            )
            ##1
            (
                psel_i &&
                !penable_i
            )
        )
        begin
            apb_back_to_back_hits++;
        end


        // ============================================================================
        // 8. APB wait state observed
        //
        // ACCESS:
        //     PSEL    = 1
        //     PENABLE = 1
        //     PREADY  = 0
        //
        // Current UART DUT is zero-wait, so this coverage is expected to remain 0.
        // ============================================================================

        c_apb_wait_state_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i &&
            penable_i &&
            !pready_o
        )
        begin
            apb_wait_state_hits++;
        end


        // ============================================================================
        // 9. PSLVERR response observed
        //
        // APB error response is meaningful at completed ACCESS:
        //
        //     PSEL    = 1
        //     PENABLE = 1
        //     PREADY  = 1
        //     PSLVERR = 1
        //
        // apb_unsupported_access_test should hit this.
        // ============================================================================

        c_apb_pslverr_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i      &&
            penable_i   &&
            pready_o    &&
            pslverr_o
        )
        begin
            apb_pslverr_hits++;
        end


        // ============================================================================
        // 10. APB4 write strobe observed
        //
        // Confirms that PSTRB is actually used during APB writes.
        // ============================================================================

        c_apb_write_strobe_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i            &&
            penable_i         &&
            pready_o          &&
            pwrite_i          &&
            (pstrb_i != 4'b0000)
        )
        begin
            apb_write_strobe_hits++;
        end


        // ============================================================================
        // 11. Partial-byte write strobe observed
        //
        // Full 32-bit write:
        //     PSTRB = 1111
        //
        // Partial write examples:
        //     0001
        //     0010
        //     0011
        //     ...
        //
        // This project frequently uses 0001 for byte-wide UART registers.
        // ============================================================================

        c_apb_partial_strobe_seen:
        cover property (
            @(posedge pclk_i)
            disable iff (!presetn_i)

            psel_i             &&
            penable_i          &&
            pready_o           &&
            pwrite_i           &&
            (pstrb_i != 4'b0000) &&
            (pstrb_i != 4'b1111)
        )
        begin
            apb_partial_strobe_hits++;
        end


        // ============================================================================
        // APB4 SVA COVERAGE SUMMARY
        // ============================================================================

        final begin

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "SETUP observed: hits=%0d",
                    apb_setup_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "ACCESS observed: hits=%0d",
                    apb_access_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "SETUP->ACCESS sequence: hits=%0d",
                    apb_setup_access_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "Completed transfers: total=%0d read=%0d write=%0d",
                    apb_complete_hits,
                    apb_read_complete_hits,
                    apb_write_complete_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "Back-to-back transfers: hits=%0d",
                    apb_back_to_back_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "Wait states: hits=%0d (0 expected for zero-wait UART APB slave)",
                    apb_wait_state_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "PSLVERR completed transfers: hits=%0d",
                    apb_pslverr_hits
                ),
                UVM_LOW
            )

            `uvm_info(
                "APB_SVA_COV",
                $sformatf(
                    "APB4 PSTRB writes: hits=%0d partial_write_hits=%0d",
                    apb_write_strobe_hits,
                    apb_partial_strobe_hits
                ),
                UVM_LOW
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
    // Cover: TX FIFO empty error
    // ============================================================

    c_tx_empty_irq_seen:
        cover property (
            @(posedge pclk_i) disable iff (!presetn_i)
            irq_tx_empty_o
        )
        begin
            tx_fifo_empty_hit_count++;
        end

        c_tx_not_empty_irq_low_seen:
    cover property (
            @(posedge pclk_i) disable iff (!presetn_i)
            (!tx_fifo_empty &&
             ctrl_tx_enable &&
             int_tx_empty_en &&
             !irq_tx_empty_o)
        )
        begin
            tx_fifo_not_empty_hit_count++;
        end

    // ============================================================
    // Cover: RX FIFO full error
    // ============================================================
    c_rx_full_irq_rise:
        cover property (
            @(posedge pclk_i) disable iff (!presetn_i)
            $rose(irq_rx_full_o)
        )
        begin
            rx_full_irq_high_hit_count++;
        end

    c_rx_full_irq_fall:
       cover property (
           @(posedge pclk_i) disable iff (!presetn_i)
           $fell(irq_rx_full_o)
       )
       begin
           rx_full_irq_low_hit_count++;
       end

    // ============================================================
    // Cover: RX FIFO empty and reading it
    // ============================================================

        c_rx_read_when_empty:
            cover property (
                @(posedge pclk_i)
                disable iff (!presetn_i)

                psel_i &&
                penable_i &&
                !pwrite_i &&
                (paddr_i == 8'h0C) &&
                rx_fifo_empty
            );

//////////////////////////////////////////////////////////////////////////////////////////////
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


        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "TX_EMPTY IRQ SVA: irq_high_hits=%0d irq_low_hits=%0d fails=%0d",
                tx_fifo_empty_hit_count,
                tx_fifo_not_empty_hit_count,
                tx_fifo_empty_fail_count
            ),
            UVM_LOW
        )

        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "RX_FULL IRQ SVA: irq_rise_hits=%0d irq_fall_hits=%0d fails=%0d",
                rx_full_irq_high_hit_count,
                rx_full_irq_low_hit_count,
                rx_full_irq_fail_count
            ),
            UVM_LOW
        )

        `uvm_info(
            "SVA_SUMMARY",
            $sformatf(
                "APB4 protocol SVA: fails=%0d",
                apb_protocol_fail_count
            ),
            UVM_LOW
        )

    end


endmodule

`endif