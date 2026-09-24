`ifndef UART_RX_RESET_TEST_SV
`define UART_RX_RESET_TEST_SV

class uart_rx_reset_test extends tb_base_test;

    `uvm_component_utils(uart_rx_reset_test)

    virtual apb_if.RESET reset_vif;


    function new(
        string name = "uart_rx_reset_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // Build
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
                "UART_RX_RESET_TEST",
                "Failed to get reset_vif"
            )

        end

    endfunction


    // ============================================================
    // Runtime reset helper
    // ============================================================

    virtual task apply_reset();

        `uvm_info(
            "UART_RX_RESET_TEST",
            "Asserting runtime reset",
            UVM_LOW
        )

        reset_vif.PRESETn = 1'b0;

        repeat (3)
            @(posedge reset_vif.PCLK);

        reset_vif.PRESETn = 1'b1;

        @(posedge reset_vif.PCLK);

        `uvm_info(
            "UART_RX_RESET_TEST",
            "Runtime reset released",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Enable UART + RX
    // ============================================================

    virtual task enable_rx(string suffix);

        apb_enable    seq_en;
        apb_rx_enable rx_en;

        seq_en = apb_enable::type_id::create(
            $sformatf("seq_en_%s", suffix)
        );

        rx_en = apb_rx_enable::type_id::create(
            $sformatf("rx_en_%s", suffix)
        );

        seq_en.start(env.apb_agt.sequencer);
        rx_en.start(env.apb_agt.sequencer);

    endtask


    // ============================================================
    // Send one known UART RX byte
    // ============================================================

    virtual task send_rx_byte(
        logic [7:0] data,
        string      name
    );

        uart_rx_multi_sequence rx_seq;

        rx_seq =
            uart_rx_multi_sequence::type_id::create(name);

        assert(
            rx_seq.randomize() with {
                num_bytes == 1;
                rx_data[0] == local::data;

                inject_frame_error  == 1'b0;
                inject_parity_error == 1'b0;

                parity_en  == 1'b0;
                parity_odd == 1'b0;
            }
        )
        else begin

            `uvm_fatal(
                "UART_RX_RESET_TEST",
                "UART RX sequence randomization failed"
            )

        end

        rx_seq.start(
            env.uart_agt.sequencer
        );

    endtask


    // ============================================================
    // Read one byte from RXDATA
    //
    // Existing scoreboard performs expected-vs-DUT comparison.
    // ============================================================

    virtual task read_rxdata(string name);

        apb_read_sequence read_seq;

        read_seq =
            apb_read_sequence::type_id::create(name);

        read_seq.start(
            env.apb_agt.sequencer
        );

    endtask


    // ============================================================
    // CASE 1
    //
    // RX FIFO already contains a completed byte.
    // Reset must remove that stale byte.
    // ============================================================

    virtual task reset_with_data_in_rx_fifo();

        `uvm_info(
            "UART_RX_RESET_TEST",
            "========== CASE 1: RESET WITH DATA IN RX FIFO ==========",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 1. Enable UART RX.
        // --------------------------------------------------------

        enable_rx("case1");


        // --------------------------------------------------------
        // 2. Receive known byte 0x5A completely.
        //
        // After send_rx_byte() returns, the complete frame has
        // already reached the DUT and should be stored in RX FIFO.
        // --------------------------------------------------------

        `uvm_info(
            "UART_RX_RESET_TEST",
            "CASE 1: Sending 0x5A into RX FIFO",
            UVM_LOW
        )

        send_rx_byte(
            8'h5A,
            "case1_old_rx"
        );


        // --------------------------------------------------------
        // 3. Reset DUT while RX FIFO contains 0x5A.
        //
        // DUT RX FIFO should become empty.
        // Scoreboard reset_model() should clear expected 0x5A.
        // --------------------------------------------------------

        apply_reset();


        // --------------------------------------------------------
        // 4. Re-enable RX.
        // --------------------------------------------------------

        enable_rx("case1_recovery");


        // --------------------------------------------------------
        // 5. Send NEW byte 0xA5.
        //
        // If stale 0x5A survived reset, the next RXDATA read would
        // return 0x5A while scoreboard expects 0xA5 -> error.
        // --------------------------------------------------------

        `uvm_info(
            "UART_RX_RESET_TEST",
            "CASE 1: Sending post-reset byte 0xA5",
            UVM_LOW
        )

        send_rx_byte(
            8'hA5,
            "case1_new_rx"
        );


        // --------------------------------------------------------
        // 6. Read RXDATA.
        //
        // Expected:
        //     scoreboard -> 0xA5
        //     DUT        -> 0xA5
        // --------------------------------------------------------

        read_rxdata(
            "case1_read_rxdata"
        );


        `uvm_info(
            "UART_RX_RESET_TEST",
            "CASE 1 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // CASE 2
    //
    // Reset while UART RX frame is actively being received.
    // ============================================================

    virtual task reset_during_active_rx();

        uart_rx_multi_sequence rx_seq;

        // Used to tell reset thread that the interrupted
        // external UART frame has completely finished.
        event interrupted_frame_done;


        `uvm_info(
            "UART_RX_RESET_TEST",
            "========== CASE 2: RESET DURING ACTIVE UART RX ==========",
            UVM_LOW
        )


        // ============================================================
        // 1. Enable UART + RX
        // ============================================================

        enable_rx("case2");


        // ============================================================
        // 2. Prepare interrupted frame = 0x3C
        // ============================================================

        rx_seq =
            uart_rx_multi_sequence::type_id::create(
                "case2_partial_rx"
            );

        assert(
            rx_seq.randomize() with {

                num_bytes == 1;

                rx_data[0] == 8'h3C;

                inject_frame_error  == 1'b0;
                inject_parity_error == 1'b0;

                parity_en  == 1'b0;
                parity_odd == 1'b0;

            }
        )
        else begin

            `uvm_fatal(
                "UART_RX_RESET_TEST",
                "CASE 2 RX sequence randomization failed"
            )

        end


        // ============================================================
        // 3. External UART frame and DUT reset run concurrently
        // ============================================================

        fork

            // --------------------------------------------------------
            // Thread A:
            // External UART keeps transmitting 0x3C normally.
            //
            // The external sender does NOT know that DUT is reset.
            // --------------------------------------------------------

            begin

                rx_seq.start(
                    env.uart_agt.sequencer
                );

                // uart_driver has now completed the whole old frame
                // and its configured inter-frame gap.
                -> interrupted_frame_done;

                `uvm_info(
                    "UART_RX_RESET_TEST",
                    "CASE 2: Interrupted external UART frame has fully ended",
                    UVM_LOW
                )

            end


            // --------------------------------------------------------
            // Thread B:
            // Assert reset while 0x3C is still being received.
            //
            // IMPORTANT:
            // Keep reset asserted until the external interrupted
            // frame has completely finished.
            // --------------------------------------------------------

            begin

                // Approximately inside the 0x3C frame.
                #20us;

                `uvm_info(
                    "UART_RX_RESET_TEST",
                    "CASE 2: Asserting reset during active UART RX frame",
                    UVM_LOW
                )

                reset_vif.PRESETn = 1'b0;


                // Wait until the OLD external frame and its gap
                // have completely finished.
                @interrupted_frame_done;


                // A couple of clean clocks while RX line is already idle.
                repeat (2)
                    @(posedge reset_vif.PCLK);


                // Now release DUT reset.
                reset_vif.PRESETn = 1'b1;

                @(posedge reset_vif.PCLK);


                `uvm_info(
                    "UART_RX_RESET_TEST",
                    "CASE 2: Reset released after interrupted frame was discarded",
                    UVM_LOW
                )

            end

        join


        // ============================================================
        // 4. Re-enable UART + RX
        // ============================================================

        enable_rx("case2_recovery");


        // ============================================================
        // 5. Send a NEW complete frame = 0xC3
        // ============================================================

        `uvm_info(
            "UART_RX_RESET_TEST",
            "CASE 2: Sending recovery byte 0xC3",
            UVM_LOW
        )

        send_rx_byte(
            8'hC3,
            "case2_new_rx"
        );


        // ============================================================
        // 6. Read RXDATA
        //
        // Expected:
        //   old interrupted 0x3C -> discarded
        //   new complete C3      -> accepted
        // ============================================================

        read_rxdata(
            "case2_read_rxdata"
        );


        `uvm_info(
            "UART_RX_RESET_TEST",
            "CASE 2 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Main run phase
    // ============================================================

    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);


        // Case 1:
        // completed byte stored in RX FIFO -> reset
        reset_with_data_in_rx_fifo();


        // Clean separation between independent cases.
        apply_reset();

        repeat (3)
            @(posedge reset_vif.PCLK);


        // Case 2:
        // reset while receiver is processing a UART frame
        reset_during_active_rx();


        `uvm_info(
            "TEST_DONE",
            "UART RX reset corner cases completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif