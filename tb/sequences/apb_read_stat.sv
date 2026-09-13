`ifndef APB_READ_STAT_SV
`define APB_READ_STAT_SV

class apb_read_stat extends apb_sequence;

    `uvm_object_utils(apb_read_stat)

    logic [31:0] rdata;
    logic        slverr;

    function new(string name = "apb_read_stat");
        super.new(name);
    endfunction

    task body();

        apb_read(
            8'h04,
            rdata,
            slverr
        );

        `uvm_info(
            "APB_READ_STAT",
            $sformatf(
                "STAT read: rdata=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_MEDIUM
        )

    endtask

endclass

`endif