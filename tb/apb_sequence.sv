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
            req.addr  == addr;
            req.write == 1'b1;
            req.wdata == data;
            req.strb  == strb;
            req.prot  == prot;
        });

        finish_item(req);

    endtask


    task apb_read(
        input logic [7:0] addr,
        input logic [2:0] prot = 3'b000
    );

        apb_item req;

        req = apb_item::type_id::create("req");

        start_item(req);

        assert(req.randomize() with {
            req.addr  == addr;
            req.write == 1'b0;
            req.prot  == prot;
        });

        finish_item(req);

    endtask


    virtual task body();
        // base sequence 先不做具体操作
    endtask

endclass

`endif