`ifndef UART_RX_TEST_SV
`define UART_RX_TEST_SV

class uart_rx_test extends tb_base_test;

    `uvm_component_utils(uart_rx_test)

    int unsigned rx_num_bytes = 0;

    function new(
        string name = "uart_rx_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    task run_phase(uvm_phase phase);

        apb_rx_enable         apb_rx_seq;
        uart_rx_multi_sequence rx_seq;
        apb_read_sequence     apb_seq;

        phase.raise_objection(this);

        apb_rx_seq = apb_rx_enable::type_id::create("apb_rx_seq");
        rx_seq     = uart_rx_multi_sequence::type_id::create("rx_seq");


//////////////////////////////////////////////////////////////////////////////
        if (rx_num_bytes == 0) begin

            assert(
                rx_seq.randomize() with {
                    num_bytes inside {[1:8]};
                }
            )
            else begin
                `uvm_fatal(
                    "UART_RX_TEST",
                    "Randomization failed"
                )
            end

        end
        else begin

            assert(
                rx_seq.randomize() with {
                    num_bytes == local::rx_num_bytes;
                }
            )
            else begin
                `uvm_fatal(
                    "UART_RX_TEST",
                    "Randomization failed"
                )
            end

        end
///////////////////////////////////////////////////////////////////////////////

        // 1. Enable UART RX
        apb_rx_seq.start(env.apb_agt.sequencer);

        #10us;

        // 2. Send all randomized RX bytes
        rx_seq.start(env.uart_agt.sequencer);

        // 3. Wait until DUT has received them
        #1000us;

        // 4. Read RXDATA once for each byte
        for (int i = 0; i < rx_seq.num_bytes; i++) begin

            apb_seq = apb_read_sequence::type_id::create(
                $sformatf("apb_seq_%0d", i)
            );

            apb_seq.start(env.apb_agt.sequencer);

        end

        #100us;

        phase.drop_objection(this);

    endtask

endclass

`endif