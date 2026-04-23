# Rust API Design

How public crate APIs and HTTP service APIs are shaped.
Follows the Rust API Guidelines (C-* checklist) and
project-level conventions.

---

## Crate API design

- **Types eagerly implement common traits.** Every public type
  derives or implements the traits that make sense:
  `Debug`, `Clone`, `PartialEq`, `Eq`, `Hash`, `Default`,
  `Display`, `Send`, `Sync`. A type missing `Debug` is a
  debugging tax on every consumer.
- **Use standard conversion traits.** `From` / `Into`,
  `AsRef` / `AsMut`, `TryFrom` / `TryInto`. Do not invent
  ad-hoc `.to_foo()` methods when a `From` impl suffices.
- **Functions minimise assumptions about parameters.** Accept
  `impl AsRef<Path>` instead of `&Path`, `impl Into<String>`
  instead of `String`, `impl Iterator<Item = T>` instead of
  `&[T]` — where it genuinely adds flexibility without
  obscuring the API.
- **Builders for complex construction.** If a constructor
  takes more than 3-4 parameters, provide a builder with
  sensible defaults.
- **Sealed traits for extension protection.** A public trait
  that is not intended for downstream implementation should
  be sealed via a private supertrait.
- **Structs have private fields** unless there is a deliberate
  reason to expose them. Public fields are part of the
  semver contract.
- **Newtypes encapsulate implementation details.** A
  `pub struct Timestamp(i64)` is free to change its
  representation; a bare `pub i64` is not.

## HTTP API design (services)

- **REST for resource-oriented APIs** (default). Axum, Actix,
  or the project's declared framework. Handlers are thin:
  extract, validate, call a service, respond.
- **`kebab-case` in paths, `snake_case` or `camelCase` in
  JSON bodies** — pick one per project and hold to it.
- **Status codes are correct.** 200, 201, 204, 400, 401, 403,
  404, 409, 422, 429, 5xx — see `dotnet/04-api-design.md` or
  `nodejs/04-api-design.md` for the full table. The rules are
  language-agnostic.
- **One error shape across the service.** Return a structured
  JSON error with `code` (machine-readable), `message`
  (human-readable), and optional `details`. See
  `06-error-handling.md`.

## Naming (API Guidelines C-CASE, C-CONV)

- **RFC 430 casing.** `snake_case` functions and methods,
  `CamelCase` types and traits, `SCREAMING_SNAKE_CASE`
  constants.
- **Conversions:** `as_` (cheap ref-to-ref), `to_` (expensive
  or ref-to-owned), `into_` (consumes self).
- **Iterators:** `iter()`, `iter_mut()`, `into_iter()` on
  collections. Iterator type names match the method:
  `fn iter(&self) -> Iter<'_>`.
- **Getters omit `get_` prefix.** `fn name(&self) -> &str`.

## Documentation (API Guidelines C-CRATE-DOC, C-EXAMPLE)

- **Every public item has a doc comment** with at least one
  example that compiles as a doc test.
- **`# Errors` section** on every `Result`-returning function.
- **`# Panics` section** if the function can panic.
- **`# Safety` section** on every `unsafe fn`.
- **Examples use `?`**, not `unwrap()`.
- **Crate-level docs** (`//!` in `lib.rs`) include a
  high-level overview, a quick-start example, and feature
  flag documentation.

## Versioning and semver

- **Follow semver strictly.** A removed public item, a changed
  type signature, or a new required field is a major bump.
- **Additive changes** (new public items, new optional fields
  behind `#[non_exhaustive]`) are minor.
- **`#[non_exhaustive]` on public enums and structs** that may
  grow. This lets you add variants/fields without a major bump.
- **Public dependencies are part of your semver contract.** A
  major bump of a re-exported dependency is a major bump for
  your crate.

## Predictability (API Guidelines C-METHOD, C-NO-OUT)

- **Functions with a clear receiver are methods.** `file.read()`
  not `read(file)`.
- **No out-parameters.** Return values instead of mutating a
  passed-in `&mut` buffer, unless performance demands it and
  it is documented.
- **Operator overloads are unsurprising.** `Add` on a matrix
  does element-wise addition, not something creative.
