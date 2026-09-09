`ifndef APB_DRIVER__SV
`define APB_DRIVER__SV

class apb_driver extends uvm_driver #(apb_item);

    `uvm_component_utils(apb_driver)

    virtual apb_if.DRIVER vif;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "apb_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // build_phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if.DRIVER)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "APB_DRIVER",
                "Failed to get virtual interface"
            )

        end

    endfunction


    // ============================================================
    // run_phase
    // ============================================================
    task run_phase(uvm_phase phase);

        drive_idle();

        forever begin

            // Wait until reset is released
            do begin
                @(vif.drv_cb);
            end
            while (!vif.drv_cb.PRESETn);


            // Get one transaction from sequencer
            seq_item_port.get_next_item(req);


            // Drive APB transaction
            drive_transfer(req);


            // Tell sequencer transaction is completed
            seq_item_port.item_done();

        end

    endtask


    // ============================================================
    // Drive APB bus to IDLE
    // ============================================================
    task drive_idle();

        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;

        vif.drv_cb.PADDR   <= '0;
        vif.drv_cb.PWRITE  <= 1'b0;
        vif.drv_cb.PWDATA  <= '0;
        vif.drv_cb.PSTRB   <= '0;
        vif.drv_cb.PPROT   <= '0;

    endtask


    // ============================================================
    // Drive one APB transfer
    // ============================================================
    task drive_transfer(apb_item req);


        // --------------------------------------------------------
        // SETUP phase
        // --------------------------------------------------------
        @(vif.drv_cb);

        if (!vif.drv_cb.PRESETn) begin

            drive_idle();
            return;

        end


        vif.drv_cb.PSEL    <= 1'b1;
        vif.drv_cb.PENABLE <= 1'b0;

        vif.drv_cb.PADDR   <= req.addr;
        vif.drv_cb.PWRITE  <= req.write;
        vif.drv_cb.PWDATA  <= req.wdata;
        vif.drv_cb.PSTRB   <= req.strb;
        vif.drv_cb.PPROT   <= req.prot;



        // --------------------------------------------------------
        // ACCESS phase
        // --------------------------------------------------------
        @(vif.drv_cb);

        if (!vif.drv_cb.PRESETn) begin

            drive_idle();
            return;

        end


        vif.drv_cb.PENABLE <= 1'b1;



        // --------------------------------------------------------
        // Wait for PREADY
        //
        // If PREADY = 0:
        // remain in ACCESS phase.
        //
        // If PREADY = 1:
        // transaction completes.
        // --------------------------------------------------------
        do begin

            @(vif.drv_cb);

            if (!vif.drv_cb.PRESETn) begin

                drive_idle();
                return;

            end

        end
        while (!vif.drv_cb.PREADY);



        // --------------------------------------------------------
        // Capture APB slave response
        // --------------------------------------------------------
        req.rdata  = vif.drv_cb.PRDATA;
        req.slverr = vif.drv_cb.PSLVERR;



        // --------------------------------------------------------
        // Return to IDLE
        // --------------------------------------------------------
        drive_idle();


    endtask


endclass

`endif