`ifndef APB_RESET_DURING_TRANSFER_TEST_SV
`define APB_RESET_DURING_TRANSFER_TEST_SV

class apb_reset_during_transfer_test extends tb_base_test;

    `uvm_component_utils(apb_reset_during_transfer_test)

    virtual apb_if.RESET reset_vif;


    function new(
        string name = "apb_reset_during_transfer_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    ////////////////////////////////////////////////////////////////
    // Build phase
    ////////////////////////////////////////////////////////////////

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if.RESET)::get(
                this,
                "",
                "reset_vif",
                reset_vif
            )) begin

            `uvm_fatal(
                "RESET_VIF",
                "Failed to get reset_vif"
            )

        end

    endfunction


    ////////////////////////////////////////////////////////////////
    // Helper:
    // Create non-reset DUT state before each reset test
    ////////////////////////////////////////////////////////////////

    virtual task prepare_non_reset_state();

        apb_enable    seq_en;
        apb_rx_enable rx_en;

        seq_en = apb_enable::type_id::create("seq_en");
        rx_en  = apb_rx_enable::type_id::create("rx_en");

        seq_en.start(
            env.apb_agt.sequencer
        );

        rx_en.start(
            env.apb_agt.sequencer
        );

        `uvm_info(
            "APB_RESET_TEST",
            "DUT configured into non-reset state",
            UVM_LOW
        )

    endtask


    ////////////////////////////////////////////////////////////////
    // Helper:
    // Check reset state and verify APB recovery
    ////////////////////////////////////////////////////////////////

    virtual task check_post_reset_state(string case_name);

        apb_post_reset_check_sequence check_seq;

        // Give DUT one clean clock after reset release.
        @(posedge reset_vif.PCLK);

        check_seq =
            apb_post_reset_check_sequence::type_id::create(
                $sformatf("check_seq_%s", case_name)
            );

        check_seq.start(
            env.apb_agt.sequencer
        );

        `uvm_info(
            "APB_RESET_TEST",
            $sformatf(
                "%s post-reset state and recovery check completed",
                case_name
            ),
            UVM_LOW
        )

    endtask


    ////////////////////////////////////////////////////////////////
    // Case 1:
    // Assert reset during APB SETUP
    //
    // SETUP:
    // PSEL    = 1
    // PENABLE = 0
    ////////////////////////////////////////////////////////////////

    virtual task run_setup_reset_case();

        apb_reset_during_transfer_sequence reset_seq;

        `uvm_info(
            "APB_RESET_TEST",
            "========== CASE 1: RESET DURING APB SETUP ==========",
            UVM_LOW
        )

        prepare_non_reset_state();

        reset_seq =
            apb_reset_during_transfer_sequence::type_id::create(
                "setup_reset_seq"
            );


        fork

            ////////////////////////////////////////////////////////
            // Thread A:
            // Start a normal APB transaction
            ////////////////////////////////////////////////////////

            begin

                reset_seq.start(
                    env.apb_agt.sequencer
                );

            end


            ////////////////////////////////////////////////////////
            // Thread B:
            // Detect SETUP and inject reset
            ////////////////////////////////////////////////////////

            begin

                wait (
                    reset_vif.PSEL    === 1'b1 &&
                    reset_vif.PENABLE === 1'b0
                );

                `uvm_info(
                    "APB_RESET_TEST",
                    "SETUP detected - asserting reset",
                    UVM_LOW
                )

                reset_vif.PRESETn = 1'b0;

                repeat (3)
                    @(posedge reset_vif.PCLK);

                reset_vif.PRESETn = 1'b1;

                `uvm_info(
                    "APB_RESET_TEST",
                    "SETUP-phase reset released",
                    UVM_LOW
                )

            end

        join


        check_post_reset_state("SETUP");

    endtask


    ////////////////////////////////////////////////////////////////
    // Case 2:
    // Assert reset during APB ACCESS
    //
    // ACCESS:
    // PSEL    = 1
    // PENABLE = 1
    //
    // Note:
    // This DUT is zero-wait-state, so PREADY is normally already 1.
    // The purpose here is to test reset coincident with ACCESS and
    // verify reset/recovery, not to claim a specific APB abort
    // behavior after transfer completion.
    ////////////////////////////////////////////////////////////////

    virtual task run_access_reset_case();

        apb_reset_during_transfer_sequence reset_seq;

        `uvm_info(
            "APB_RESET_TEST",
            "========== CASE 2: RESET DURING APB ACCESS ==========",
            UVM_LOW
        )

        prepare_non_reset_state();

        reset_seq =
            apb_reset_during_transfer_sequence::type_id::create(
                "access_reset_seq"
            );


        fork

            ////////////////////////////////////////////////////////
            // Thread A:
            // Start normal APB transaction
            ////////////////////////////////////////////////////////

            begin

                reset_seq.start(
                    env.apb_agt.sequencer
                );

            end


            ////////////////////////////////////////////////////////
            // Thread B:
            // Detect ACCESS and inject reset
            ////////////////////////////////////////////////////////

            begin

                wait (
                    reset_vif.PSEL    === 1'b1 &&
                    reset_vif.PENABLE === 1'b1
                );

                `uvm_info(
                    "APB_RESET_TEST",
                    "ACCESS detected - asserting reset",
                    UVM_LOW
                )

                reset_vif.PRESETn = 1'b0;

                repeat (3)
                    @(posedge reset_vif.PCLK);

                reset_vif.PRESETn = 1'b1;

                `uvm_info(
                    "APB_RESET_TEST",
                    "ACCESS-phase reset released",
                    UVM_LOW
                )

            end

        join


        check_post_reset_state("ACCESS");

    endtask


    ////////////////////////////////////////////////////////////////
    // Main run phase
    ////////////////////////////////////////////////////////////////

    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);


        ////////////////////////////////////////////////////////////
        // Case 1: reset during SETUP
        ////////////////////////////////////////////////////////////

        run_setup_reset_case();


        ////////////////////////////////////////////////////////////
        // Small separation between the two directed scenarios
        ////////////////////////////////////////////////////////////

        repeat (3)
            @(posedge reset_vif.PCLK);


        ////////////////////////////////////////////////////////////
        // Case 2: reset during ACCESS
        ////////////////////////////////////////////////////////////

        run_access_reset_case();


        ////////////////////////////////////////////////////////////
        // End
        ////////////////////////////////////////////////////////////

        `uvm_info(
            "TEST_DONE",
            "APB SETUP/ACCESS reset corner cases completed",
            UVM_LOW
        )

        phase.drop_objection(this);

    endtask

endclass

`endif