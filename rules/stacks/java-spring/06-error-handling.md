# Java / Spring Boot Error Handling

## Strategy

- **Domain exceptions extend a base `ServiceException`** that
  carries an error code, HTTP status, and user-facing message.
  `throw new NotFoundException(…)`, not `throw new
  RuntimeException("not found")`.
- **A global `@RestControllerAdvice`** maps `ServiceException`
  subclasses to RFC 7807 Problem Detail responses. Controllers
  never catch domain exceptions themselves.
- **Unexpected exceptions** (`NullPointerException`, etc.) are
  caught by the same advice, logged at ERROR with full stack
  trace, and returned as a generic 500 Problem Detail without
  internal details.

## Anti-patterns

- **No empty catch blocks.** At minimum, log the exception and
  explain why it is safe to continue.
- **No `throws Exception` on method signatures.** Declare the
  specific checked exception or wrap it in an unchecked domain
  exception.
- **No `@SneakyThrows`.** Checked exceptions exist for a
  reason; handle or wrap them explicitly.
- **No business logic in exception handlers.** The advice maps
  exceptions to responses; it does not retry, compensate, or
  send notifications.

## Validation errors

- Bean Validation failures are caught by the advice and returned
  as 400 Problem Detail with a `violations` array listing each
  field, the constraint, and the rejected value.

