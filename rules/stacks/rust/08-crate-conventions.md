# Rust Crate Conventions

Rules specific to authoring reusable crates (libraries). Backend
services follow `05-folder-structure.md`; this file covers
crates that ship to consumers via crates.io or a private
registry.

---

## Public API surface

- **Default to private.** Every item is private or `pub(crate)`
  unless it is part of the documented contract. A type that
  leaks by accident is a breaking change to remove.
- **`#[non_exhaustive]` on public enums and structs** that may
  gain variants or fields. This reserves the right to add
  without a major version bump.
- **Sealed traits** for traits that consumers should use but
  not implement. See `04-api-design.md`.
- **Structs have private fields** with constructor functions
  or builders. Public fields are forever.

## Derive and trait implementations

- **Derive generously.** Every public type should derive at
  minimum `Debug` and `Clone`. Add `PartialEq`, `Eq`, `Hash`,
  `Default`, `Serialize`, `Deserialize` where they make sense.
- **`Display` for user-facing types.** If a type appears in
  error messages or logs, implement `Display`.
- **`From` / `TryFrom` for conversions.** Do not invent ad-hoc
  methods when standard traits exist.
- **Collections implement `FromIterator` and `Extend`** if
  they are collection-like.

## Feature flags

- **Features are additive.** Enabling a feature never removes
  functionality. A feature that changes behaviour (rather than
  adding it) is a design bug.
- **Default features are minimal.** The crate compiles and is
  useful with default features. Optional integrations (serde,
  async runtimes, specific backends) are behind feature flags.
- **Document every feature** in crate-level docs and
  `Cargo.toml` `[features]` comments.
- **Feature names are descriptive.** `serde`, `tokio`,
  `postgres` — not `feat1` or `extra`.

## Dependencies

- **Minimise runtime dependencies.** Every dependency is
  compile-time cost and a semver coupling point for consumers.
  If the functionality can be implemented in < 50 lines, do
  so.
- **Optional dependencies behind feature flags.** A consumer
  who doesn't use the Postgres backend shouldn't compile
  `tokio-postgres`.
- **No version duplication.** In a workspace, use
  `[workspace.dependencies]`. In a single crate, keep
  dependency versions up to date; `cargo update` weekly.
- **Public dependencies are part of semver.** Re-exporting a
  type from a dependency makes that dependency's version your
  contract. A major bump there is a major bump for you.

## Documentation

- **Crate-level docs** (`//!` in `lib.rs`) include:
  1. What the crate does (one paragraph)
  2. Quick-start example
  3. Feature flag table
  4. MSRV policy
- **Every public item has a doc comment** with at least one
  example that compiles as a doc test.
- **`# Errors`, `# Panics`, `# Safety`** sections per the
  API Guidelines. See `04-api-design.md`.
- **`#[doc(hidden)]`** for public items that exist for
  macro internals or cross-crate plumbing. They don't appear
  in docs and are not part of the semver contract.

## Testing (crate-specific)

- **Doc tests are first-class tests.** Every example compiles
  and runs. Use `# fn main() -> Result<(), Box<dyn Error>> {`
  wrappers and `?` instead of `unwrap()`.
- **API snapshot tests** (optional but recommended) verify
  that the public API surface doesn't change accidentally.
  Use `cargo public-api` or `expect-test`.
- **Test against MSRV in CI.** If the crate declares
  `rust-version = "1.70"`, CI runs `cargo +1.70 check`.

## Releasing

- **Follow semver strictly.** See `04-api-design.md`.
- **Use `cargo-release`** (or a similar tool) to automate
  version bump → changelog update → git tag → `cargo publish`.
  Manual version bumps are error-prone.
- **Changelog** follows [Keep a Changelog](https://keepachangelog.com/)
  format. Updated in the same commit as the version bump.
- **Publish only from tagged commits.** CI checks
  `refs/tags/v*` before running `cargo publish`.
- **`--dry-run` first.** `cargo publish --dry-run` catches
  packaging issues (missing files, metadata) before the real
  publish.

## Backward compatibility

- **`#[deprecated]` before removal.** Mark items as deprecated
  in a minor release; remove them in the next major release.
  The deprecation message tells the consumer what to use
  instead.
- **Re-export renamed items** during the transition:
  ```rust
  #[deprecated(since = "2.0.0", note = "renamed to `Widget`")]
  pub type Gadget = Widget;
  ```
- **MSRV bumps are documented** in the changelog and are
  minor version changes (not patch).
