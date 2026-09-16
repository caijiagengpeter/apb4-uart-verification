VCS = vcs

export VERDI_HOME = /opt/Synopsys/verdi/V-2023.12-SP2


# ============================================================
# RTL
# ============================================================

RTL = \
	dut/rtl/sync_fifo.sv \
	dut/rtl/uart_transmitter.sv \
	dut/rtl/uart_receiver.sv \
	dut/rtl/uart_controller.sv


# ============================================================
# Testbench compilation units
# ============================================================

TB = \
	tb/apb_agent/apb_if.sv \
	tb/uart_agent/uart_if.sv \
	tb/apb_pkg.sv \
	tb/tb_top.sv

# ============================================================
# Top module
# ============================================================

TOP = tb_top


# ============================================================
# Include directories
# ============================================================

INC_DIRS = \
	+incdir+tb \
	+incdir+tb/apb_agent \
	+incdir+tb/uart_agent \
	+incdir+tb/sequences \
	+incdir+tb/env \
	+incdir+tb/tests \
	+incdir+tb/scoreboard \
	+incdir+tb/assertions


# ============================================================
# Verdi / FSDB PLI
# ============================================================

VERDI_PLI = \
	-P $(VERDI_HOME)/share/PLI/VCS/linux64/novas.tab \
	   $(VERDI_HOME)/share/PLI/VCS/linux64/pli.a


# ============================================================
# VCS flags
# ============================================================

VCS_FLAGS = \
	-full64 \
	-sverilog \
	-timescale=1ns/1ps \
	-ntb_opts uvm-1.2 \
	$(INC_DIRS) \
	-debug_access+all \
	-kdb \
	$(VERDI_PLI)

# ============================================================
# Assertions
# ============================================================

ASSERT = \
	tb/assertions/uart_assertions.sv \
	tb/assertions/uart_bind.sv


# ============================================================
# Targets  +ntb_random_seed_automatic
# ============================================================

all: compile


EXTRA_FLAGS ?=

compile:
	$(VCS) $(VCS_FLAGS) $(EXTRA_FLAGS) \
		$(RTL) \
		$(ASSERT) \
		$(TB) \
		-o simv


compile_parity_even:
	$(MAKE) compile EXTRA_FLAGS="+define+UART_PARITY_EVEN"


compile_parity_odd:
	$(MAKE) compile EXTRA_FLAGS="+define+UART_PARITY_ODD"


run:
	./simv | tee simv.log


run_test:
	./simv +UVM_TESTNAME=$(TEST) | tee simv.log


run_parity_error:
	./simv +UVM_TESTNAME=stat_parity_error_test | tee simv.log


verdi:
	$(VERDI_HOME)/bin/verdi \
		-nologo \
		-dbdir simv.daidir \
		-ssf wave.fsdb &


clean:
	rm -rf \
		simv \
		simv.daidir \
		csrc \
		ucli.key \
		vc_hdrs.h \
		AN.DB \
		verdiLog \
		simv.log \
		wave.fsdb

# ==================================================================
frame_error:
	$(MAKE) clean
	$(MAKE) compile
	./simv +UVM_TESTNAME=stat_frame_error_test | tee simv.log

parity_even_error:
	$(MAKE) clean
	$(MAKE) compile_parity_even
	./simv +UVM_TESTNAME=stat_rx_parity_bit_test | tee simv.log

parity_odd_error:
	$(MAKE) clean
	$(MAKE) compile_parity_odd
	./simv +UVM_TESTNAME=stat_rx_parity_odd_bit_test | tee simv.log