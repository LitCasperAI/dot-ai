# Java / Quarkus Error Handling

How errors are represented, propagated, logged, and returned to callers.

---

## Strategy

- **Domain exceptions extend a base `ServiceException`** or map directly to JAX-RS `WebApplicationException` (e.g., `BadRequestException`, `NotFoundException`) that carries an error code and user-facing message.
- **Global `ExceptionMapper<Exception>` classes** act as a safety net. If an exception is a standard JAX-RS `WebApplicationException`, the mapper should let the framework handle its inherent HTTP response. REST resources never catch domain exceptions themselves.
- **Unexpected exceptions** (`NullPointerException`, etc.) are caught by the catch-all `ExceptionMapper`, logged at ERROR with full stack trace, and returned as a generic 500 error string or JSON without internal details.

## Anti-patterns

- **No empty catch blocks.** At minimum, log the exception and explain why it is safe to continue.
- **No `throws Exception` on method signatures.** Declare the specific checked exception 
  or wrap it in an unchecked domain exception.
- **No `@SneakyThrows`.** Checked exceptions exist for a reason; handle or wrap them explicitly.
- **No business logic in exception handlers.** The mapper maps exceptions to responses; 
  it does not retry, compensate, or send notifications.

## Validation errors

- **ConstraintViolationException mapper.** Bean Validation failures are caught by an 
  `ExceptionMapper<ConstraintViolationException>` and returned as 400 Problem Detail 
  with an array listing each field, the constraint, and the rejected value.