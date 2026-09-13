`ifndef UART_TX_TEST_SV
`define UART_TX_TEST_SV

class uart_tx_test extends tb_base_test;

    `uvm_component_utils(uart_tx_test)

    function new(
        string name = "uart_tx_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

///////////////////////////////////////////////////////
    task run_phase(uvm_phase phase);
    
        uart_tx_multi_sequence seq;
        apb_tx_enable          seq_en;
    
        phase.raise_objection(this);
    
        seq    = uart_tx_multi_sequence::type_id::create("seq");
        seq_en = apb_tx_enable::type_id::create("seq_en");
    
        seq_en.start(env.apb_agt.sequencer);
    
        assert(
            seq.randomize() with {
                num_bytes inside {[1:8]};
            }
        )
        else
            `uvm_fatal(
                "UART_TX_TEST",
                "Randomization failed"
            )
    
        seq.start(env.apb_agt.sequencer);
    
        #1000us;
    
        phase.drop_objection(this);
    
    endtask

endclass

`endif