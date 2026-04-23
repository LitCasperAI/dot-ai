# Rust Error Handling

How errors are represented, propagated, logged, and returned
to callers. Rust's `Result` type makes errors explicit — these
rules make them useful.

---

## Error representation

- **Library crates use `thiserror`.** Define a crate-level
  error enum with `#[derive(thiserror::Error)]`. Each variant
  is a meaningful failure mode the caller can match on.

  ```rust
  #[derive(Debug, thiserror::Error)]
  pub enum ParseError {
      #[error("unexpected token '{token}' at position {pos}")]
      UnexpectedToken { token: String, pos: usize },
      #[error("unexpected end of input")]
      UnexpectedEof,
      #[error(transparent)]
      Io(#[from] std::io::Error),
  }
  ```

- **Application crates use `anyhow` or `eyre`.** The caller
  doesn't need to match on variants; they need context and a
  backtrace.

  ```rust
  use anyhow::{Context, Result};

  fn load_config(path: &Path) -> Result<Config> {
      let text = std::fs::read_to_string(path)
          .with_context(|| format!("failed to read {}", path.display()))?;
      toml::from_str(&text).context("invalid config TOML")
  }
  ```

- **Do not mix `thiserror` and `anyhow` in the same crate.**
  Libraries expose structured errors; applications wrap them
  in `anyhow::Error` at the boundary.

## Propagation

- **Use `?` everywhere.** The `?` operator is the primary
  error propagation mechanism. A `match` that just re-wraps
  an error is noise — implement `From` and let `?` convert.
- **Add context at boundaries.** When an error crosses a
  logical boundary (entering a service, leaving a repository),
  wrap it with `.context("what we were trying to do")`.
  Raw low-level errors ("connection refused") are not useful
  to callers without context.
- **Do not discard errors.** `let _ = fallible_op();` is a
  code smell. If you genuinely don't care about the error,
  add a comment explaining why.

## Panics

- **`panic!` is for programming errors**, not operational
  failures. An out-of-bounds index or a violated invariant is
  a panic. A network timeout is not.
- **`unwrap()` / `expect()` are banned in production code.**
  See `01-constraints.md`. Use them freely in tests.
- **`expect()` with a descriptive message** is acceptable in
  `main()` or one-off scripts where the program should crash
  on an impossible condition.

## Early return (guard clauses)

- **Use early return to reduce nesting.** Check error
  conditions first and return early; the "happy path" reads
  linearly at the end of the function.

  ```rust
  fn list_books(&self) -> Result<Vec<Book>> {
      if !self.connected {
          return Err(Error::NotConnected);
      }
      if !self.authenticated {
          return Err(Error::NotAuthenticated);
      }
      // happy path
      Ok(self.db.query_books()?)
  }
  ```

- **Prefer combinators for `Option`/`Result` chains.** Use
  `.ok_or()`, `.map_err()`, `.and_then()` instead of nested
  `match` when the logic is straightforward.

## HTTP error mapping (services)

- **A single error-handling layer** converts domain errors to
  HTTP responses. Handlers do not catch and map errors
  themselves.
- **Domain error → status code mapping is exhaustive.**
  `NotFound` → 404, `Validation` → 400/422,
  `Conflict` → 409, `Unauthorized` → 401,
  `Forbidden` → 403, anything else → 500.
- **5xx responses never leak internals.** Log the full error;
  return a generic message to the caller.

## Logging errors

- **Log at the point of handling, not the point of
  propagation.** An error that is `?`-propagated is not logged
  at every level it passes through — that produces duplicate
  noise. Log once, where the error is handled or returned to
  the caller.
- **Structured logging with `tracing`.** Use `tracing::error!`
  with fields, not string interpolation.

  ```rust
  tracing::error!(%err, user_id = %id, "failed to create user");
  ```

## Result combinators cheat-sheet

| Need | Use |
|---|---|
| Transform the Ok value | `.map(...)` |
| Transform the Err value | `.map_err(...)` |
| Chain fallible operations | `.and_then(...)` |
| Provide a fallback | `.unwrap_or_else(...)` (lazy) |
| Convert Result → Option | `.ok()` |
| Convert Option → Result | `.ok_or(...)` / `.ok_or_else(...)` |
| Add context (anyhow) | `.context("...")` / `.with_context(...)` |
