`ifndef APB_MONITOR__SV
`define APB_MONITOR__SV

class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)


    // Virtual interface
    virtual apb_if.MONITOR vif;


    // Broadcast observed APB transactions
    uvm_analysis_port #(apb_item) ap;



    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "apb_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

    endfunction


    // ============================================================
    // build_phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if.MONITOR)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "APB_MONITOR",
                "Failed to get virtual interface"
            )

        end

    endfunction


    // ============================================================
    // run_phase
    // ============================================================
    task run_phase(uvm_phase phase);

        apb_item tr;

        forever begin


            // Sample APB bus at clocking block event
            @(vif.mon_cb);


            // Ignore bus activity during reset
            if (!vif.mon_cb.PRESETn)
                continue;



            // ----------------------------------------------------
            // One APB transaction completes only when:
            //
            // PSEL    = 1
            // PENABLE = 1
            // PREADY  = 1
            // ----------------------------------------------------
            if (vif.mon_cb.PSEL    &&
                vif.mon_cb.PENABLE &&
                vif.mon_cb.PREADY) begin

/////////////////////////////////////////////////////////////////////////////////////////////
`uvm_info(
    "APB_MON",
    $sformatf(
        "ADDR=0x%02h WRITE=%0b WDATA=0x%08h STRB=0x%h RDATA=0x%08h PREADY=%0b PSLVERR=%0b",
        vif.mon_cb.PADDR,
        vif.mon_cb.PWRITE,
        vif.mon_cb.PWDATA,
        vif.mon_cb.PSTRB,
        vif.mon_cb.PRDATA,
        vif.mon_cb.PREADY,
        vif.mon_cb.PSLVERR
    ),
    UVM_LOW
)


/////////////////////////////////////////////////////////////////////////////////////////////
                // Create one transaction
                tr = apb_item::type_id::create("tr");


                // -----------------------------------------------
                // Sample APB request
                // -----------------------------------------------
                tr.addr   = vif.mon_cb.PADDR;
                tr.write  = vif.mon_cb.PWRITE;
                tr.wdata  = vif.mon_cb.PWDATA;
                tr.strb   = vif.mon_cb.PSTRB;
                tr.prot   = vif.mon_cb.PPROT;


                // -----------------------------------------------
                // Sample APB response
                // -----------------------------------------------
                tr.rdata  = vif.mon_cb.PRDATA;
                tr.slverr = vif.mon_cb.PSLVERR;


                // -----------------------------------------------
                // Broadcast transaction
                //
                // Later:
                //
                // Monitor.ap
                //    ├── Scoreboard
                //    └── Coverage
                // -----------------------------------------------
                ap.write(tr);


            end

        end

    endtask


endclass

`endif