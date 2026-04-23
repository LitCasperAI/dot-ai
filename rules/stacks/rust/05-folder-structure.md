# Rust Folder Structure

How Rust projects are organised. Two reference layouts:
single-crate applications/services and multi-crate workspaces
(libraries or large systems).

---

## Single-crate application (service / CLI)

```text
my-service/
├── Cargo.toml
├── Cargo.lock              # Committed for applications (not libraries)
├── src/
│   ├── main.rs             # Entry point: config, tracing, server startup
│   ├── lib.rs              # (optional) re-export for integration tests
│   ├── config.rs           # Environment / file config parsing
│   ├── routes/             # HTTP handlers (thin — extract, validate, call service)
│   │   ├── mod.rs
│   │   └── users.rs
│   ├── services/           # Business logic (pure where possible)
│   │   ├── mod.rs
│   │   └── user_service.rs
│   ├── models/             # Domain types, DTOs
│   │   ├── mod.rs
│   │   └── user.rs
│   ├── db/                 # Database access (queries, migrations)
│   │   ├── mod.rs
│   │   └── user_repo.rs
│   ├── errors.rs           # Error types, HTTP error mapping
│   └── telemetry.rs        # Tracing / metrics setup
├── tests/                  # Integration tests
│   ├── common/
│   │   └── mod.rs          # Shared test helpers
│   └── api_tests.rs
├── benches/                # Criterion benchmarks
├── migrations/             # SQL migrations (sqlx, diesel)
└── testdata/               # Test fixtures
```

## Multi-crate workspace (library / large system)

```text
my-workspace/
├── Cargo.toml              # [workspace] definition
├── Cargo.lock
├── crates/
│   ├── my-lib/             # Core library crate
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       └── ...
│   ├── my-lib-macros/      # Proc-macro crate (if needed)
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── my-cli/             # Binary crate
│   │   ├── Cargo.toml
│   │   └── src/main.rs
│   └── my-server/          # Server binary crate
│       ├── Cargo.toml
│       └── src/main.rs
├── tests/                  # Workspace-level integration tests
├── benches/                # Workspace-level benchmarks
└── xtask/                  # Build automation (xtask pattern)
    ├── Cargo.toml
    └── src/main.rs
```

## Key conventions

- **`Cargo.lock` is committed for applications**, not for
  libraries. Libraries let downstream pick exact versions.
- **Workspace dependencies** are declared in the root
  `Cargo.toml` under `[workspace.dependencies]` and
  referenced by members with `{ workspace = true }`. No
  version duplication across crates.
- **Feature flags** are declared in `Cargo.toml` with
  descriptive names. Default features are minimal; additive
  features enable optional capabilities.

## Module organisation

- **One concept per module.** `user.rs` contains the `User`
  type, its impls, and closely related types. If a module
  exceeds ~300 lines, consider splitting.
- **`mod.rs` is acceptable but file-per-module is preferred**
  on Rust 2018+: `routes/users.rs` rather than
  `routes/users/mod.rs`, unless the module has submodules.
- **`pub use` re-exports in parent modules** to flatten the
  public API. Consumers write `use my_lib::User`, not
  `use my_lib::models::user::User`.
- **`prelude` module** (optional) re-exports the most commonly
  used items for ergonomic `use my_lib::prelude::*` in
  downstream code and examples.

## Layering (services)

- **Handlers are thin.** Extract request data, call a service,
  return a response. No business logic in handlers.
- **Services own business logic.** They accept trait objects or
  generics for I/O, making them testable without a running
  server.
- **Repositories wrap database access.** A repository method is
  a named domain operation, not a thin pass-through to the ORM.
- **Outbound HTTP** goes through typed clients with timeouts
  and retry policies (via `reqwest` + `tower` middleware or
  equivalent).

## Tests

- Unit tests colocate with code (`#[cfg(test)] mod tests`),
  per `02-testing.md`.
- Integration tests in `tests/` import the crate as an
  external consumer.
- Shared test helpers in `tests/common/mod.rs`.
- Test fixtures in `testdata/` or `tests/fixtures/`.

## Build automation

- **`xtask` pattern** for non-trivial build scripts (code
  generation, release prep, CI steps). An `xtask` crate in
  the workspace provides `cargo xtask <command>` — no
  external build tools required.
- **`build.rs`** only for compile-time code generation
  (protobuf, FFI bindings). Keep build scripts fast; slow
  build scripts hurt every developer.
