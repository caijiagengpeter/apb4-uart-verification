`ifndef UART_TX_RESET_TEST_SV
`define UART_TX_RESET_TEST_SV

class uart_tx_reset_test extends tb_base_test;

    `uvm_component_utils(uart_tx_reset_test)

    virtual apb_if.RESET reset_vif;


    function new(
        string name = "uart_tx_reset_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // Build phase
    // ============================================================

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if.RESET)::get(
                this,
                "",
                "reset_vif",
                reset_vif
            )) begin

            `uvm_fatal(
                "UART_TX_RESET_TEST",
                "Failed to get reset_vif"
            )

        end

    endfunction


    // ============================================================
    // Reset helper
    // ============================================================

    virtual task apply_reset();

        `uvm_info(
            "UART_TX_RESET_TEST",
            "Asserting runtime reset",
            UVM_LOW
        )

        reset_vif.PRESETn = 1'b0;

        repeat (3)
            @(posedge reset_vif.PCLK);

        reset_vif.PRESETn = 1'b1;

        @(posedge reset_vif.PCLK);

        `uvm_info(
            "UART_TX_RESET_TEST",
            "Runtime reset released",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Case 1
    //
    // Data is already stored in TX FIFO,
    // but TX transmitter is disabled.
    //
    // Reset must remove the stale FIFO byte.
    // ============================================================

    virtual task reset_with_data_in_tx_fifo();

        apb_enable             seq_en;
        apb_tx_enable          tx_en;
        uart_tx_multi_sequence tx_seq;

        `uvm_info(
            "UART_TX_RESET_TEST",
            "========== CASE 1: RESET WITH DATA IN TX FIFO ==========",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 1. Enable global UART only.
        //
        // CTRL:
        // enable    = 1
        // tx_enable = 0
        //
        // Therefore TX FIFO can receive data, but transmitter
        // must not remove/send it.
        // --------------------------------------------------------

        seq_en = apb_enable::type_id::create("case1_seq_en");

        seq_en.start(
            env.apb_agt.sequencer
        );


        // --------------------------------------------------------
        // 2. Put a known byte into TX FIFO.
        // --------------------------------------------------------

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "case1_tx_seq"
            );

        assert(
            tx_seq.randomize() with {
                num_bytes  == 1;
                tx_data[0] == 8'h5A;
            }
        )
        else begin

            `uvm_fatal(
                "UART_TX_RESET_TEST",
                "CASE 1 TX sequence randomization failed"
            )

        end


        `uvm_info(
            "UART_TX_RESET_TEST",
            "CASE 1: Loading 0x5A into TX FIFO while TX is disabled",
            UVM_LOW
        )

        tx_seq.start(
            env.apb_agt.sequencer
        );


        // --------------------------------------------------------
        // 3. Reset while byte is still waiting in FIFO.
        //
        // Scoreboard reset_model() should also clear its
        // expected TX queue here.
        // --------------------------------------------------------

        apply_reset();


        // --------------------------------------------------------
        // 4. Re-enable UART + TX.
        //
        // Important:
        // If reset FAILED to clear TX FIFO, old 0x5A would now
        // start transmitting.
        //
        // Scoreboard currently expects nothing, therefore any
        // stale transmission should become an unexpected-TX error.
        // --------------------------------------------------------

        tx_en =
            apb_tx_enable::type_id::create(
                "case1_tx_enable"
            );

        tx_en.start(
            env.apb_agt.sequencer
        );


        // Wait longer than one normal 8N1 UART frame.
        // At 115200 baud one frame is ~87 us.
        //
        // If stale 0x5A survived reset, it should appear here
        // and scoreboard should report an unexpected TX.
        #120us;


        // --------------------------------------------------------
        // 5. Post-reset recovery:
        // Send NEW byte 0xA5.
        // --------------------------------------------------------

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "case1_recovery_tx_seq"
            );

        assert(
            tx_seq.randomize() with {
                num_bytes  == 1;
                tx_data[0] == 8'hA5;
            }
        )
        else begin

            `uvm_fatal(
                "UART_TX_RESET_TEST",
                "CASE 1 recovery sequence randomization failed"
            )

        end

        tx_seq.start(
            env.apb_agt.sequencer
        );


        // Give UART enough time to transmit complete frame.
        #120us;


        `uvm_info(
            "UART_TX_RESET_TEST",
            "CASE 1 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Case 2
    //
    // UART transmitter is already sending a frame.
    // Assert reset in the middle of transmission.
    // ============================================================

    virtual task reset_during_active_tx();

        apb_enable             seq_en;
        apb_tx_enable          tx_en;
        uart_tx_multi_sequence tx_seq;

        `uvm_info(
            "UART_TX_RESET_TEST",
            "========== CASE 2: RESET DURING ACTIVE UART TX ==========",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 1. Start from known enabled state.
        // --------------------------------------------------------

        seq_en =
            apb_enable::type_id::create(
                "case2_seq_en"
            );

        tx_en =
            apb_tx_enable::type_id::create(
                "case2_tx_enable"
            );

        seq_en.start(
            env.apb_agt.sequencer
        );

        tx_en.start(
            env.apb_agt.sequencer
        );


        // --------------------------------------------------------
        // 2. Send known byte 0x3C.
        // --------------------------------------------------------

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "case2_tx_seq"
            );

        assert(
            tx_seq.randomize() with {
                num_bytes  == 1;
                tx_data[0] == 8'h3C;
            }
        )
        else begin

            `uvm_fatal(
                "UART_TX_RESET_TEST",
                "CASE 2 TX sequence randomization failed"
            )

        end

        tx_seq.start(
            env.apb_agt.sequencer
        );


        // --------------------------------------------------------
        // 3. Wait until transmission should clearly be in progress.
        //
        // Existing TX_BUSY test already uses 20 us for this DUT.
        // At 115200 baud the frame lasts ~87 us, therefore
        // 20 us lands well inside the frame.
        // --------------------------------------------------------

        #20us;


        `uvm_info(
            "UART_TX_RESET_TEST",
            "CASE 2: Asserting reset during active UART transmission",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 4. Reset mid-frame.
        //
        // DUT should abandon the partial frame.
        // Scoreboard reset_model() clears the expected 0x3C.
        // --------------------------------------------------------

        apply_reset();


        // --------------------------------------------------------
        // 5. Re-enable UART TX after reset.
        // --------------------------------------------------------

        seq_en =
            apb_enable::type_id::create(
                "case2_recovery_enable"
            );

        tx_en =
            apb_tx_enable::type_id::create(
                "case2_recovery_tx_enable"
            );

        seq_en.start(
            env.apb_agt.sequencer
        );

        tx_en.start(
            env.apb_agt.sequencer
        );


        // --------------------------------------------------------
        // 6. Send a new byte after reset.
        //
        // Successful monitor + scoreboard comparison proves
        // transmitter recovered and can complete a new frame.
        // --------------------------------------------------------

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "case2_recovery_tx_seq"
            );

        assert(
            tx_seq.randomize() with {
                num_bytes  == 1;
                tx_data[0] == 8'hC3;
            }
        )
        else begin

            `uvm_fatal(
                "UART_TX_RESET_TEST",
                "CASE 2 recovery sequence randomization failed"
            )

        end

        tx_seq.start(
            env.apb_agt.sequencer
        );

        #120us;


        `uvm_info(
            "UART_TX_RESET_TEST",
            "CASE 2 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Main run phase
    // ============================================================

    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);


        // --------------------------------------------------------
        // Case 1:
        // reset while stale data is waiting in TX FIFO
        // --------------------------------------------------------

        reset_with_data_in_tx_fifo();


        repeat (5)
            @(posedge reset_vif.PCLK);


        // Reset once between the two independent cases so Case 2
        // begins from a clean DUT/reference-model state.
        apply_reset();


        // --------------------------------------------------------
        // Case 2:
        // reset while UART TX is actively shifting a frame
        // --------------------------------------------------------

        reset_during_active_tx();


        `uvm_info(
            "TEST_DONE",
            "UART TX reset corner cases completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif