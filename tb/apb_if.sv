`ifndef APB_IF__SV
`define APB_IF__SV

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

modport DRIVER (
    input  PCLK,
    input  PRESETn,
    input  PRDATA,
    input  PREADY,
    input  PSLVERR,

    output PSEL,
    output PENABLE,
    output PADDR,
    output PWRITE,
    output PWDATA,
    output PSTRB,
    output PPROT
);


modport MONITOR (
    input PCLK,
    input PRESETn,
    input PSEL,
    input PENABLE,
    input PADDR,
    input PWRITE,
    input PWDATA,
    input PSTRB,
    input PPROT,
    input PRDATA,
    input PREADY,
    input PSLVERR
);

endinterface

`endif