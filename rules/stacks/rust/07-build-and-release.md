# Rust Build and Release

How the project is built, linted, and shipped. Stack-specific
expansion of `global/05-version-control.md` and
`global/07-dependencies.md`.

---

## Toolchain

- **`rust-toolchain.toml` pins the toolchain.** Every
  developer and CI agent runs the same Rust version. The file
  declares `channel` (stable, with MSRV), `components`
  (rustfmt, clippy), and optionally `targets`.
- **`Cargo.toml` declares `rust-version` (MSRV).** Cargo
  enforces this on `cargo build`. Bumping MSRV is a minor
  version bump for libraries.

## Formatting

- **`rustfmt` on every save and in CI.** `cargo fmt --check`
  fails the build if formatting drifts. A `rustfmt.toml` at
  the repo root captures any project-level overrides
  (max width, import grouping).
- **Do not debate formatting.** The formatter is the authority.
  If a rule is wrong, change `rustfmt.toml` in a dedicated PR.

## Linting

- **Clippy is mandatory.** `cargo clippy -- -D warnings` in
  CI. Clippy catches correctness bugs, performance footguns,
  and unidiomatic code that the compiler alone misses.
- **Project-level lint configuration** goes in `Cargo.toml`
  or `clippy.toml`:

  ```toml
  # Cargo.toml
  [lints.clippy]
  pedantic = { level = "warn", priority = -1 }
  unwrap_used = "deny"
  expect_used = "deny"
  panic = "deny"
  ```

- **Lint allows are scoped.** `#[allow(clippy::too_many_arguments)]`
  on a single function, never crate-wide. Crate-wide allows
  disable the lint for everyone forever.

## Dependency auditing

- **`cargo deny`** checks licenses, advisories (RustSec), and
  duplicate versions. Configuration in `deny.toml`.
- **`cargo audit`** (or `cargo deny check advisories`) runs in
  CI on every PR and nightly. Security advisories are
  addressed immediately.
- **Dependabot / Renovate** creates weekly PRs for dependency
  updates. CI validates them automatically.

## Build profiles

- **`dev` profile** for local development: debug info, no
  optimisation. Default.
- **`release` profile** for production: `opt-level = 3`,
  `lto = "thin"` (or `"fat"` for final binaries),
  `strip = true` for smaller binaries.
- **`test` profile** inherits `dev` but may enable
  `opt-level = 1` if tests are slow due to unoptimised
  crypto / compression.

## Continuous integration

- **CI runs on every push and PR.** Minimum pipeline:
  `cargo fmt --check` → `cargo clippy` → `cargo build` →
  `cargo test` → `cargo deny check`.
- **Cache `~/.cargo/registry` and `target/`.** Rust builds
  are slow; CI caching is not optional.
- **Cross-compilation targets** (if applicable) are tested in
  CI with `cross` or `cargo build --target`.

## Packaging (libraries)

- **`cargo publish` to crates.io** (or a private registry).
  Only from tagged commits.
- **`Cargo.toml` metadata is complete:** `description`,
  `license`, `repository`, `homepage`, `documentation`,
  `keywords`, `categories`, `readme`.
- **`#![doc = include_str!("../README.md")]`** to use the
  repo README as crate-level docs on docs.rs.
- **Changelog** follows Keep a Changelog format. Updated in
  the same PR as the version bump.

## Packaging (services / binaries)

- **Multi-stage Docker builds.** Build in `rust:latest` (or
  the pinned toolchain image), copy the binary to a minimal
  runtime image (`debian:slim`, `distroless`, or `scratch`
  for fully static builds).
- **Static linking with musl** for scratch/distroless images:
  `cargo build --release --target x86_64-unknown-linux-musl`.
- **Health check endpoints** (`/healthz`, `/readyz`) are wired
  and verified by the container orchestrator.
- **Graceful shutdown** on `SIGTERM`: stop accepting new work,
  drain in-flight requests, close connections.

## Versioning

- **Semver strictly.** See `04-api-design.md` for what
  constitutes a breaking change.
- **Version is declared in `Cargo.toml`.** Use a release
  script or `cargo-release` to bump, tag, and publish in one
  step.
- **Pre-release versions** (`1.0.0-alpha.1`) for unstable
  APIs. crates.io does not serve pre-release to `^` ranges.

## Workspace conventions

- **Shared dependencies in `[workspace.dependencies]`.**
  Crates reference them with `{ workspace = true }`.
- **`[workspace.lints]`** for shared lint configuration across
  all crates.
- **A root `xtask` crate** for build automation (code gen,
  release prep, CI steps). Invoked via
  `cargo xtask <command>`.
