# Rust Constraints

Hard rules for Rust code in this project. If a constraint here
conflicts with what you're about to write, stop and escalate —
don't route around it.

---

## Language and toolchain

- **Latest stable Rust.** The project declares `rust-version`
  (MSRV) in `Cargo.toml`. Do not use nightly features in
  production code without an ADR.
- **Edition 2021 (or newest stable).** Set in `Cargo.toml`;
  do not override per-crate.
- **All warnings are denied in CI.** `#![deny(warnings)]` or
  `RUSTFLAGS="-D warnings"` in CI. Do not suppress a warning
  without a comment explaining why.

## Ownership and borrowing

- **Prefer immutable references for function inputs.** Accept
  `&T` or `&[T]` / `&str` (slices) unless the function
  genuinely needs ownership. A function that takes `String`
  when `&str` would suffice forces the caller to clone.
- **Accept slices over owned collections.** `&[T]` instead of
  `&Vec<T>`, `&str` instead of `&String`, `&Path` instead of
  `&PathBuf`. Slices are strictly more general.
- **Use owned types in struct fields.** `String`, `Vec<T>`,
  `PathBuf` — not `&str`, `&[T]`, `&Path`. Structs own their
  data; references in structs introduce lifetimes that
  complicate the API.
- **Derive `Clone` on every type unless there is a reason not
  to.** Derive `Copy` when all fields are `Copy` and the
  struct is small. This eliminates a class of ownership
  friction for callers.
- **Avoid `Rc`/`Arc` as a default.** Shared ownership is a
  design decision, not a workaround for borrow-checker
  errors. If you reach for `Rc`/`Arc`, document why shared
  ownership is the right model.

## Type safety

- **Newtypes for domain concepts.** Wrap primitive types that
  carry domain meaning: `struct UserId(u64)`, not bare `u64`.
  The compiler catches misuse for free.
- **Use enums over booleans for flags.** A function that takes
  `bool, bool` is unreadable at the call site. Use a
  descriptive enum or a builder.
- **Leverage the type system for state machines.** Encode
  valid transitions in types rather than runtime checks; the
  compiler rejects invalid states.
- **`bitflags` for flag sets**, not enums with bitwise ops.

## Error handling

- **No `unwrap()` or `expect()` in production code.** They
  panic. Use `?`, combinators (`map`, `and_then`,
  `unwrap_or_else`), or explicit `match`.
- **`unwrap()` is allowed in tests** where a panic is the
  correct failure mode.
- **`thiserror` for library error types, `anyhow` /
  `eyre` for application error types.** Libraries expose
  structured, matchable errors; applications care about
  context and backtraces.
- **Propagate errors with `?`.** Do not write `match` blocks
  that just re-wrap — let `From` conversions and `?` do the
  work.
- **Every `Result`-returning function documents when and why
  it fails** in a `# Errors` doc section.

## Unsafe

- **`unsafe` blocks require a `// SAFETY:` comment** that
  explains why the invariants are upheld. A bare `unsafe` is
  rejected in review.
- **Minimise the surface area.** Extract the `unsafe`
  operation into the smallest possible function and wrap it in
  a safe API. Callers never write `unsafe`.
- **`unsafe` in new code requires an ADR** unless it is
  FFI-mandated (calling C libraries via `extern`).

## Concurrency

- **`Send` and `Sync` are meaningful.** Types that cross
  thread boundaries must be `Send`; types shared across
  threads must be `Sync`. Do not circumvent these bounds
  with `unsafe impl`.
- **Prefer message passing** (`mpsc`, `tokio::sync::mpsc`,
  `crossbeam`) over shared mutable state. If shared state is
  needed, use `Mutex` or `RwLock` with a documented locking
  strategy.
- **Do not hold locks across `.await` points.** A `MutexGuard`
  alive across an `await` blocks the executor and can
  deadlock. Use `tokio::sync::Mutex` only when genuinely
  needed.

## Async

- **Async is for I/O, not CPU.** Do not make synchronous
  computation async. `spawn_blocking` for CPU work that must
  run inside an async context.
- **Do not mix sync and async I/O** in the same call chain
  without `spawn_blocking` or a clear boundary.
- **One async runtime per project.** Tokio is the default.
  Do not pull in a second runtime.

## Dependencies

- **No new runtime dependencies without explicit approval.**
  Escalate to the architect. Rust's compilation model means
  every dependency is compile-time cost.
- **Dev dependencies can be added** without approval, but
  call them out in the commit message.
- **Check `cargo deny`** (or the project's declared audit
  tool) for license and vulnerability issues before merging
  dependency changes.

## Naming

- **Follow RFC 430.** `snake_case` for functions, methods,
  variables, modules; `CamelCase` for types and traits;
  `SCREAMING_SNAKE_CASE` for constants and statics.
- **Conversion methods:** `as_` (cheap, borrowed → borrowed),
  `to_` (expensive or borrowed → owned), `into_` (owned →
  owned, consumes self).
- **Iterator methods:** `iter()`, `iter_mut()`, `into_iter()`.
- **Getter methods omit `get_` prefix.** `fn name(&self)`
  not `fn get_name(&self)`.

## Imports

- **Group `use` statements:** std → external crates → crate
  modules, separated by blank lines. `rustfmt` handles the
  rest.
- **Avoid glob imports** (`use foo::*`) outside of preludes
  and test modules.

## Things out of scope for this file

Testing (`02-testing.md`), performance (`03-performance.md`),
API design (`04-api-design.md`), folder structure
(`05-folder-structure.md`), error handling
(`06-error-handling.md`), build/release
(`07-build-and-release.md`), and crate conventions
(`08-crate-conventions.md`) each live in their own file.
