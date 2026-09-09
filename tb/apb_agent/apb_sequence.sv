`ifndef APB_SEQUENCE__SV
`define APB_SEQUENCE__SV

class apb_sequence extends uvm_sequence #(apb_item);

    `uvm_object_utils(apb_sequence)

    function new(string name = "apb_sequence");
        super.new(name);
    endfunction


task apb_write(
    input logic [7:0]  addr,
    input logic [31:0] data,
    input logic [3:0]  strb = 4'b1111,
    input logic [2:0]  prot = 3'b000
);

    apb_item req;

    req = apb_item::type_id::create("req");

    start_item(req);

    assert(req.randomize() with {

        req.addr  == local::addr;
        req.write == 1'b1;
        req.wdata == local::data;
        req.strb  == local::strb;
        req.prot  == local::prot;

    })
    else begin

        `uvm_fatal(
            "APB_SEQ",
            "apb_write randomization failed"
        )

    end

    finish_item(req);

endtask



task apb_read(
    input  logic [7:0]  addr,
    output logic [31:0] data,
    output logic        slverr,
    input  logic [2:0]  prot = 3'b000
);

    apb_item req;

    req = apb_item::type_id::create("req");

    start_item(req);

    assert(req.randomize() with {

        req.addr  == local::addr;
        req.write == 1'b0;

        req.wdata == 32'h0000_0000;
        req.strb  == 4'b0000;

        req.prot  == local::prot;

    })
    else begin

        `uvm_fatal(
            "APB_SEQ",
            "apb_read randomization failed"
        )

    end

    finish_item(req);

    data   = req.rdata;
    slverr = req.slverr;

endtask



    virtual task body();
        // base sequence 先不做具体操作
    endtask

endclass

`endif