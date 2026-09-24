# Changelog

## v1.0 Verification Hardening - 2026-09-24

### Added

- Unsupported APB access, runtime reset, TX/RX reset recovery, full-duplex, and global-enable TX-gating verification.
- APB4 protocol SVA/cover properties and automated hardening regression targets.

### Verification Results

- 7/7 PASS; UVM_WARNING, UVM_ERROR, and UVM_FATAL are all zero.
- Results documented from the verified local Synopsys VCS/URG regression.

### Coverage Closure

- Functional coverage: 100.00%.
- Residual holes were reviewed rather than forced.
