# Node.js Constraints

Hard rules for Node.js service code in this project. If a
constraint here conflicts with what you're about to write, stop
and escalate — don't route around it.

These are constraints, not suggestions. Every item in this file
is something that should trigger pushback in code review.

---

## Language and runtime

- **TypeScript only, strict mode on.** No `.js` files in
  `src/`. Every new file is `.ts`. `strict: true` in
  `tsconfig.json` is a hard requirement, not aspirational.
- **Target the current LTS.** The project declares its Node
  version in `.nvmrc` / `package.json` `engines`. CI, local
  dev, and production run the same major. Do not adopt a
  non-LTS version without an ADR.
- **ESM only.** `"type": "module"` in `package.json`. CommonJS
  (`require`, `module.exports`) is not used in new code.
- **No `any` type.** Use `unknown` if the type is genuinely
  unknown and narrow it before use. If you're tempted to reach
  for `any`, that's a signal the types are modelled wrong —
  fix the model, not the escape hatch.

## Service shape

- **One HTTP framework per service.** The project declares its
  framework (Fastify is the default; Express is legacy-only).
  Do not mix frameworks within a service.
- **HTTP is a transport, not a layer of business logic.**
  Route handlers are thin: validate input, call a service
  function, shape the response. Business rules live in
  `src/features/<x>/services/`.
- **No singletons constructed at import time** beyond pure
  constants. Clients (database, HTTP, message broker) are
  instantiated by a composition root and passed in. Module
  top-level `new DbClient()` is rejected in review.

## Input validation

- **Every external input is validated with Zod before use.**
  HTTP bodies, query strings, path params, message payloads,
  webhook bodies, environment variables — all parsed, not
  cast. A validated input is typed; an unvalidated input is
  untrusted.
- **Validation errors return 400 with a structured error
  payload.** See `global/09-observability-and-errors.md`.
- **Runtime schemas and TypeScript types come from the same
  source.** Declare the Zod schema, derive the type with
  `z.infer` — do not hand-write both.

## Database and I/O

- **One ORM/query builder per service.** The project declares
  its data layer (Prisma or Drizzle is the default, depending
  on project). Raw SQL is acceptable for specific performance
  needs with a comment noting why.
- **All I/O is wrapped.** Direct `fetch` / `undici` calls from
  handlers are rejected; outbound HTTP goes through a client in
  `src/core/api/` with timeouts and retries configured.
- **Transactions are explicit.** A multi-statement mutation
  runs inside a transaction; relying on "it usually works" is
  not a strategy.
- **Connections are pooled and bounded.** Pool size is
  declared in config and matches the database's capacity; a
  service that opens unbounded connections is a load incident
  waiting to happen.

## Async and errors

- **Async functions return typed promises.** `Promise<User>`,
  not `Promise<any>` or bare inference.
- **Every async operation that can fail has explicit error
  handling.** No unhandled promise rejections. At minimum, log
  through the project's error service and either re-throw or
  return a typed result — do not silently swallow. See
  `global/09-observability-and-errors.md`.
- **Domain errors are typed classes** (or a discriminated
  union). `throw new Error("not found")` is rejected — use
  `throw new NotFoundError(...)` and let the HTTP layer map
  it.
- **No `.then().catch()` chains for new code.** Use
  `async/await` with `try/catch`.

## Process lifecycle

- **Graceful shutdown is wired.** On `SIGTERM`/`SIGINT` the
  service stops accepting new work, drains in-flight requests
  within a timeout, and closes DB/broker connections before
  exit. A service that crashes on SIGTERM kills in-flight
  requests.
- **No process-level `try/catch` that swallows everything.**
  Unhandled rejections and uncaught exceptions are logged and
  the process exits; the orchestrator restarts it. An
  always-on `process.on('uncaughtException', () => {})` is a
  bug generator.
- **Configuration is loaded at boot and validated.** A missing
  required env var crashes on startup, not on the first
  request.

## Secrets and config

- **Config comes from env vars**, loaded through a single
  `src/core/config/` module that validates with Zod. No
  `process.env.FOO` sprinkled across the codebase.
- **Secrets are never logged.** The logger has a redaction
  list; if a new secret is added, the redaction list is
  updated in the same PR. See `global/08-secrets-and-data.md`.
- **No secrets in the repo.** Not in `.env`, not in fixtures,
  not in committed test config.

## Observability

- **Structured logs (JSON) only.** No `console.log` in new
  code; use the project's logger
  (Pino by default) configured in `src/core/logger.ts`.
- **Every request has a correlation ID** captured in log
  context from a header (`x-request-id`) or generated if
  absent. Downstream calls propagate it.
- **Metrics and traces** are wired through the project's
  declared stack (OpenTelemetry by default). Do not hand-roll
  an alternative.

## Dependencies

- **No new runtime dependencies without explicit approval.** If
  you think a dependency is needed, stop and escalate to the
  architect.
- **Dev dependencies (types, test utilities) can be added**
  without approval, but call them out in the commit message.
- **Before adding a dependency, check if it's already
  installed.**
- **Native-code dependencies require a platform compatibility
  check.** Anything that compiles native code has to build on
  both developer (macOS arm64) and production (Linux x86_64 or
  arm64) images.

## Imports

- **Absolute imports via `tsconfig.json` paths aliases** —
  `@/core/…`, `@/features/…`, `@/common/…`. No deep relative
  paths like `../../../`.
- **Named exports only.** No `export default` for services,
  handlers, or utilities. Named exports give consistent import
  names and better refactor tooling.
- **Feature boundaries are enforced.** Other features or
  global code import from a feature's `index.ts` barrel only,
  never from its internals. See `05-folder-structure.md`.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), API design (`04-api-design.md`), folder
structure (`05-folder-structure.md`), error handling
(`06-error-handling.md`), build/release (`07-build-and-release.md`),
and module-authoring conventions (`08-module-conventions.md`)
each live in their own file. Don't pile them into this one.
