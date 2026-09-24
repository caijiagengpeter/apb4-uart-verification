# =============================================================================
# Tool configuration
# =============================================================================

VCS = vcs

export VERDI_HOME = /opt/Synopsys/verdi/V-2023.12-SP2


# =============================================================================
# RTL
# =============================================================================

RTL = \
	dut/rtl/sync_fifo.sv \
	dut/rtl/uart_transmitter.sv \
	dut/rtl/uart_receiver.sv \
	dut/rtl/uart_controller.sv


# =============================================================================
# Testbench compilation units
# =============================================================================

TB = \
	tb/apb_agent/apb_if.sv \
	tb/uart_agent/uart_if.sv \
	tb/coverage/uart_status_if.sv \
	tb/apb_pkg.sv \
	tb/tb_top.sv


# =============================================================================
# Assertions
# =============================================================================

ASSERT = \
	tb/assertions/uart_assertions.sv \
	tb/assertions/uart_bind.sv


# =============================================================================
# Top module
# =============================================================================

TOP = tb_top


# =============================================================================
# Include directories
# =============================================================================

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


# =============================================================================
# Verdi / FSDB PLI
# =============================================================================

VERDI_PLI = \
	-P $(VERDI_HOME)/share/PLI/VCS/linux64/novas.tab \
	$(VERDI_HOME)/share/PLI/VCS/linux64/pli.a


# =============================================================================
# Common VCS flags
#
# IMPORTANT:
# Coverage flags are NOT placed here.
# Normal simulation, coverage simulation and regression are kept separate.
# =============================================================================

VCS_FLAGS = \
	-full64 \
	-sverilog \
	-timescale=1ns/1ps \
	-ntb_opts uvm-1.2 \
	$(INC_DIRS) \
	-debug_access+all \
	-kdb \
	$(VERDI_PLI)


# =============================================================================
# Coverage configuration
# =============================================================================

CM_METRICS = line+cond+fsm+tgl+branch+assert


# =============================================================================
# Optional compile flags
# =============================================================================

EXTRA_FLAGS ?=


# =============================================================================
# General targets
# =============================================================================

.PHONY: all compile compile_parity_even compile_parity_odd

all: compile


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


# =============================================================================
# Normal simulation
# =============================================================================

.PHONY: run run_test

run:
	./simv -l simv.log


run_test:
	./simv \
		+UVM_TESTNAME=$(TEST) \
		-l simv.log


# =============================================================================
# Verdi
# =============================================================================

.PHONY: verdi

verdi:
	$(VERDI_HOME)/bin/verdi \
		-nologo \
		-dbdir simv.daidir \
		-ssf wave.fsdb &


# =============================================================================
# Clean
# =============================================================================

.PHONY: clean clean_coverage clean_regression clean_all

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
		cov_*.vdb \
		urgReport \
		urgReport_*


clean_regression:
	rm -rf \
		regression \
		urgReport_regression


clean_all: clean clean_coverage clean_regression


# =============================================================================
# Directed tests
# =============================================================================

.PHONY: frame_error parity_even parity_odd tx_empty_irq rx_full_irq

frame_error:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=stat_frame_error_test \
		-l simv_frame_error.log


parity_even:
	$(MAKE) clean
	$(MAKE) compile_parity_even
	./simv \
		+UVM_TESTNAME=stat_rx_parity_bit_test \
		-l simv_parity_even.log


parity_odd:
	$(MAKE) clean
	$(MAKE) compile_parity_odd
	./simv \
		+UVM_TESTNAME=stat_rx_parity_odd_bit_test \
		-l simv_parity_odd.log


tx_empty_irq:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=int_tx_empty_test \
		-l simv_tx_empty_irq.log


rx_full_irq:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=int_rx_full_test \
		-l simv_rx_full_irq.log


# =============================================================================
# Generic coverage compile definitions
# =============================================================================

define COMPILE_COVERAGE
	$(VCS) $(VCS_FLAGS) $(1) \
		-cm $(CM_METRICS) \
		-cm_dir $(2) \
		$(RTL) \
		$(ASSERT) \
		$(TB) \
		-o simv
endef


define RUN_COVERAGE
	./simv \
		-cm $(CM_METRICS) \
		-cm_dir $(2) \
		+UVM_TESTNAME=$(1) \
		-l $(3)
endef


# =============================================================================
# Coverage compile targets
# =============================================================================

.PHONY: \
	compile_coverage_even \
	compile_coverage_odd \
	compile_coverage_8n1 \
	compile_coverage_frame_error \
	compile_coverage_overrun \
	compile_coverage_tx_fifo \
	compile_coverage_rx_fifo \
	compile_coverage_tx_irq \
	compile_coverage_rx_irq \
	compile_coverage_tx_parity_even \
	compile_coverage_apb_regs


compile_coverage_even:
	$(call COMPILE_COVERAGE,+define+UART_PARITY_EVEN,cov_even.vdb)


compile_coverage_odd:
	$(call COMPILE_COVERAGE,+define+UART_PARITY_ODD,cov_odd.vdb)


compile_coverage_8n1:
	$(call COMPILE_COVERAGE,,cov_8n1.vdb)


compile_coverage_frame_error:
	$(call COMPILE_COVERAGE,,cov_frame_error.vdb)


compile_coverage_overrun:
	$(call COMPILE_COVERAGE,,cov_overrun.vdb)


compile_coverage_tx_fifo:
	$(call COMPILE_COVERAGE,,cov_tx_fifo.vdb)


compile_coverage_rx_fifo:
	$(call COMPILE_COVERAGE,,cov_rx_fifo.vdb)


compile_coverage_tx_irq:
	$(call COMPILE_COVERAGE,,cov_tx_irq.vdb)


compile_coverage_rx_irq:
	$(call COMPILE_COVERAGE,,cov_rx_irq.vdb)


compile_coverage_tx_parity_even:
	$(call COMPILE_COVERAGE,+define+UART_PARITY_EVEN,cov_tx_parity_even.vdb)


compile_coverage_apb_regs:
	$(call COMPILE_COVERAGE,,cov_apb_regs.vdb)


# =============================================================================
# Coverage runs
# =============================================================================

.PHONY: \
	coverage_even \
	coverage_odd \
	coverage_8n1 \
	coverage_frame_error \
	coverage_overrun \
	coverage_tx_fifo \
	coverage_rx_fifo \
	coverage_tx_irq \
	coverage_rx_irq \
	coverage_tx_parity_even \
	coverage_apb_regs


coverage_even:
	$(MAKE) clean
	rm -rf cov_even.vdb
	$(MAKE) compile_coverage_even
	$(call RUN_COVERAGE,stat_rx_parity_bit_test,cov_even.vdb,simv_even.log)


coverage_odd:
	$(MAKE) clean
	rm -rf cov_odd.vdb
	$(MAKE) compile_coverage_odd
	$(call RUN_COVERAGE,stat_rx_parity_odd_bit_test,cov_odd.vdb,simv_odd.log)


coverage_8n1:
	$(MAKE) clean
	rm -rf cov_8n1.vdb
	$(MAKE) compile_coverage_8n1
	$(call RUN_COVERAGE,uart_rx_test,cov_8n1.vdb,simv_8n1.log)


coverage_frame_error:
	$(MAKE) clean
	rm -rf cov_frame_error.vdb
	$(MAKE) compile_coverage_frame_error
	$(call RUN_COVERAGE,stat_frame_error_test,cov_frame_error.vdb,simv_frame_error.log)


coverage_overrun:
	$(MAKE) clean
	rm -rf cov_overrun.vdb
	$(MAKE) compile_coverage_overrun
	$(call RUN_COVERAGE,uart_rx_fifo_boundary_test,cov_overrun.vdb,simv_overrun.log)


coverage_tx_fifo:
	$(MAKE) clean
	rm -rf cov_tx_fifo.vdb
	$(MAKE) compile_coverage_tx_fifo
	$(call RUN_COVERAGE,uart_tx_fifo_boundary_test,cov_tx_fifo.vdb,simv_tx_fifo.log)


coverage_rx_fifo:
	$(MAKE) clean
	rm -rf cov_rx_fifo.vdb
	$(MAKE) compile_coverage_rx_fifo
	$(call RUN_COVERAGE,uart_rx_fifo_boundary_test,cov_rx_fifo.vdb,simv_rx_fifo.log)


coverage_tx_irq:
	$(MAKE) clean
	rm -rf cov_tx_irq.vdb
	$(MAKE) compile_coverage_tx_irq
	$(call RUN_COVERAGE,int_tx_empty_test,cov_tx_irq.vdb,simv_tx_irq.log)


coverage_rx_irq:
	$(MAKE) clean
	rm -rf cov_rx_irq.vdb
	$(MAKE) compile_coverage_rx_irq
	$(call RUN_COVERAGE,int_rx_full_test,cov_rx_irq.vdb,simv_rx_irq.log)


coverage_tx_parity_even:
	$(MAKE) clean
	rm -rf cov_tx_parity_even.vdb
	$(MAKE) compile_coverage_tx_parity_even
	$(call RUN_COVERAGE,uart_tx_parity_test,cov_tx_parity_even.vdb,simv_tx_parity_even.log)


coverage_apb_regs:
	$(MAKE) clean
	rm -rf cov_apb_regs.vdb
	$(MAKE) compile_coverage_apb_regs
	$(call RUN_COVERAGE,apb_register_access_test,cov_apb_regs.vdb,simv_apb_regs.log)


# =============================================================================
# IRQ coverage merge
# =============================================================================

.PHONY: coverage_irq_merge

coverage_irq_merge:
	rm -rf urgReport_irq
	urg \
		-full64 \
		-dir cov_tx_irq.vdb \
		-dir cov_rx_irq.vdb \
		-report urgReport_irq


# =============================================================================
# Corner-case directed tests
# =============================================================================

.PHONY: \
	compile_apb_unsupported \
	run_apb_unsupported \
	run_apb_reset \
	run_uart_tx_reset \
	run_uart_rx_reset \
	run_uart_simultaneous


compile_apb_unsupported:
	$(MAKE) compile


run_apb_unsupported:
	$(MAKE) clean
	$(MAKE) compile_apb_unsupported
	./simv \
		+UVM_TESTNAME=apb_unsupported_access_test \
		-l simv_apb_unsupported.log


run_apb_reset:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=apb_reset_during_transfer_test \
		-l simv_apb_reset.log


run_uart_tx_reset:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=uart_tx_reset_test \
		-l simv_uart_tx_reset.log


run_uart_rx_reset:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=uart_rx_reset_test \
		-l simv_uart_rx_reset.log


run_uart_simultaneous:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=uart_simultaneous_tx_rx_test \
		-l simv_uart_simultaneous.log


# =============================================================================
# Hardening regression
#
# These tests all use the default 8N1/non-parity DUT configuration,
# therefore they can share one compiled simv executable.
# =============================================================================

REGRESSION_TESTS = \
	apb_register_access_test \
	apb_unsupported_access_test \
	apb_reset_during_transfer_test \
	uart_tx_reset_test \
	uart_rx_reset_test \
	uart_simultaneous_tx_rx_test \
	uart_global_disable_tx_test


REG_DIR         = regression
REG_LOG_DIR     = $(REG_DIR)/logs
REG_COV_DIR     = $(REG_DIR)/coverage
REG_COMPILE_VDB = $(REG_DIR)/compile.vdb
REG_URG_DIR     = urgReport_regression


# =============================================================================
# Regression coverage compile
# =============================================================================

.PHONY: compile_regression

compile_regression:
	mkdir -p $(REG_LOG_DIR)
	mkdir -p $(REG_COV_DIR)

	$(VCS) $(VCS_FLAGS) \
		-cm $(CM_METRICS) \
		-cm_dir $(REG_COMPILE_VDB) \
		$(RTL) \
		$(ASSERT) \
		$(TB) \
		-o simv


# =============================================================================
# Regression
# =============================================================================

.PHONY: regression

regression:
	$(MAKE) clean
	$(MAKE) clean_regression

	mkdir -p $(REG_LOG_DIR)
	mkdir -p $(REG_COV_DIR)

	$(MAKE) compile_regression

	@echo ""
	@echo "============================================================"
	@echo " Starting UART APB4 UVM regression"
	@echo "============================================================"
	@echo ""

	@fail_count=0; \
	for test in $(REGRESSION_TESTS); do \
		echo ""; \
		echo "============================================================"; \
		echo " RUNNING: $$test"; \
		echo "============================================================"; \
		echo ""; \
		rc=0; \
		./simv \
			+UVM_TESTNAME=$$test \
			-cm $(CM_METRICS) \
			-cm_dir $(REG_COV_DIR)/$$test.vdb \
			-cm_name $$test \
			-l $(REG_LOG_DIR)/$$test.log \
			|| rc=$$?; \
		if [ $$rc -ne 0 ]; then \
			echo "[FAIL] $$test : simulator return code $$rc"; \
			fail_count=$$((fail_count + 1)); \
		elif grep -Eq \
			'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9][0-9]*' \
			$(REG_LOG_DIR)/$$test.log; then \
			echo "[FAIL] $$test : UVM_ERROR/UVM_FATAL detected"; \
			fail_count=$$((fail_count + 1)); \
		else \
			echo "[PASS] $$test"; \
		fi; \
	done; \
	echo ""; \
	echo "============================================================"; \
	echo " Regression finished"; \
	echo " Failures: $$fail_count"; \
	echo "============================================================"; \
	if [ $$fail_count -ne 0 ]; then \
		exit 1; \
	fi

	$(MAKE) regression_merge


# =============================================================================
# Merge regression coverage databases
# =============================================================================

.PHONY: regression_merge

regression_merge:
	@echo ""
	@echo "============================================================"
	@echo " Merging regression coverage"
	@echo "============================================================"
	@echo ""

	rm -rf $(REG_URG_DIR)

	@dirs=""; \
	for vdb in $(REG_COV_DIR)/*.vdb; do \
		dirs="$$dirs -dir $$vdb"; \
	done; \
	urg \
		-full64 \
		$$dirs \
		-report $(REG_URG_DIR)

	@echo ""
	@echo "Merged coverage report:"
	@echo "  $(REG_URG_DIR)"
	@echo ""

	$(MAKE) regression_summary


# =============================================================================
# Regression summary
# =============================================================================

.PHONY: regression_summary

regression_summary:
	@echo ""
	@echo "============================================================"
	@echo " UVM REGRESSION SUMMARY"
	@echo "============================================================"
	@echo ""

	@for test in $(REGRESSION_TESTS); do \
		log="$(REG_LOG_DIR)/$$test.log"; \
		printf "%-42s " "$$test"; \
		if [ ! -f "$$log" ]; then \
			echo "FAIL (missing log)"; \
		elif grep -Eq \
			'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9][0-9]*' \
			"$$log"; then \
			echo "FAIL"; \
		else \
			echo "PASS"; \
		fi; \
	done

	@echo ""
	@echo "============================================================"
	@echo " APB SVA COVERAGE HITS BY TEST"
	@echo "============================================================"
	@echo ""

	@for test in $(REGRESSION_TESTS); do \
		log="$(REG_LOG_DIR)/$$test.log"; \
		echo "---------------- $$test ----------------"; \
		grep "\[APB_SVA_COV\]" "$$log" || true; \
		echo ""; \
	done

	@echo "============================================================"
	@echo " Merged URG report"
	@echo "============================================================"
	@echo " $(REG_URG_DIR)"
	@echo ""


# =============================================================================
# Default coverage report
# =============================================================================

.PHONY: coverage_report

coverage_report:
	urg \
		-full64 \
		-dir simv.vdb \
		-report urgReport

# =============================================================================
# Final full coverage regression
#
# Runs all meaningful coverage scenarios using the current code base,
# then merges their VDBs together with the hardening regression VDBs.
#
# NOTE:
#   coverage_overrun is not run separately here because
#   uart_rx_fifo_boundary_test is already exercised by coverage_rx_fifo
#   and covers the overrun scenario as part of the same test.
#
#   coverage_apb_regs is also not run separately because
#   apb_register_access_test is already included in the hardening regression.
# =============================================================================

FINAL_URG_DIR = urgReport_final


.PHONY: final_coverage final_merge final_summary


final_coverage:
	@echo ""
	@echo "============================================================"
	@echo " Starting FINAL UART APB4 coverage regression"
	@echo "============================================================"
	@echo ""

	$(MAKE) clean_coverage
	$(MAKE) clean_regression

	@echo ""
	@echo "============================================================"
	@echo " 1/10 - UART 8N1 RX"
	@echo "============================================================"
	$(MAKE) coverage_8n1

	@echo ""
	@echo "============================================================"
	@echo " 2/10 - RX parity even"
	@echo "============================================================"
	$(MAKE) coverage_even

	@echo ""
	@echo "============================================================"
	@echo " 3/10 - RX parity odd"
	@echo "============================================================"
	$(MAKE) coverage_odd

	@echo ""
	@echo "============================================================"
	@echo " 4/10 - Frame error"
	@echo "============================================================"
	$(MAKE) coverage_frame_error

	@echo ""
	@echo "============================================================"
	@echo " 5/10 - TX FIFO boundary"
	@echo "============================================================"
	$(MAKE) coverage_tx_fifo

	@echo ""
	@echo "============================================================"
	@echo " 6/10 - RX FIFO boundary / overrun"
	@echo "============================================================"
	$(MAKE) coverage_rx_fifo

	@echo ""
	@echo "============================================================"
	@echo " 7/10 - TX EMPTY IRQ"
	@echo "============================================================"
	$(MAKE) coverage_tx_irq

	@echo ""
	@echo "============================================================"
	@echo " 8/10 - RX FULL IRQ"
	@echo "============================================================"
	$(MAKE) coverage_rx_irq

	@echo ""
	@echo "============================================================"
	@echo " 9/10 - TX parity even"
	@echo "============================================================"
	$(MAKE) coverage_tx_parity_even

	@echo ""
	@echo "============================================================"
	@echo " 10/10 - APB/reset/full-duplex hardening regression"
	@echo "============================================================"
	$(MAKE) regression

	@echo ""
	@echo "============================================================"
	@echo " All final tests completed successfully"
	@echo "============================================================"
	@echo ""

	$(MAKE) final_merge


# =============================================================================
# Final merge
# =============================================================================

final_merge:
	@echo ""
	@echo "============================================================"
	@echo " Merging ALL final coverage databases"
	@echo "============================================================"
	@echo ""

	rm -rf $(FINAL_URG_DIR)

	@dirs=""; \
	for vdb in \
		cov_8n1.vdb \
		cov_even.vdb \
		cov_odd.vdb \
		cov_frame_error.vdb \
		cov_tx_fifo.vdb \
		cov_rx_fifo.vdb \
		cov_tx_irq.vdb \
		cov_rx_irq.vdb \
		cov_tx_parity_even.vdb \
		regression/coverage/*.vdb; do \
		if [ -d "$$vdb" ]; then \
			echo "Adding coverage database: $$vdb"; \
			dirs="$$dirs -dir $$vdb"; \
		fi; \
	done; \
	if [ -z "$$dirs" ]; then \
		echo "ERROR: No coverage databases found"; \
		exit 1; \
	fi; \
	urg \
		-full64 \
		$$dirs \
		-report $(FINAL_URG_DIR)

	@echo ""
	@echo "============================================================"
	@echo " FINAL coverage merge complete"
	@echo " Report directory: $(FINAL_URG_DIR)"
	@echo "============================================================"
	@echo ""

	$(MAKE) final_summary


# =============================================================================
# Final result summary
# =============================================================================

final_summary:
	@echo ""
	@echo "============================================================"
	@echo " FINAL HARDENING REGRESSION SUMMARY"
	@echo "============================================================"
	@echo ""

	@for test in $(REGRESSION_TESTS); do \
		log="$(REG_LOG_DIR)/$$test.log"; \
		printf "%-42s " "$$test"; \
		if [ ! -f "$$log" ]; then \
			echo "MISSING LOG"; \
		elif grep -Eq \
			'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9][0-9]*' \
			"$$log"; then \
			echo "FAIL"; \
		else \
			echo "PASS"; \
		fi; \
	done

	@echo ""
	@echo "============================================================"
	@echo " FINAL APB SVA COVERAGE"
	@echo "============================================================"
	@echo ""

	@grep -h "\[APB_SVA_COV\]" \
		$(REG_LOG_DIR)/*.log \
		|| true

	@echo ""
	@echo "============================================================"
	@echo " FINAL SVA SUMMARY"
	@echo "============================================================"
	@echo ""

	@grep -h "\[SVA_SUMMARY\]" \
		$(REG_LOG_DIR)/*.log \
		|| true

	@echo ""
	@echo "============================================================"
	@echo " Final URG report:"
	@echo " $(FINAL_URG_DIR)"
	@echo "============================================================"
	@echo ""

.PHONY: run_uart_global_disable_tx

run_uart_global_disable_tx:
	$(MAKE) clean
	$(MAKE) compile
	./simv \
		+UVM_TESTNAME=uart_global_disable_tx_test \
		-l simv_uart_global_disable_tx.log