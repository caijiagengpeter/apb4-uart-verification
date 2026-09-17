`ifndef STAT_RX_PARITY_ODD_BIT_TEST_SV
`define STAT_RX_PARITY_ODD_BIT_TEST_SV

class stat_rx_parity_odd_bit_test extends tb_base_test;

    `uvm_component_utils(stat_rx_parity_odd_bit_test)

    function new(
        string name = "stat_rx_parity_odd_bit_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction
///////////////////////////////////////////////////////////////////////


    function void build_phase(uvm_phase phase);

        uvm_config_db#(bit)::set(
            this,
            "env.uart_agt.rx_monitor",
            "parity_en",
            1'b1
        );

        uvm_config_db#(bit)::set(
            this,
            "env.uart_agt.rx_monitor",
            "parity_odd",
            1'b1
        );

        super.build_phase(phase);

    endfunction



    task run_phase(uvm_phase phase);

        localparam int NUM_RX_BYTES = 2;
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
        // 1. Enable UART and RX 
        // CTRL = 0x05
        // ------------------------------------------------
        seq_en.start(env.apb_agt.sequencer);
        rx_en.start(env.apb_agt.sequencer);

        // ------------------------------------------------
        // Fill 1 error Byte
        // ------------------------------------------------

/////////////////////////////////////////////////////GOOD One
        assert(
            seq1.randomize() with {
                num_bytes == 1;
                parity_en == 1;
                parity_odd == 1;
                inject_parity_error == 0;
                inject_frame_error == 0;
            }
        )
        else
            `uvm_fatal(
                "STAT_PARITY_ERROR_TEST",
                "1 normal byte sequence randomization failed"
            )

        seq1.start(env.uart_agt.sequencer);
        seq_stat.start(env.apb_agt.sequencer);

        #100us;

/////////////////////////////////////////////////////BAD One



        assert(
            seq1_error.randomize() with {
                num_bytes == 1;
                parity_en == 1;
                parity_odd == 1;
                inject_parity_error == 1;
                inject_frame_error == 0;
            }
        )
        else
            `uvm_fatal(
                "STAT_PARITY_ERROR_TEST",
                "1 error byte sequence randomization failed"
            )

        seq1_error.start(env.uart_agt.sequencer);

        #100us;


/////////////////////////////////////////////////////////////////////////
 
        // ------------------------------------------------
        //  Read RXDATA once for right byte
        //
        // ------------------------------------------------

        for (int i = 0; i < NUM_RX_BYTES; i++) begin

            apb_read = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_read.start(env.apb_agt.sequencer);

        end

        phase.drop_objection(this);

    endtask

endclass

`endif
