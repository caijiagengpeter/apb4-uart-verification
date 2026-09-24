`ifndef UART_GLOBAL_DISABLE_TX_TEST_SV
`define UART_GLOBAL_DISABLE_TX_TEST_SV

class uart_global_disable_tx_test extends tb_base_test;

    `uvm_component_utils(uart_global_disable_tx_test)


    function new(
        string name = "uart_global_disable_tx_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // Write CTRL helper
    // ============================================================

    virtual task write_ctrl(
        logic [31:0] value,
        string       seq_name
    );

        apb_ctrl_write_sequence ctrl_seq;

        ctrl_seq =
            apb_ctrl_write_sequence::type_id::create(
                seq_name
            );

        ctrl_seq.ctrl_value = value;

        ctrl_seq.start(
            env.apb_agt.sequencer
        );

    endtask


    // ============================================================
    // Check TX_BUSY helper
    // ============================================================

    virtual task check_tx_busy(
        bit    expected_busy,
        string seq_name
    );

        apb_check_tx_busy_sequence busy_seq;

        busy_seq =
            apb_check_tx_busy_sequence::type_id::create(
                seq_name
            );

        busy_seq.expected_busy = expected_busy;

        busy_seq.start(
            env.apb_agt.sequencer
        );

    endtask


    // ============================================================
    // Main test
    //
    // Goal:
    //
    //   ctrl_enable      = 0
    //   ctrl_tx_enable   = 1
    //   tx_fifo_empty    = 0
    //   uart_tx_busy     = 0
    //
    // uart_tx_start must remain LOW.
    //
    // Then enable global control and verify that the queued byte
    // is transmitted normally.
    // ============================================================

    virtual task run_phase(uvm_phase phase);

        uart_tx_multi_sequence tx_seq;


        phase.raise_objection(this);


        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "========== GLOBAL DISABLE BLOCKS QUEUED TX ==========",
            UVM_LOW
        )


        // ========================================================
        // STEP 1
        //
        // Configure:
        //
        // CTRL[0] = 0 : global disable
        // CTRL[1] = 1 : TX enable
        //
        // CTRL = 0x2
        // ========================================================

        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "STEP 1: Setting TX_ENABLE=1 while GLOBAL_ENABLE=0",
            UVM_LOW
        )

        write_ctrl(
            32'h0000_0002,
            "ctrl_global_off_tx_on"
        );


        // ========================================================
        // STEP 2
        //
        // Queue one TX byte while global enable is LOW.
        //
        // TX FIFO should accept the APB write, but UART transmitter
        // must NOT start.
        // ========================================================

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "queued_tx_byte"
            );

        assert(
            tx_seq.randomize() with {

                num_bytes  == 1;
                tx_data[0] == 8'h5A;

            }
        )
        else begin

            `uvm_fatal(
                "UART_GLOBAL_DISABLE_TX_TEST",
                "Failed to randomize TX sequence"
            )

        end


        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "STEP 2: Queuing TX byte 0x5A while global enable is disabled",
            UVM_LOW
        )

        tx_seq.start(
            env.apb_agt.sequencer
        );


        // ========================================================
        // STEP 3
        //
        // Give DUT enough time that TX definitely would have
        // started if global enable gating were broken.
        //
        // One 8N1 frame at 115200 baud is about 86.8 us.
        //
        // Check early AND late to demonstrate TX_BUSY stays LOW.
        // ========================================================

        #20us;

        check_tx_busy(
            1'b0,
            "check_tx_busy_disabled_early"
        );


        // Wait longer than one complete UART frame.
        #100us;

        check_tx_busy(
            1'b0,
            "check_tx_busy_disabled_late"
        );


        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "STEP 3: TX remained idle while global enable was disabled",
            UVM_LOW
        )


        // ========================================================
        // STEP 4
        //
        // Enable global + TX:
        //
        // CTRL = 0x3
        //
        // The byte 0x5A should still be queued in TX FIFO.
        // Once global enable becomes 1, uart_tx_start should assert
        // and transmission should begin.
        // ========================================================

        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "STEP 4: Enabling global control; queued 0x5A should now transmit",
            UVM_LOW
        )

        write_ctrl(
            32'h0000_0003,
            "ctrl_global_on_tx_on"
        );


        // Give TX enough time to enter its active frame.
        #20us;


        // ========================================================
        // STEP 5
        //
        // Confirm transmission actually started.
        // ========================================================

        check_tx_busy(
            1'b1,
            "check_tx_busy_after_enable"
        );


        // ========================================================
        // STEP 6
        //
        // Wait until complete UART frame is observed.
        //
        // Existing TX monitor + scoreboard should produce:
        //
        //   TX data match: 0x5A
        //
        // The scoreboard already queued expected 0x5A when the
        // TXDATA APB write occurred.
        // ========================================================

        #100us;


        // At this point the frame should be complete.
        check_tx_busy(
            1'b0,
            "check_tx_busy_after_completion"
        );


        `uvm_info(
            "UART_GLOBAL_DISABLE_TX_TEST",
            "Queued TX byte successfully transmitted after global enable",
            UVM_LOW
        )


        `uvm_info(
            "TEST_DONE",
            "Global-disable TX gating corner test completed",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask

endclass

`endif