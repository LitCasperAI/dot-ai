# Node.js Error Handling

How errors are represented, propagated, logged, and returned to
callers. One consistent model across the service — callers and
operators both benefit.

---

## Error classes

- **Domain errors are typed classes** extending a service-
  level `AppError` base. Examples: `NotFoundError`,
  `ValidationError`, `ConflictError`, `UnauthorizedError`,
  `ForbiddenError`, `RateLimitError`, `ExternalServiceError`.
- **`throw new Error("not found")` is rejected.** The string
  is opaque to every layer above; throw the typed class.
- **Each domain error declares a stable `code` string** used
  in the wire format (`USER_NOT_FOUND`, not a UUID or a number
  that changes).
- **Errors carry structured context** (`{ userId, tenantId }`)
  as fields, not as interpolated message strings. Context is
  preserved for logging and not leaked to the client by
  default.

## HTTP mapping

- **A single error-handler plugin maps `AppError` subclasses
  to HTTP responses.** Route handlers do not write status
  codes for error cases — they throw.
- **Unknown errors map to 500** with a generic message and a
  logged stack trace. A thrown `Error` without a mapping is a
  bug, but the response is safe by default.
- **The wire shape is consistent:**

  ```json
  {
    "error": {
      "code": "USER_NOT_FOUND",
      "message": "User not found",
      "details": [
        { "path": "userId", "message": "Unknown user" }
      ]
    }
  }
  ```

  `details` is present for validation errors; absent otherwise.

## Validation errors

- **Zod parse failures become `ValidationError`** through a
  converter, mapped to HTTP 400 (or 422 if the project's API
  design says so — pick one, see `04-api-design.md`).
- **`details` lists each failing field** with a `path` and a
  human-readable `message`. The client can show per-field
  errors without string-matching.

## External failures

- **Outbound HTTP clients wrap upstream failures in
  `ExternalServiceError`** with the upstream name and status.
  Do not propagate raw `undici` errors to the caller — they
  leak implementation detail and do not map cleanly to a
  5xx.
- **Retries are explicit and bounded.** Transient failures
  (5xx, network timeout) retry with exponential backoff and a
  jitter; 4xx responses never retry.
- **A circuit breaker is in place for high-volume outbound
  calls.** Tripping the breaker returns a typed error fast
  instead of dog-piling a dying upstream.

## Logging errors

- **Errors are logged once, at the boundary where they are
  handled.** A service function that throws and a route
  handler that logs and re-throws duplicate the log line.
- **Log at the right level.** Expected domain errors (404,
  409) are `info` or `warn`; unexpected errors (500,
  unmapped throws) are `error`.
- **The full stack trace goes to the log, never to the
  client.** Production 500 responses are opaque by
  configuration.
- **Correlation ID is on every error log.** Without it, you
  cannot follow a request across services.

## Process-level handlers

- **`process.on('unhandledRejection')` and
  `process.on('uncaughtException')` log and exit.** The
  orchestrator restarts; we do not try to keep a process
  alive after an unknown error state.
- **No blanket `try/catch` around `await` that just
  `console.error`s and carries on.** That is how silent data
  loss happens.

## Async patterns

- **`try/catch` with `async/await`.** No
  `.then().catch()` chains for new code.
- **Errors from `Promise.all` are surfaced at the first
  rejection.** If you want partial success, use
  `Promise.allSettled` and handle each result explicitly.
- **Never throw inside a setTimeout / setInterval callback
  without handling.** The throw is unhandled rejection
  territory; orchestrate through a typed scheduler if the
  work is load-bearing.

## User-facing vs internal messages

- **Messages returned to the client are safe to show.** They
  do not leak stack, table names, column names, query
  fragments, or internal identifiers.
- **Rich detail goes to the log with the correlation ID.**
  Support can correlate the user-facing code with the full
  context without the client seeing it.

## Testing

- **Every mapped error has a test.** The mapping from
  `NotFoundError` to HTTP 404 is behaviour; regressing it is
  a bug.
- **Every retry path has a test.** Mock a transient failure
  and assert the retry count and final outcome — otherwise
  retries are a thing you believe is happening.
