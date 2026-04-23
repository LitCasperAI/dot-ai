# Rust Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **Built-in `#[test]` for unit tests.** No external test
  framework unless there is a compelling reason.
- **`cargo nextest` as the test runner** where available.
  Faster parallelism and better output than `cargo test`.
  Fall back to `cargo test` if nextest is not installed.
- **Assertions:** standard `assert!`, `assert_eq!`,
  `assert_ne!` for unit tests. `proptest` or `quickcheck`
  for property-based tests on critical logic.
- **Mocking:** `mockall` when trait-based mocking is needed.
  Prefer designing for testability (accept trait objects or
  generics) over mocking frameworks.

## What to test at which level

- **Pure functions and data transformations** have unit tests
  in the same file (`#[cfg(test)] mod tests`). These are the
  fastest and most valuable — write them generously.
- **Module-internal logic** is tested via unit tests that can
  access private items (Rust's test modules are in-crate).
- **Public API surface** is tested via integration tests in
  `tests/`. These import the crate like an external consumer
  and verify the contract.
- **Async and I/O code** gets integration tests using
  `tokio::test` (or the project's async test macro). Mock
  external services with `wiremock` or similar; never hit
  real third-party APIs in CI.
- **CLI binaries** are tested with `assert_cmd` + `predicates`
  for end-to-end execution.

## Test naming

- **Hierarchical names in unit test modules.** Tests that
  belong together share a prefix so they can be filtered:
  `parse_valid_input`, `parse_empty_input`,
  `parse_malformed_utf8`. Run a group with
  `cargo nextest run parse_`.
- **Integration tests are named for the scenario**, not the
  implementation: `creates_user_and_returns_201`, not
  `test_post_handler`.

## Test file layout

- **Unit tests colocate** with the code under test:

  ```rust
  // src/parser.rs
  pub fn parse(input: &str) -> Result<Ast, ParseError> { ... }

  #[cfg(test)]
  mod tests {
      use super::*;

      #[test]
      fn parse_valid_expression() { ... }
  }
  ```

- **Integration tests** live in `tests/` at the crate root.
  Each file is a separate test binary. Use `tests/common/mod.rs`
  for shared helpers.
- **Test fixtures** (sample files, golden outputs) live in
  `tests/fixtures/` or `testdata/`.

## `unwrap` in tests

- **`unwrap()` is allowed in test code** where a panic is the
  correct failure mode — it keeps tests short and focused on
  `assert!` statements.
- **Prefer `?` with `-> Result<(), Box<dyn Error>>` return
  type** for integration tests that have complex setup, so
  failures produce useful messages instead of bare panics.

## Test utilities and fixtures

- **Shared test helpers** go in a `#[cfg(test)]` module or a
  `test_utils` feature-gated module. Name generator functions
  `generate_test_<type>()`.
- **Builder patterns for test data.** If a test needs a
  complex struct, provide a builder with sensible defaults
  so tests only specify the fields they care about.

## Property-based tests

- **Use `proptest` (or `quickcheck`) for functions with a
  wide input domain.** Parsing, serialization, mathematical
  operations, and codec round-trips are ideal candidates.
- **Regression cases from property tests are pinned.** When
  a shrunk failure is found, add it as a deterministic
  `#[test]` so it never regresses.

## Benchmarks

- **`criterion` for micro-benchmarks.** Benchmarks live in
  `benches/` and are not run in PR CI.
- **A claim about performance comes with a benchmark run.**
  "It seems fast" is not evidence.

## Coverage

- **Coverage is a floor, not a target.** The global minimum
  is declared in `global/06-testing.md`. Use `cargo tarpaulin`
  or `cargo llvm-cov` for collection.
- **`unsafe` code paths have 100% test coverage** for every
  safe-API entry point.

## Doc tests

- **Every public function and type has a doc example** that
  compiles and runs as a test (`cargo test --doc`). Examples
  use `?` and `# fn main() -> Result<...>` wrappers, not
  `unwrap()`.
