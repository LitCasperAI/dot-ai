# Python Error Handling

How errors are represented, propagated, logged, and returned to
callers.

---

## Error representation

- **Define a project-level exception hierarchy**, rooted in one
  base exception per package/service, not bare `Exception`:

  ```python
  class AppError(Exception):
      """Base class for all application errors."""

  class NotFoundError(AppError):
      def __init__(self, resource: str, id: str) -> None:
          super().__init__(f"{resource} {id!r} not found")
          self.resource = resource
          self.id = id

  class ValidationError(AppError):
      pass
  ```

- **Each exception type is a failure mode the caller can catch
  and act on**, not a generic wrapper. If every caller just logs
  and re-raises, you don't need a new type.
- **Never raise a bare `Exception` or `RuntimeError` for a domain
  failure.** Reserve `RuntimeError` for genuine "this should be
  impossible" states; use a specific domain exception otherwise.

## Propagation

- **Let exceptions propagate rather than catching and
  re-raising the same type.** A `try/except` that just logs and
  re-raises unchanged is noise.
- **Chain with `raise NewError(...) from e`** when translating one
  exception type to another, so the original traceback is
  preserved in `__cause__`.
- **Never silently swallow an exception.** `except Exception:
  pass` is a code smell. If a failure is genuinely ignorable,
  catch the specific type and add a comment explaining why.
- **Add context when an error crosses a boundary** (entering a
  service, leaving a repository) — wrap or annotate with what was
  being attempted. A raw `KeyError` from three layers down is not
  useful to the caller without that context.

## Bare `except` and broad catches

- **`except:` (bare) is banned.** It catches `KeyboardInterrupt`
  and `SystemExit` along with real bugs.
- **`except Exception:` is a last resort**, used only at a
  process boundary (a worker loop, a request handler's outermost
  layer) where the alternative is crashing the whole process for
  one bad input. Log the full exception there; do not let it
  disappear silently.

## Early return (guard clauses)

- **Check failure conditions first and return/raise early**; the
  happy path reads linearly at the end of the function.

  ```python
  def list_books(self) -> list[Book]:
      if not self.connected:
          raise NotConnectedError()
      if not self.authenticated:
          raise NotAuthenticatedError()
      return self.db.query_books()
  ```

## HTTP error mapping (services)

- **A single error-handling layer** (middleware / exception
  handler) converts domain exceptions to HTTP responses. Route
  handlers do not catch and map errors individually.
- **Domain error → status code mapping is exhaustive and
  centralized:** `NotFoundError` → 404, `ValidationError` → 400
  or 422, `ConflictError` → 409, `UnauthorizedError` → 401,
  `ForbiddenError` → 403, anything unmapped → 500.
- **5xx responses never leak internals** (stack traces, SQL,
  file paths) to the client. Log the full exception server-side;
  return a generic message to the caller.

## Logging errors

- **Log once, at the point the error is handled**, not at every
  layer it passes through on its way up. Duplicate logging at
  every `except` in the call chain is noise, not signal.
- **Use structured logging** (`logger.error("...", extra={...})`,
  or the project's structured logger) with the exception object
  passed via `exc_info=True` so the traceback is captured — don't
  interpolate the exception into the message string.

  ```python
  logger.error("failed to create user", exc_info=True, extra={"user_id": user_id})
  ```

## Validation errors

- **Validate at the boundary, once.** Pydantic (or the project's
  validation library) raises a structured validation error at
  the point data enters the system; downstream code trusts the
  validated type and doesn't re-check.
- **Aggregate validation errors** where the input has multiple
  fields, so the caller gets every problem in one response
  instead of fixing one field at a time.
