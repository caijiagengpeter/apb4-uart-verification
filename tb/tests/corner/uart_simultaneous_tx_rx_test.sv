`ifndef UART_SIMULTANEOUS_TX_RX_TEST_SV
`define UART_SIMULTANEOUS_TX_RX_TEST_SV

class uart_simultaneous_tx_rx_test extends tb_base_test;

    `uvm_component_utils(uart_simultaneous_tx_rx_test)


    function new(
        string name = "uart_simultaneous_tx_rx_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // Enable UART + TX + RX
    // ============================================================

    virtual task enable_tx_rx(string name);

        apb_tx_rx_enable enable_seq;

        enable_seq =
            apb_tx_rx_enable::type_id::create(name);

        enable_seq.start(
            env.apb_agt.sequencer
        );

    endtask


    // ============================================================
    // Read one byte from RX FIFO
    //
    // Existing scoreboard performs RX data comparison.
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
    // TX starts first.
    // RX begins while TX frame is still active.
    // ============================================================

    virtual task tx_first_case();

        uart_tx_multi_sequence tx_seq;
        uart_rx_multi_sequence rx_seq;
        apb_check_tx_rx_busy   busy_seq;


        `uvm_info(
            "UART_SIMULTANEOUS_TEST",
            "========== CASE 1: TX FIRST, RX STARTS DURING TX ==========",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 1. Enable TX + RX simultaneously.
        // --------------------------------------------------------

        enable_tx_rx("case1_enable");


        // --------------------------------------------------------
        // 2. Prepare TX byte = 0x5A
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
                "UART_SIMULTANEOUS_TEST",
                "CASE 1 TX randomization failed"
            )

        end


        // --------------------------------------------------------
        // 3. Prepare RX byte = 0xA5
        // --------------------------------------------------------

        rx_seq =
            uart_rx_multi_sequence::type_id::create(
                "case1_rx_seq"
            );

        assert(
            rx_seq.randomize() with {

                num_bytes  == 1;
                rx_data[0] == 8'hA5;

                inject_frame_error  == 1'b0;
                inject_parity_error == 1'b0;

                parity_en  == 1'b0;
                parity_odd == 1'b0;

            }
        )
        else begin

            `uvm_fatal(
                "UART_SIMULTANEOUS_TEST",
                "CASE 1 RX randomization failed"
            )

        end


        // --------------------------------------------------------
        // 4. Start TX first.
        //
        // uart_tx_multi_sequence only performs the APB TXDATA
        // write, so it returns quickly while UART transmission
        // continues in hardware.
        // --------------------------------------------------------

        tx_seq.start(
            env.apb_agt.sequencer
        );


        // Allow TX to enter active frame.
        #10us;


        // --------------------------------------------------------
        // 5. Start RX while TX is active.
        //
        // At the same time, check STAT while both should be busy.
        // --------------------------------------------------------

        fork

            // External UART RX frame.
            begin

                rx_seq.start(
                    env.uart_agt.sequencer
                );

            end


            // During RX frame, both TX and RX should be active.
            begin

                #10us;

                busy_seq =
                    apb_check_tx_rx_busy::type_id::create(
                        "case1_busy_check"
                    );

                busy_seq.start(
                    env.apb_agt.sequencer
                );

            end

        join


        // --------------------------------------------------------
        // 6. RX frame has completed.
        // Read RXDATA -> scoreboard expects 0xA5.
        //
        // TX monitor/scoreboard independently checks 0x5A.
        // --------------------------------------------------------

        read_rxdata(
            "case1_read_rxdata"
        );


        `uvm_info(
            "UART_SIMULTANEOUS_TEST",
            "CASE 1 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // CASE 2
    //
    // RX starts first.
    // TX begins while RX frame is still active.
    // ============================================================

    virtual task rx_first_case();

        uart_tx_multi_sequence tx_seq;
        uart_rx_multi_sequence rx_seq;
        apb_check_tx_rx_busy   busy_seq;


        `uvm_info(
            "UART_SIMULTANEOUS_TEST",
            "========== CASE 2: RX FIRST, TX STARTS DURING RX ==========",
            UVM_LOW
        )


        // --------------------------------------------------------
        // 1. TX + RX remain enabled.
        // Write CTRL=0x7 again to establish known configuration.
        // --------------------------------------------------------

        enable_tx_rx("case2_enable");


        // --------------------------------------------------------
        // 2. RX byte = 0x3C
        // --------------------------------------------------------

        rx_seq =
            uart_rx_multi_sequence::type_id::create(
                "case2_rx_seq"
            );

        assert(
            rx_seq.randomize() with {

                num_bytes  == 1;
                rx_data[0] == 8'h3C;

                inject_frame_error  == 1'b0;
                inject_parity_error == 1'b0;

                parity_en  == 1'b0;
                parity_odd == 1'b0;

            }
        )
        else begin

            `uvm_fatal(
                "UART_SIMULTANEOUS_TEST",
                "CASE 2 RX randomization failed"
            )

        end


        // --------------------------------------------------------
        // 3. TX byte = 0xC3
        // --------------------------------------------------------

        tx_seq =
            uart_tx_multi_sequence::type_id::create(
                "case2_tx_seq"
            );

        assert(
            tx_seq.randomize() with {
                num_bytes  == 1;
                tx_data[0] == 8'hC3;
            }
        )
        else begin

            `uvm_fatal(
                "UART_SIMULTANEOUS_TEST",
                "CASE 2 TX randomization failed"
            )

        end


        // --------------------------------------------------------
        // 4. RX starts first.
        //
        // After 20 us, start TX while RX is still receiving.
        //
        // About 10 us later check that both BUSY bits are high.
        // --------------------------------------------------------

        fork

            // External RX frame starts immediately.
            begin

                rx_seq.start(
                    env.uart_agt.sequencer
                );

            end


            begin

                // RX is already well inside its frame.
                #20us;


                // Start TX while RX remains active.
                tx_seq.start(
                    env.apb_agt.sequencer
                );


                // Give TX time to enter active transmission.
                #10us;


                // Now both should be active.
                busy_seq =
                    apb_check_tx_rx_busy::type_id::create(
                        "case2_busy_check"
                    );

                busy_seq.start(
                    env.apb_agt.sequencer
                );

            end

        join


        // --------------------------------------------------------
        // 5. RX complete -> read expected 0x3C.
        // --------------------------------------------------------

        read_rxdata(
            "case2_read_rxdata"
        );


        // TX started later than RX, so allow enough time for
        // its complete 0xC3 frame to finish and reach scoreboard.
        #40us;


        `uvm_info(
            "UART_SIMULTANEOUS_TEST",
            "CASE 2 completed",
            UVM_LOW
        )

    endtask


    // ============================================================
    // Main
    // ============================================================

    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);


        // --------------------------------------------------------
        // Case 1:
        // TX active first, then RX joins.
        // --------------------------------------------------------

        tx_first_case();


        // Give a clean idle interval between the two cases.
        #20us;


        // --------------------------------------------------------
        // Case 2:
        // RX active first, then TX joins.
        // --------------------------------------------------------

        rx_first_case();


        `uvm_info(
            "TEST_DONE",
            "Simultaneous UART TX/RX corner test completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif