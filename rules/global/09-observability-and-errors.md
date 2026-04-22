# Observability and errors

Stack-agnostic posture for logging, metrics, and error handling.
Stacks pick the libraries and log formats; this file defines what
good looks like regardless of stack.

## Errors are not decoration

- Do not catch an exception only to log it and continue. If the
  caller cannot handle the failure, let it propagate.
- Do not catch broad exception types (`Exception`, `Error`,
  `catch (e)`) to paper over a specific bug. Catch what you can
  handle; re-raise the rest.
- An empty `catch` block is a bug. If ignoring an error is
  intentional, say so in one short comment explaining why.

## Error messages

- Error messages name what failed and, when possible, how to
  recover. "Invalid input" is not an error message.
- Do not include secrets, tokens, or full request bodies in error
  messages. Redact before raising.
- Wrap lower-level errors with context as they bubble up, rather
  than either swallowing them or losing the original cause.

## Logging

- Logs are structured (key-value or JSON), not ad-hoc strings.
  Stack rules declare the exact format.
- Log levels carry meaning:
  - `error` — something broke that needs attention.
  - `warn`  — something unexpected, but handled.
  - `info`  — one-line record of a significant event.
  - `debug` — developer detail, off in production.
- Do not log in hot loops. Do not log the same event from every
  layer of the stack; pick one.

## Metrics and tracing

- New behaviour that matters in production emits at least one
  signal — a metric, a trace span, or a structured log — that
  lets someone answer "is this working?" without reading code.
- Names are consistent across services. Stack rules declare the
  naming scheme.

## User-facing vs internal errors

- The message a user sees is not the message you log. Users get
  something actionable and non-leaky; logs get the full detail.
- Never surface stack traces, SQL, or internal paths to an end
  user.
