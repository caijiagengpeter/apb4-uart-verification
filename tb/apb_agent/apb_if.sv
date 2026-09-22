`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if(input logic PCLK);

    logic        PRESETn;

    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;

    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;

    logic        PREADY;
    logic        PSLVERR;

    logic [3:0]  PSTRB;
    logic [2:0]  PPROT;


    // ============================================================
    // Driver Clocking Block
    // ============================================================
    clocking drv_cb @(posedge PCLK);

        default input #0 output #1step;

        input  PRESETn;

        input  PRDATA;
        input  PREADY;
        input  PSLVERR;

        output PSEL;
        output PENABLE;
        output PADDR;
        output PWRITE;
        output PWDATA;
        output PSTRB;
        output PPROT;

    endclocking


    // ============================================================
    // Monitor Clocking Block
    // ============================================================
    clocking mon_cb @(posedge PCLK);

        default input #0;

        input PRESETn;

        input PSEL;
        input PENABLE;
        input PADDR;
        input PWRITE;
        input PWDATA;
        input PSTRB;
        input PPROT;

        input PRDATA;
        input PREADY;
        input PSLVERR;

    endclocking


    modport DRIVER (
        clocking drv_cb
    );

    modport MONITOR (
        clocking mon_cb
    );

    modport RESET (
        input  PCLK,
        input  PSEL,
        input  PENABLE,
        output PRESETn
    );

    modport RESET_MONITOR (
        input PCLK,
        input PRESETn
    );


endinterface

`endif