`ifndef APB_RESET_DURING_TRANSFER_SEQUENCE_SV
`define APB_RESET_DURING_TRANSFER_SEQUENCE_SV

class apb_reset_during_transfer_sequence extends apb_sequence;

    `uvm_object_utils(apb_reset_during_transfer_sequence)

    function new(
        string name = "apb_reset_during_transfer_sequence"
    );
        super.new(name);
    endfunction


    virtual task body();

        `uvm_info(
            "APB_RESET_SEQ",
            "Starting APB write that will be interrupted by reset",
            UVM_LOW
        )

        // BAUD register = 0x10
        // This transaction is intentionally interrupted by reset.
        apb_write(
            8'h10,
            32'hDEAD_BEEF,
            4'b1111,
            3'b000
        );

    endtask

endclass

`endif