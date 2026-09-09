`ifndef APB_READ_SEQUENCE_SV
`define APB_READ_SEQUENCE_SV

class apb_read_sequence extends apb_sequence;

    `uvm_object_utils(apb_read_sequence)

    function new(string name = "apb_read_sequence");
        super.new(name);
    endfunction

    task body();
    
        logic [31:0] rdata;
        logic        slverr;
    
        `uvm_info(
            "APB_READ_SEQ",
            "Starting APB read sequence",
            UVM_MEDIUM
        )
    
        apb_read(
            8'h0C,
            rdata,
            slverr
        );
    
        `uvm_info(
            "APB_READ_SEQ",
            $sformatf(
                "RXDATA read: rdata=0x%08h slverr=%0b",
                rdata,
                slverr
            ),
            UVM_MEDIUM
        )
    
    endtask

endclass

`endif