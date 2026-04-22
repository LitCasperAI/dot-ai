# .NET Error Handling

How errors are represented, propagated, logged, and returned
to callers. One consistent model across the service — callers
and operators both benefit.

---

## Error representation

- **Domain errors are typed exceptions** that inherit from a
  project-level `DomainException` base, or a Result/OneOf
  pattern. Pick one per project and be consistent.
- **Each error carries a machine-readable `Code`** (string
  constant, e.g. `"USER_NOT_FOUND"`) and a human-readable
  `Message`. Callers switch on `Code`, never on `Message`.
- **Infrastructure errors wrap inner exceptions.** A
  repository that catches a `SqlException` re-throws a
  domain-meaningful type (e.g. `ConflictException`) so the
  caller doesn't couple to the database.

## HTTP error mapping

- **A single exception-handling middleware** (or
  `IExceptionHandler` in .NET 8+) maps domain exceptions to
  RFC 7807 `ProblemDetails`. Endpoints do not catch and map
  exceptions themselves.
- **Mapping is exhaustive.** `NotFoundException` → 404,
  `ValidationException` → 400/422, `ConflictException` → 409,
  `UnauthorizedException` → 401, `ForbiddenException` → 403,
  anything else → 500. A new exception type without a mapping
  is a 500 — add the mapping in the same PR.
- **5xx responses never leak implementation details.** The
  `ProblemDetails.Detail` for a 500 says "An unexpected error
  occurred"; the stack trace is logged, not returned.

## Logging errors

- **Every caught-and-handled error is logged at `Warning` or
  higher.** An exception that's swallowed silently is a
  debugging nightmare.
- **Unhandled exceptions (500s) are logged at `Error` with
  the full exception.** Use structured logging:
  `_logger.LogError(ex, "Failed to process order {OrderId}", orderId)`.
- **Do not log and throw.** Either handle the error (log +
  return a response) or re-throw for the middleware to handle.
  Logging at every layer produces duplicate noise.

## Validation errors

- **Validation runs before the service layer.** A validator
  (FluentValidation, MediatR pipeline behaviour, or endpoint
  filter) rejects bad input and returns 400/422 with
  field-level details.
- **Validation error responses use `ValidationProblemDetails`**
  with an `errors` dictionary keyed by property path.
- **The service layer does not repeat input validation.** It
  may enforce business invariants (e.g. "email must be unique"),
  but it trusts that shape/format validation has already run.

## Result pattern (if used)

- **Result types are `readonly record struct`** or a library
  type (`OneOf`, `ErrorOr`, `FluentResults`). Pick one per
  project.
- **The caller must inspect the result.** A result that is
  ignored triggers a compiler warning or analyzer rule.
- **Do not mix Result and exceptions in the same layer.** If
  the service returns `Result<T>`, it does not also throw. The
  exception path is for truly exceptional failures (out of
  memory, network partition).

## Retry and resilience

- **Retries are handled by Polly** (or the project's declared
  resilience library), configured once per outbound client.
  Do not hand-roll retry loops.
- **Retries use jittered exponential backoff.** Fixed-interval
  retries synchronize thundering herds.
- **Circuit breakers protect downstream.** A client that keeps
  hammering a failing dependency makes the outage worse.
- **Retried operations must be idempotent.** If the operation
  is not safe to repeat, do not retry it.
