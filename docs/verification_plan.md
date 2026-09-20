# Verification Plan

## 1. Scope

This plan covers the implemented APB4 UART verification environment.

- APB4 slave interface and register behavior
- UART transmit and receive behavior
- TX/RX FIFO behavior, boundaries, and corner cases
- TX-empty and RX-full interrupts
- Parity, frame-error, and overrun handling

## 2. Verification Architecture

The APB agent drives compliant SETUP/ACCESS transfers and monitors bus activity. The UART agent drives serial traffic and monitors TX/RX transactions. The scoreboard and UART reference model compare modeled register, FIFO, UART, and status behavior. The DUT status monitor publishes overrun and IRQ events. Bound assertions check error propagation, empty-RX-FIFO reads, and interrupt behavior. Functional coverage samples parity, errors, FIFO occupancy/corners, and interrupts.

## 3. Verification Matrix

| Feature | Stimulus / Test | Checker | Assertion | Functional Coverage | Status |
|---|---|---|---|---|---|
| APB normal read | APB read/register sequences | Scoreboard/reference model | - | Register scenarios | Covered |
| APB normal write | APB write/register sequences | Scoreboard/reference model | - | Register scenarios | Covered |
| Illegal address access | Unsupported-address path | APB response checking | - | - | Partially Covered |
| PSTRB behavior | APB register-access sequence | Scoreboard/reference model | - | Implemented byte-write paths | Covered |
| CTRL register | APB register-access sequence | Scoreboard/reference model | - | Register scenarios | Covered |
| STAT register | Status and error tests | Scoreboard/status checking | Error propagation | Status scenarios | Covered |
| BAUD register | Register-access sequence | APB response checking | - | - | Partially Covered |
| FIFO register | Register-access sequence | APB response checking | - | - | Partially Covered |
| INT register | TX/RX IRQ tests | Status monitor/scoreboard | IRQ assertions | IRQ coverage | Covered |
| UART TX single byte | uart_tx_test | UART monitor/scoreboard | - | Transaction samples | Covered |
| UART TX multi-byte | UART TX multi-byte sequences | UART monitor/scoreboard | - | Transaction samples | Covered |
| UART RX single byte | uart_rx_test | UART monitor/scoreboard | - | Transaction samples | Covered |
| UART RX multi-byte | UART RX multi-byte/gap tests | UART monitor/scoreboard | - | Transaction samples | Covered |
| TX FIFO empty/middle/full | uart_tx_fifo_boundary_test | FIFO model/monitor | - | Occupancy bins | Covered |
| RX FIFO empty/middle/full | uart_rx_fifo_boundary_test | FIFO model/monitor | Empty-read safety | Occupancy bins | Covered |
| TX write while FIFO full | TX FIFO boundary test | FIFO corner monitor | - | TX-full bin | Covered |
| RX receive while FIFO full | RX FIFO boundary test | Status monitor | Overrun | RX-full/overrun bins | Covered |
| RXDATA read while FIFO empty | RX FIFO boundary test | FIFO corner monitor | No-read-when-empty | Empty-read bin | Covered |
| TX busy | stat_tx_busy_bit_test | Status checking | - | - | Covered |
| RX busy | stat_rx_busy_bit_test | Status checking | - | - | Covered |
| Frame error | stat_frame_error_test | Status checking | Frame-error propagation | Frame-error bin | Covered |
| Overrun error | RX FIFO boundary test | Status checking | Overrun/no-spurious | Overrun bin | Covered |
| Parity disabled | UART mode tests | UART monitor/scoreboard | - | Parity mode bin | Covered |
| Even parity | stat_rx_parity_bit_test | UART monitor/scoreboard | Parity propagation | Mode/error cross | Covered |
| Odd parity | stat_rx_parity_odd_bit_test | UART monitor/scoreboard | Parity propagation | Mode/error cross | Covered |
| Parity error injection | Parity error tests | UART monitor/status checking | Parity propagation | Error bin/cross | Covered |
| TX_EMPTY interrupt | int_tx_empty_test | Status monitor/scoreboard | TX IRQ/no-spurious | TX IRQ bin | Covered |
| RX_FULL interrupt | int_rx_full_test | Status monitor/scoreboard | RX IRQ/no-spurious | RX IRQ bin | Covered |
| Reset behavior | Base-test reset and all tests | UVM environment | Assertion disable during reset | - | Covered |

## 4. Coverage Closure Strategy

Defined functional coverage goals are currently 100%, and assertion coverage is currently 100%. Remaining code-coverage holes are reviewed individually. Protocol-unreachable, reserved, constant, unused, specification-dependent, and RTL-design-gap cases are documented rather than artificially forced. Detailed analysis is in [coverage_summary.md](coverage_summary.md).

## 5. Known Design Gaps / Limitations

- CTRL parity configuration bits decode into internal nets but do not dynamically configure TX/RX parity.
- UART parity behavior is controlled by compile-time parameters.
- PPROT is present but unused by controller RTL.
- CTRL and INT contain writable bits with no functional consumer.
- BAUD and FIFO software registers are stored/read through APB, while UART/FIFO implementation behavior is parameterized; dynamic control is not established by current RTL.

## 6. Regression / Exit Criteria

- UVM_ERROR = 0 and UVM_FATAL = 0.
- Defined functional coverage goals = 100%.
- Defined assertion coverage goals = 100%.
- Code-coverage holes are reviewed and classified in the coverage summary.
- No DUT modification is made solely for coverage improvement.

Run make coverage_regression followed by make coverage_full_merge to reproduce the directed coverage flow and merged URG report.
