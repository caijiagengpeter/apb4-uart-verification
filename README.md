# APB4 UART Verification

A SystemVerilog/UVM verification project for an APB4 UART controller with FIFO, error-status, and interrupt behavior.

![Final merged coverage summary](docs/images/final_coverage_summary.png)

## Project overview

This project provides a coverage-driven UVM environment for APB4 register transactions, UART transmit/receive behavior, FIFO boundaries and corner cases, error reporting, and interrupts.

## DUT origin and APB4 context

The original/ directory preserves the Vyges source package and Apache-2.0 licensing/origin material. This repository focuses on APB4 verification: UVM agents, scoreboard/reference modeling, assertions, functional coverage, directed tests, and regression support. Repository history records an APB4 UART RTL baseline and APB4 coverage work. The current controller exposes PSTRB and PPROT.

## Verification architecture

- APB agent: compliant APB SETUP/ACCESS driver and monitor.
- UART agent: serial-traffic driver plus TX/RX monitors.
- Scoreboard/reference model: register, FIFO, UART, and status checking.
- Assertions: error propagation, FIFO-read safety, and TX-empty/RX-full IRQ behavior.
- Functional coverage: parity, errors, FIFO states/corners, and interrupts.

## Verified scope

APB register access and byte strobes; UART TX/RX; FIFO empty/middle/full; TX write while full; RX receive while full; RX read while empty; parity modes/errors; frame error; overrun; TX-empty IRQ; and RX-full IRQ are verified. See [verification plan](docs/verification_plan.md).

## Coverage results

Whole-simulation URG totals include UVM/Verdi recording instrumentation, so portfolio interpretation uses DUT scope.

| Scope | Result |
|---|---:|
| Functional coverage groups | **100.00%** |
| Assertion coverage | **100.00%** |
| DUT subtree line / branch / condition / toggle / FSM | **99.15% / 92.86% / 82.65% / 77.81% / 66.67%** |
| uart_controller line / branch / condition / toggle | **100.00% / 100.00% / 83.93% / 66.57%** |

Functional and assertion coverage are complete; condition, toggle, and DUT-subtree FSM coverage retain reviewed gaps. See [coverage summary](docs/coverage_summary.md).

## Known RTL design gaps

- CTRL parity bits feed internal nets, but TX/RX parity uses compile-time parameters; runtime parity control is not implemented.
- PPROT is present but not consumed by controller RTL.
- Some CTRL and INT bits are writable but functionally unused; reset-only fields are distinguished in the coverage summary.

## Build, run, and regression

~~~bash
make compile
make run_test TEST=uart_rx_test
make frame_error
make tx_empty_irq
make rx_full_irq
make coverage_regression
make coverage_full_merge
make verdi
~~~

The Makefile supports parity, error, FIFO, IRQ, and APB register coverage targets. Generated VDB, URG, simulator, and log artifacts are not release content.

## Tools used

SystemVerilog, UVM 1.2, Synopsys VCS, URG, and optional Verdi/FSDB integration.

## Repository structure

~~~text
dut/       UART RTL and submodules
tb/        UVM environment, agents, tests, assertions, coverage
docs/      Coverage analysis, verification plan, and release image
original/  Preserved upstream source and attribution material
Makefile   Compilation, tests, coverage regression, merge, and Verdi flow
~~~

## Future work

Specify runtime parity, PPROT, reserved-register, and unaligned-address intent; add unsupported-access and global-enable robustness tests; and add CI where licensed tools are available.

## Attribution

DUT-origin material and license notices are preserved under original/. The UVM verification environment and project documentation are maintained in this repository.
