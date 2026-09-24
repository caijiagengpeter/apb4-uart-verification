`ifndef APB_CTRL_WRITE_SEQUENCE_SV
`define APB_CTRL_WRITE_SEQUENCE_SV

class apb_ctrl_write_sequence extends apb_sequence;

    `uvm_object_utils(apb_ctrl_write_sequence)

    logic [31:0] ctrl_value;


    function new(string name = "apb_ctrl_write_sequence");
        super.new(name);
        ctrl_value = 32'h0;
    endfunction


    virtual task body();

        `uvm_info(
            "APB_CTRL_WRITE",
            $sformatf(
                "Writing CTRL = 0x%08h",
                ctrl_value
            ),
            UVM_MEDIUM
        )

        apb_write(
            8'h00,          // CTRL
            ctrl_value,
            4'b0001,
            3'b000
        );

    endtask

endclass

`endif