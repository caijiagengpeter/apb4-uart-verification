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
tb/coverage/uart_status_if.sv \
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
+incdir+tb/assertions \
+incdir+tb/coverage


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
# Coverage flags
# ============================================================

CM_FLAGS = \
-cm line+cond+fsm+tgl+branch \
-cm_dir simv.vdb


# ============================================================
# Assertions
# ============================================================

ASSERT = \
tb/assertions/uart_assertions.sv \
tb/assertions/uart_bind.sv


# ============================================================
# General targets
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


# ============================================================
# Verdi
# ============================================================

verdi:
	$(VERDI_HOME)/bin/verdi \
	-nologo \
	-dbdir simv.daidir \
	-ssf wave.fsdb &


# ============================================================
# Clean
# ============================================================

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


clean_coverage:
	rm -rf \
	simv.vdb \
	urgReport


# ============================================================
# Directed tests
# ============================================================

frame_error:
	$(MAKE) clean
	$(MAKE) compile
	./simv +UVM_TESTNAME=stat_frame_error_test | tee simv.log


parity_even:
	$(MAKE) clean
	$(MAKE) compile_parity_even
	./simv +UVM_TESTNAME=stat_rx_parity_bit_test | tee simv.log


parity_odd:
	$(MAKE) clean
	$(MAKE) compile_parity_odd
	./simv +UVM_TESTNAME=stat_rx_parity_odd_bit_test | tee simv.log


tx_empty_irq:
	$(MAKE) clean
	$(MAKE) compile
	./simv +UVM_TESTNAME=int_tx_empty_test | tee simv.log


rx_full_irq:
	$(MAKE) clean
	$(MAKE) compile
	./simv +UVM_TESTNAME=int_rx_full_test | tee simv.log


# ============================================================
# Coverage compile
# ============================================================

compile_coverage_even:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_even.vdb \
	+define+UART_PARITY_EVEN \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


compile_coverage_odd:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_odd.vdb \
	+define+UART_PARITY_ODD \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


compile_coverage_8n1:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_8n1.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv

# ============================================================
# Coverage runs
# ============================================================

coverage_even:
	$(MAKE) clean
	rm -rf cov_even.vdb
	$(MAKE) compile_coverage_even
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_even.vdb \
	+UVM_TESTNAME=stat_rx_parity_bit_test \
	| tee simv.log


coverage_odd:
	$(MAKE) clean
	rm -rf cov_odd.vdb
	$(MAKE) compile_coverage_odd
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_odd.vdb \
	+UVM_TESTNAME=stat_rx_parity_odd_bit_test \
	| tee simv.log

coverage_8n1:
	$(MAKE) clean
	rm -rf cov_8n1.vdb
	$(MAKE) compile_coverage_8n1
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_8n1.vdb \
	+UVM_TESTNAME=uart_rx_test \
	| tee simv.log

compile_coverage_frame_error:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_frame_error.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


coverage_frame_error:
	$(MAKE) clean
	rm -rf cov_frame_error.vdb
	$(MAKE) compile_coverage_frame_error
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_frame_error.vdb \
	+UVM_TESTNAME=stat_frame_error_test \
	| tee simv.log

compile_coverage_overrun:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_overrun.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv

coverage_overrun:
	$(MAKE) clean
	rm -rf cov_overrun.vdb
	$(MAKE) compile_coverage_overrun
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_overrun.vdb \
	+UVM_TESTNAME=uart_rx_fifo_boundary_test \
	| tee simv.log

compile_coverage_tx_fifo:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_fifo.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv

compile_coverage_rx_fifo:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_rx_fifo.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv

coverage_tx_fifo:
	$(MAKE) clean
	rm -rf cov_tx_fifo.vdb
	$(MAKE) compile_coverage_tx_fifo
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_fifo.vdb \
	+UVM_TESTNAME=uart_tx_fifo_boundary_test \
	| tee simv.log

coverage_rx_fifo:
	$(MAKE) clean
	rm -rf cov_rx_fifo.vdb
	$(MAKE) compile_coverage_rx_fifo
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_rx_fifo.vdb \
	+UVM_TESTNAME=uart_rx_fifo_boundary_test \
	| tee simv.log


# ============================================================
# IRQ functional coverage
# ============================================================

compile_coverage_tx_irq:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_irq.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


compile_coverage_rx_irq:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_rx_irq.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


coverage_tx_irq:
	$(MAKE) clean
	rm -rf cov_tx_irq.vdb
	$(MAKE) compile_coverage_tx_irq
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_irq.vdb \
	+UVM_TESTNAME=int_tx_empty_test \
	| tee simv_tx_irq.log


coverage_rx_irq:
	$(MAKE) clean
	rm -rf cov_rx_irq.vdb
	$(MAKE) compile_coverage_rx_irq
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_rx_irq.vdb \
	+UVM_TESTNAME=int_rx_full_test \
	| tee simv_rx_irq.log


coverage_irq_merge:
	rm -rf urgReport_irq
	urg \
	-dir cov_tx_irq.vdb cov_rx_irq.vdb \
	-report urgReport_irq

# ============================================================================ Temporay
compile_coverage_tx_parity_even:
	$(VCS) $(VCS_FLAGS) \
	+define+UART_PARITY_EVEN \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_parity_even.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv

coverage_tx_parity_even:
	$(MAKE) clean
	rm -rf cov_tx_parity_even.vdb
	$(MAKE) compile_coverage_tx_parity_even
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_tx_parity_even.vdb \
	+UVM_TESTNAME=uart_tx_parity_test \
	| tee simv_tx_parity_even.log

# APB register access coverage============================================================

compile_coverage_apb_regs:
	$(VCS) $(VCS_FLAGS) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_apb_regs.vdb \
	$(RTL) \
	$(ASSERT) \
	$(TB) \
	-o simv


coverage_apb_regs:
	$(MAKE) clean
	rm -rf cov_apb_regs.vdb
	$(MAKE) compile_coverage_apb_regs
	./simv \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir cov_apb_regs.vdb \
	+UVM_TESTNAME=apb_register_access_test \
	| tee simv_apb_regs.log

# ============================================================
# Full Functional Coverage Regression
# ============================================================

coverage_regression:
	@echo "========================================"
	@echo " Running UART functional coverage regression"
	@echo "========================================"

	rm -rf cov_8n1.vdb
	rm -rf cov_even.vdb
	rm -rf cov_odd.vdb
	rm -rf cov_frame_error.vdb
	rm -rf cov_overrun.vdb
	rm -rf cov_tx_fifo.vdb
	rm -rf cov_rx_fifo.vdb
	rm -rf cov_tx_irq.vdb
	rm -rf cov_rx_irq.vdb
	rm -rf urgReport_full

	$(MAKE) coverage_8n1
	$(MAKE) coverage_even
	$(MAKE) coverage_odd
	$(MAKE) coverage_frame_error
	$(MAKE) coverage_overrun
	$(MAKE) coverage_tx_fifo
	$(MAKE) coverage_rx_fifo
	$(MAKE) coverage_tx_irq
	$(MAKE) coverage_rx_irq

coverage_full_merge:
	rm -rf urgReport_full_v3
	urg \
	-dir cov_8n1.vdb \
	     cov_even.vdb \
	     cov_odd.vdb \
	     cov_frame_error.vdb \
	     cov_overrun.vdb \
	     cov_tx_fifo.vdb \
	     cov_rx_fifo.vdb \
	     cov_tx_irq.vdb \
	     cov_rx_irq.vdb \
	     cov_tx_parity_even.vdb \
	     cov_apb_regs.vdb \
	-report urgReport_full_v3

	@echo "========================================"
	@echo " Regression finished"
	@echo " Coverage report: urgReport_full"
	@echo "========================================"


# ============================================================
# Coverage report
# ============================================================

coverage_report:
	urg \
	-dir simv.vdb \
	-report urgReport
