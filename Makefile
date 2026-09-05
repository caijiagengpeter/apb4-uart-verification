VCS = vcs

RTL = \
	dut/rtl/sync_fifo.sv \
	dut/rtl/uart_transmitter.sv \
	dut/rtl/uart_receiver.sv \
	dut/rtl/uart_controller.sv

TB = tb/tb_top.sv

TOP = tb_top

VCS_FLAGS = -full64 -sverilog

all: compile

compile:
	$(VCS) $(VCS_FLAGS) \
		$(RTL) \
		$(TB) \
		-top $(TOP) \
		-o simv

run: compile
	./simv

clean:
	rm -rf simv simv.daidir csrc ucli.key