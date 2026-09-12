`ifndef UART_RX_TEST_SV
`define UART_RX_TEST_SV

class uart_rx_test extends tb_base_test;

    `uvm_component_utils(uart_rx_test)

    function new(
        string name = "uart_rx_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    task run_phase(uvm_phase phase);

        uart_send_sequence seq;
        uart_rx_smoke_sequence rx_seq;
        apb_read_sequence apb_seq;

        phase.raise_objection(this);

        seq = uart_send_sequence::type_id::create("seq");
        rx_seq = uart_rx_smoke_sequence::type_id::create("rx_seq");
        apb_seq = apb_read_sequence::type_id::create("apb_seq");


        rx_seq.start(env.apb_agt.sequencer);
        #10us;
        seq.start(env.uart_agt.sequencer);
        #120us;
        apb_seq.start(env.apb_agt.sequencer);
        #10us;




        phase.drop_objection(this);

    endtask

endclass

`endif