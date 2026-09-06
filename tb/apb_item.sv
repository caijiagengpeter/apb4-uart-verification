`ifndef APB_ITEM_SV
`define APB_ITEM_SV

class apb_item extends uvm_sequence_item;

    rand logic [7:0]  addr;
    rand logic        write;
    rand logic [31:0] wdata;
    rand logic [3:0]  strb;
    rand logic [2:0]  prot;

         logic [31:0] rdata;
         logic        slverr;

    `uvm_object_utils(apb_item)

    function new(string name = "apb_item");
        super.new(name);
    endfunction

endclass

`endif