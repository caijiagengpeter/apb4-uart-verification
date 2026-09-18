`ifndef INT_RX_FULL_TEST_SV
`define INT_RX_FULL_TEST_SV

class int_rx_full_test extends tb_base_test;

    `uvm_component_utils(int_rx_full_test)

    function new(
        string name = "int_rx_full_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction
///////////////////////////////////////////////////////////////////////

    task run_phase(uvm_phase phase);

        localparam int FIFO_DEPTH = 16;
        apb_enable             seq_en;
        uart_rx_multi_sequence seq16;
        apb_read_stat          seq_stat;
        apb_rx_enable          rx_en;
        apb_read_sequence      apb_read;
        apb_int_rx_full_enable int_rx_enable;


        phase.raise_objection(this);

        seq_en = apb_enable::type_id::create("seq_en");
        seq16  = uart_rx_multi_sequence::type_id::create("seq16");
        seq_stat = apb_read_stat::type_id::create("seq_stat");
        rx_en = apb_rx_enable::type_id::create("rx_en");
        int_rx_enable = apb_int_rx_full_enable::type_id::create("int_rx_enable");


        // ------------------------------------------------
        // UART and RX Eable
        // CTRL = 0x05
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);
        rx_en.start(env.apb_agt.sequencer);
        seq_stat.start(env.apb_agt.sequencer);
        int_rx_enable.start(env.apb_agt.sequencer);

        // Check point 1 expected 0/////////////////////////////////

        // ------------------------------------------------
        // Fill 16 entries
        // ------------------------------------------------
        assert(
            seq16.randomize() with {
                num_bytes == 16;
            }
        )
        else
            `uvm_fatal(
                "INT_RX_FULL_TEST",
                "16-byte sequence randomization failed"
            )


        // Check point 2 expected 1/////////////////////////////////////
        seq16.start(env.uart_agt.sequencer);
        seq_stat.start(env.apb_agt.sequencer);

        #3000us;


        rx_en.start(env.apb_agt.sequencer);


        // ------------------------------------------------
        // 9. Read RXDATA once for each byte
        // ------------------------------------------------

        for (int i = 0; i < FIFO_DEPTH; i++) begin

            apb_read = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_read.start(env.apb_agt.sequencer);

        end

        // Check point 3 expected 0/////////////////////////////////////
        seq_stat.start(env.apb_agt.sequencer);

        phase.drop_objection(this);

    endtask

endclass

`endif
