`ifndef STAT_FRAME_ERROR_TEST_SV
`define STAT_FRAME_ERROR_TEST_SV

class stat_frame_error_test extends tb_base_test;

    `uvm_component_utils(stat_frame_error_test)

    function new(
        string name = "stat_frame_error_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction
///////////////////////////////////////////////////////////////////////

    task run_phase(uvm_phase phase);

        localparam int NUM_GOOD_BYTES = 1;
        apb_enable             seq_en;
        uart_rx_multi_sequence seq1;
        uart_rx_multi_sequence seq1_error;
        apb_rx_enable          rx_en;
        apb_read_sequence      apb_read;
        apb_read_stat          seq_stat;


        phase.raise_objection(this);

        seq_en = apb_enable::type_id::create("seq_en");
        seq1  = uart_rx_multi_sequence::type_id::create("seq1");
        seq1_error  = uart_rx_multi_sequence::type_id::create("seq1_error");
        rx_en = apb_rx_enable::type_id::create("rx_en");
        seq_stat = apb_read_stat::type_id::create("seq_stat");


        // ------------------------------------------------
        // 1. UART enable, RX disable
        // CTRL = 0x01
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);
        rx_en.start(env.apb_agt.sequencer);

        // ------------------------------------------------
        // Fill 1 error Byte
        // ------------------------------------------------
        assert(
            seq1_error.randomize() with {
                num_bytes == 1;
                inject_frame_error == 1;
            }
        )
        else
            `uvm_fatal(
                "STAT_FRAME_ERROR_TEST",
                "1 error byte sequence randomization failed"
            )

        seq1_error.start(env.uart_agt.sequencer);
         ///////////////////////////////////////////////////////////SVA PART to check the flag
        #100us;


/////////////////////////////////////////////////////////////////////////
        assert(
            seq1.randomize() with {
                num_bytes == 1;
            }
        )
        else
            `uvm_fatal(
                "STAT_FRAME_ERROR_TEST",
                "1 normal byte sequence randomization failed"
            )

        seq1.start(env.uart_agt.sequencer);
        seq_stat.start(env.apb_agt.sequencer);

        #100us;
 
        // ------------------------------------------------
        //  Read RXDATA once for right byte
        //
        // ------------------------------------------------

        for (int i = 0; i < NUM_GOOD_BYTES; i++) begin

            apb_read = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_read.start(env.apb_agt.sequencer);

        end

        phase.drop_objection(this);

    endtask

endclass

`endif
