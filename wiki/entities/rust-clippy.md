---
tags: [rust, linter, linting-tool]
date: 2026-07-02
type: documentation
category: entity
sources: ["raw/corrected/SRC-test-entity-001/rust-clippy.md"]
related: []
---

# Clippy

## Definition

Clippy is a collection of lints (static analysis checks) to catch common mistakes and improve Rust code. It runs on top of rustc as a custom lint tool, providing suggestions beyond the compiler's built-in diagnostics.

## Key Characteristics

- **600+ lints** organized by category: `all`, `complexity`, `correctness`, `perf`, `style`, `pedantic`, `cargo`, `nursery` (experimental), `restriction`
- **Auto-fix support**: Many lints suggest corrections via `cargo clippy --fix`
- **Triage levels**: Lints sorted by priority — `info`, `warn`, `deny`
- **Configuration flexibility**: Individual lints can be enabled/disabled per-project in `Cargo.toml` under `[lints.clippy]`
- **Toolchain integration**: Ships bundled with Rust toolchain — same versioning as rustc, no separate installation needed

## Architecture / Implementation Details

Clippy integrates as `clippy-driver`, which compiles your code like rustc but adds custom lint passes. Checks run at compile time, not runtime, meaning:
- No performance penalty during development (already caught by compiler)
- Zero overhead in production builds
- Seamless workflow — runs alongside normal compilation

### Lint Categories and Their Purpose

| Category | Focus Area | Default Status |
|----------|-----------|----------------|
| `clippy::pedantic` | Style issues, considered too strict | Disabled |
| `clippy::cargo` | Cargo best practices and common mistakes | Enabled |
| `clippy::complexity` | Simplifying complex code patterns | Enabled |
| `clippy::correctness` | Potential bugs or unsafe patterns | Enabled |
| `clippy::performance` | Faster alternatives for common operations | Enabled |
| `clippy::style` | Idiomatic Rust conventions | Enabled |

### Configuration Example

Lints are configured in project's `Cargo.toml`:

```toml
[lints.clippy]
# Enable a lint
borrow_as_ptr = "allow"
# Disable a lint
needless_return = "deny"
```

## Usage Examples

Basic usage:
```bash
# Run Clippy on a project with warnings as errors
cargo clippy -- -D warnings
```

Example lints caught by Clippy:

| Lint | Category | Description |
|------|----------|-------------|
| `clippy::needless_question_mark` | Complexity | Suggests removing unnecessary `?` operators |
| `clippy::map_clone` | Performance | Suggests more efficient `.map(|x| *x)` patterns |
| `clippy::wrong_self_convention` | Style | Warns about inconsistent receiver naming (self vs &mut self) |

## Related Pages

*No related pages yet — to be populated after crosslink discovery.*
