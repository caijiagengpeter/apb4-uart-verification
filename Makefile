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
	+incdir+tb/tests\
	+incdir+tb/scoreboard


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
# Targets
# ============================================================

all: compile


compile:
	$(VCS) $(VCS_FLAGS) \
		$(RTL) \
		$(TB) \
		-top $(TOP) \
		-o simv


run: compile
	./simv


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
		verdiLog