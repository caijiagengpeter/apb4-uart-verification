`ifndef APB_AGENT__SV
`define APB_AGENT__SV

class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)


    // ============================================================
    // APB Agent Components
    // ============================================================
    apb_sequencer sequencer;
    apb_driver    driver;
    apb_monitor   monitor;



    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "apb_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction



    // ============================================================
    // build_phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // --------------------------------------------------------
        // Monitor always exists
        //
        // ACTIVE:
        //     driver + sequencer + monitor
        //
        // PASSIVE:
        //     monitor only
        // --------------------------------------------------------
        monitor = apb_monitor::type_id::create(
            "monitor",
            this
        );


        if (get_is_active() == UVM_ACTIVE) begin


            sequencer = apb_sequencer::type_id::create(
                "sequencer",
                this
            );


            driver = apb_driver::type_id::create(
                "driver",
                this
            );


        end

    endfunction



    // ============================================================
    // connect_phase
    // ============================================================
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        if (get_is_active() == UVM_ACTIVE) begin


            driver.seq_item_port.connect(
                sequencer.seq_item_export
            );


        end

    endfunction


endclass

`endif