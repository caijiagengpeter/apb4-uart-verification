`ifndef STAT_RX_BUSY_BIT_TEST_SV
`define STAT_RX_BUSY_BIT_TEST_SV

class stat_rx_busy_bit_test extends tb_base_test;

    `uvm_component_utils(stat_rx_busy_bit_test)

    function new(
        string name = "stat_rx_busy_bit_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

/////////////////////////////////////////////////////
   task run_phase(uvm_phase phase);

        uart_rx_multi_sequence seq1;
        apb_enable             seq_en;
        apb_read_stat          seq_stat;
        apb_rx_enable          rx_en;
        apb_read_sequence      apb_read;
        localparam int FIFO_DEPTH = 1;

        phase.raise_objection(this);

        seq_en = apb_enable::type_id::create("seq_en");
        seq1   = uart_rx_multi_sequence::type_id::create("seq1");
        seq_stat   = apb_read_stat::type_id::create("seq_stat");
        rx_en  = apb_rx_enable::type_id::create("rx_en");

        seq_en.start(env.apb_agt.sequencer);
        rx_en.start(env.apb_agt.sequencer);

        // idle
        seq_stat.start(env.apb_agt.sequencer);

        assert(seq1.randomize() with { num_bytes == 1; })
        else
            `uvm_fatal(
                "STAT_RX_BUSY_BIT_TEST",
                "1-byte sequence randomization failed"
            )

        fork
            begin
                seq1.start(env.uart_agt.sequencer);
            end

            begin
                #20us;
                seq_stat.start(env.apb_agt.sequencer);
            end
        join

        #20us;

        // complete
        seq_stat.start(env.apb_agt.sequencer);
/////////////////////////////////////////////////////////////////////apb read

        for (int i = 0; i < FIFO_DEPTH; i++) begin

            apb_read = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_read.start(env.apb_agt.sequencer);

        end

        phase.drop_objection(this);

    endtask

endclass

`endif