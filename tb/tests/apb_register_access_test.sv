`ifndef APB_UNSUPPORTED_ACCESS_TEST_SV
`define APB_UNSUPPORTED_ACCESS_TEST_SV

class apb_unsupported_access_test extends tb_base_test;

    `uvm_component_utils(apb_unsupported_access_test)

    function new(
        string name = "apb_unsupported_access_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    virtual task run_phase(uvm_phase phase);

        apb_enable                       seq_en;
        apb_rx_enable                    rx_en;
        uart_rx_multi_sequence           rx_seq;
        apb_unsupported_access_sequence  unsupported_seq;

        phase.raise_objection(this);


        ////////////////////////////////////////////////////////////
        // Step 1:
        // Enable UART
        ////////////////////////////////////////////////////////////

        seq_en = apb_enable::type_id::create("seq_en");

        seq_en.start(
            env.apb_agt.sequencer
        );


        ////////////////////////////////////////////////////////////
        // Step 2:
        // Enable RX path
        ////////////////////////////////////////////////////////////

        rx_en = apb_rx_enable::type_id::create("rx_en");

        rx_en.start(
            env.apb_agt.sequencer
        );


        ////////////////////////////////////////////////////////////
        // Step 3:
        // Send one known byte from external UART side.
        //
        // The DUT RX FIFO should contain 0x5A after this.
        ////////////////////////////////////////////////////////////

        rx_seq =
            uart_rx_multi_sequence::type_id::create("rx_seq");

        assert(
            rx_seq.randomize() with {

                num_bytes == 1;

                rx_data[0] == 8'h5A;

                inject_frame_error  == 1'b0;
                inject_parity_error == 1'b0;

                parity_en  == 1'b0;
                parity_odd == 1'b0;

            }
        )
        else begin

            `uvm_fatal(
                "APB_UNSUPPORTED_TEST",
                "UART RX sequence randomization failed"
            )

        end


        `uvm_info(
            "APB_UNSUPPORTED_TEST",
            "Injecting UART RX byte 0x5A into DUT RX FIFO",
            UVM_LOW
        )

        rx_seq.start(
            env.uart_agt.sequencer
        );


        ////////////////////////////////////////////////////////////
        // Step 4:
        // Perform unsupported APB accesses and verify that the
        // illegal RXDATA write did not corrupt RX FIFO contents.
        ////////////////////////////////////////////////////////////

        unsupported_seq =
            apb_unsupported_access_sequence::type_id::create(
                "unsupported_seq"
            );

        unsupported_seq.expected_rx_data = 8'h5A;

        unsupported_seq.start(
            env.apb_agt.sequencer
        );


        ////////////////////////////////////////////////////////////
        // End
        ////////////////////////////////////////////////////////////

        `uvm_info(
            "TEST_DONE",
            "APB unsupported access corner test completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif