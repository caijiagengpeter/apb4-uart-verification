# APB4 UART Coverage Summary

## Scope and evidence

This summary is based on the current RTL, UVM environment, assertions, functional covergroups, and latest merged URG report, `urgReport_full_v4` (11 tests; generated September 20, 2026). The regression covers UART modes, parity modes/errors, frame error, overrun, FIFO boundaries, TX-empty/RX-full interrupts, and APB register access. Functional coverage is in `tb/coverage/uart_coverage.sv`; assertions are in `tb/assertions/uart_assertions.sv`.

## Final coverage status

Controller-only values are from `urgReport_full_v4/mod14.html` for `tb_top.dut`. DUT-subtree values are the URG hierarchy roll-up, including the controller, FIFOs, transmitter, receiver, and bound assertions.

| Scope | Metric | Result |
|---|---|---:|
| Verification model | Functional coverage (groups) | **100.00%** |
| Assertions | Assertion coverage | **100.00%** |
| `uart_controller` | Line coverage | **100.00%** |
| `uart_controller` | Branch coverage | **100.00%** |
| `uart_controller` | Condition coverage | **83.93%** |
| `uart_controller` | Toggle coverage | **66.57%** |
| DUT subtree (`tb_top.dut`) | Line coverage | **99.15%** |
| DUT subtree (`tb_top.dut`) | Branch coverage | **92.86%** |
| DUT subtree (`tb_top.dut`) | FSM coverage | **66.67%** |

The controller has no standalone FSM metric in this report. Functional and assertion coverage are complete, but condition, toggle, and DUT-subtree FSM coverage retain reviewed gaps; this is not a claim of 100% code coverage.

## Coverage Waiver / Exclusion Analysis

**Status guide:** **Covered** is measured in the merged run. A **candidate for exclusion** needs a documented rationale. **Protocol-unreachable** applies only to the compliant APB-master scope. **Specification-dependent** and **review required** need an IP-spec decision. **Real verification hole / follow-up test**, **RTL design gap**, **unused implementation signal**, and **reserved/constant** are retained as separate engineering classifications.

| Coverage Type | Signal / Condition | Status | Rationale |
|---|---|---|---|
| Toggle | `paddr_i[1:0]` | **Specification-dependent / review required** | The register map uses 32-bit-aligned addresses. If the IP permits aligned accesses only, these bits are a candidate for exclusion. If unsupported/unaligned accesses must return `PSLVERR`, add a robustness test; unmatched addresses drive the RTL default `pslverr_o` path. |
| Toggle | `pprot_i[2:0]` | **Unused implementation signal** | Declared and connected in `tb_top`, but not consumed by controller RTL. Exclude only if intentionally ignoring APB protection attributes is specified for this IP; otherwise review is required. |
| Toggle | `ctrl_reg[4:3]` / `ctrl_parity_en`, `ctrl_parity_odd` | **RTL design gap** | CTRL[3:4] feed these nets, but neither is consumed by the TX/RX datapath. Parity uses static `PARITY_ENABLE` and `PARITY_TYPE` parameters; runtime parity controls are not implemented. |
| Toggle | `ctrl_reg[7:5]` | **Review required** | The CTRL path writes [7:0] and reads the full register, but [7:5] have no RTL consumer. They are writable/readable, functionally unused state; do not waive without a specification decision. |
| Toggle | `ctrl_reg[31:8]` | **Reserved/constant - candidate for exclusion** | Reset clears the full register and the only CTRL write targets [7:0], so this range is reset-only in current RTL. |
| Toggle | `stat_reg[31:7]` | **Reserved/constant - candidate for exclusion** | RTL explicitly assigns `stat_reg[31:7] = 25'h0`; status is implemented only in [6:0]. |
| Toggle | `int_reg[1:0]` | **Covered** | These enable bits are written, read back, and drive `int_tx_empty_en` and `int_rx_full_en`. |
| Toggle | `int_reg[7:2]` | **Review required** | The INT path writes [7:0], but only [1:0] are consumed or read back. [7:2] are writable, functionally unused state, not reset-only constants. |
| Toggle | `int_reg[31:8]` | **Reserved/constant - candidate for exclusion** | Reset clears the full register and the only INT write targets [7:0], making this range reset-only. |
| Toggle | Architecturally fixed `prdata_o` bits | **Reserved/constant - candidate for exclusion** | RXDATA returns `{24'h0, rxdata_reg}`; INT returns `{28'h0, pending[1:0], int_reg[1:0]}`; STATUS [31:7] is tied low. Do not blanket-exclude high read-data bits: CTRL, BAUD, and FIFO return full registers. |
| Condition | `psel_i=0`, `penable_i=1` at lines 177/194 | **Protocol-unreachable / candidate for exclusion** | The APB driver generates IDLE=`0,0`, SETUP=`1,0`, and ACCESS=`1,1`; URG marks only `0,1` unhit. It is unreachable under the compliant-master scope. |
| Condition | TXDATA predicate: active read of TXDATA | **Real verification hole / follow-up test** | URG leaves this legal-but-unsupported vector unhit. TXDATA is absent from the read decoder and reaches default `PSLVERR`; do not waive automatically. |
| Condition | RXDATA predicate: active write of RXDATA | **Real verification hole / follow-up test** | URG leaves this misuse vector unhit. RXDATA is absent from the write decoder and reaches default `PSLVERR`; do not waive automatically. |
| Condition | `ctrl_enable=0, ctrl_tx_enable=1, !tx_fifo_empty, !uart_tx_busy` | **Real verification hole / follow-up test** | URG marks this exact `uart_tx_start` vector unhit. The RTL requires `ctrl_enable`; a directed test should show `uart_tx_start` remains low with global UART enable off. |

## Coverage Closure Conclusion

Earlier report values above are retained as historical context; the authoritative current hardening results and reviewed residual holes are recorded in the v1.0 section below.

## v1.0 Hardening Final Results

Results documented from the verified local Synopsys VCS/URG regression on September 24, 2026.

| Scope | Metric | Result |
|---|---|---:|
| Verification model | Functional coverage | **100.00%** |
| `uart_controller` | Line / condition / branch / toggle | **100.00% / 87.50% / 100.00% / 69.48%** |
| DUT subtree | Line / condition / toggle / FSM / branch | **99.21% / 83.67% / 80.72% / 77.78% / 88.37%** |
| Assertions | Assertion coverage | **89.19%** |

The global URG score is not reported as the primary result because it includes UVM/Verdi instrumentation. Residual holes were reviewed as design-inapplicable, protocol/topology artifacts, parameter/alignment-driven, or low verification-value combinations: zero-wait APB has no wait-state hit, `PADDR[1:0]` is static for word-aligned registers, `PPROT` is unused, and assertion failure action branches should not execute in a passing regression.
