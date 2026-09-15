`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

class uart_sequence extends uvm_sequence #(uart_item);

    `uvm_object_utils(uart_sequence)

    function new(string name = "uart_sequence");
        super.new(name);
    endfunction

    task send_uart(
        input logic [7:0] data,
        input bit inject_frame_error = 1'b0
    );
    
        uart_item req;
    
        req = uart_item::type_id::create("req");
    
        start_item(req);
    
        assert(req.randomize() with {
            data               == local::data;
            inject_frame_error == local::inject_frame_error;
        })
        else
            `uvm_fatal(
                "UART_SEQUENCE",
                "uart_item randomization failed"
            )
    
        finish_item(req);
    
    endtask

    task body();
    ///////////////////
    endtask

endclass

`endif