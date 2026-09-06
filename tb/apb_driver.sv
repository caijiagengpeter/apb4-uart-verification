class apb_driver extends uvm_driver #(apb_item);

    `uvm_component_utils(apb_driver)

    virtual apb_if.DRIVER vif;

    function new(string name = "apb_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction



























endclass