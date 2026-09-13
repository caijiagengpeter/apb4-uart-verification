`ifndef UART_TX_FIFO_BOUNDARY_TEST_SV
`define UART_TX_FIFO_BOUNDARY_TEST_SV

class uart_tx_fifo_boundary_test extends tb_base_test;

    `uvm_component_utils(uart_tx_fifo_boundary_test)

    function new(
        string name = "uart_tx_fifo_boundary_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

 
    task run_phase(uvm_phase phase);

        uart_tx_multi_sequence seq15;
        uart_tx_multi_sequence seq1;
        apb_enable             seq_en;
        apb_read_stat          seq_stat;
        apb_tx_enable          tx_en;

        phase.raise_objection(this);

        seq_en = apb_enable::type_id::create("seq_en");
        seq15  = uart_tx_multi_sequence::type_id::create("seq15");
        seq1   = uart_tx_multi_sequence::type_id::create("seq1");
        seq_stat   = apb_read_stat::type_id::create("seq_stat");
        tx_en  = apb_tx_enable::type_id::create("tx_en");

        // ------------------------------------------------
        // 1. UART enable, TX disable
        // CTRL = 0x01
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);

        // ------------------------------------------------
        // 2. Fill first 15 entries
        // ------------------------------------------------
        assert(
            seq15.randomize() with {
                num_bytes == 15;
            }
        )
        else
            `uvm_fatal(
                "UART_TX_FIFO_BOUNDARY_TEST",
                "15-byte sequence randomization failed"
            )

        seq15.start(env.apb_agt.sequencer);

        // ------------------------------------------------
        // 3. Read STAT
        // Expected TX_FULL = 0
        // ------------------------------------------------

            seq_stat.start(env.apb_agt.sequencer);

            if (seq_stat.rdata[2] !== 1'b0)
                `uvm_error(
                    "UART_TX_FIFO_BOUNDARY_TEST",
                    $sformatf(
                        "TX_FULL expected 0 after 15 bytes, STAT=0x%08h",
                        seq_stat.rdata
                    )
                )
         // ------------------------------------------------
         // 4. Write the 16th byte
         // ------------------------------------------------
         assert(
             seq1.randomize() with {
                 num_bytes == 1;
             }
         )
         else
             `uvm_fatal(
                 "UART_TX_FIFO_BOUNDARY_TEST",
                 "1-byte sequence randomization failed"
             )

         seq1.start(env.apb_agt.sequencer);
        // ------------------------------------------------
        // 5. Read STAT again
        // Expected TX_FULL = 1
        // ------------------------------------------------

        seq_stat.start(env.apb_agt.sequencer);

        if (seq_stat.rdata[2] !== 1'b1)
            `uvm_error(
                "UART_TX_FIFO_BOUNDARY_TEST",
                $sformatf(
                    "TX_FULL expected 1 after 16 bytes, STAT=0x%08h",
                    seq_stat.rdata
                )
            )


         // ------------------------------------------------
         // 6. Write the 17th byte
         // ------------------------------------------------
         assert(
             seq1.randomize() with {
                 num_bytes == 1;
             }
         )
         else
             `uvm_fatal(
                 "UART_TX_FIFO_BOUNDARY_TEST",
                 "1-byte sequence randomization failed"
             )

         seq1.start(env.apb_agt.sequencer);
        // ------------------------------------------------
        // 7. Read STAT again
        // Expected TX_FULL = 1
        // ------------------------------------------------

        seq_stat.start(env.apb_agt.sequencer);

        if (seq_stat.rdata[2] !== 1'b1)
            `uvm_error(
                "UART_TX_FIFO_BOUNDARY_TEST",
                $sformatf(
                    "TX_FULL expected 1 after 17 bytes, STAT=0x%08h",
                    seq_stat.rdata
                )
            )

        #15us;

        // ------------------------------------------------
        // 8. Enable the Tx Transmission
        // CTRL = 0x03
        // ------------------------------------------------   
        tx_en.start(env.apb_agt.sequencer);

        #5000us;

        // ------------------------------------------------
        // 9. Read STAT again
        // Expected TX_FULL = 0
        // ------------------------------------------------

        seq_stat.start(env.apb_agt.sequencer);

        if (seq_stat.rdata[2] !== 1'b0)
            `uvm_error(
                "UART_TX_FIFO_BOUNDARY_TEST",
                $sformatf(
                    "TX_FULL expected 0 after 0 bytes, STAT=0x%08h",
                    seq_stat.rdata
                )
            )


        phase.drop_objection(this);

    endtask

endclass

`endif