# .NET Constraints

Hard rules for .NET code in this project. If a constraint here
conflicts with what you're about to write, stop and escalate —
don't route around it.

These are constraints, not suggestions. Every item in this file
is something that should trigger pushback in code review.

---

## Language and runtime

- **C# only, latest stable LTS language version.** The project
  declares `LangVersion` in `Directory.Build.props`. Do not
  override it per-project.
- **Target the current LTS framework(s).** The project declares
  `TargetFramework(s)` in `Directory.Build.props` or
  per-project. Multi-targeting is normal for libraries; backend
  services pin a single TFM.
- **Treat warnings as errors.** `TreatWarningsAsErrors` is
  `true` in `Directory.Build.props`. Do not suppress a warning
  without a comment explaining why.
- **Nullable reference types are enabled.** `<Nullable>enable</Nullable>`
  is the default. Do not disable it. Every `null` is typed.
- **No `dynamic`.** If you're tempted to reach for `dynamic`,
  the types are modelled wrong — fix the model.

## Code style (enforced by .editorconfig)

- **Use language keywords over BCL names.** `int`, not `Int32`.
  `string`, not `String`. Enforced as an error.
- **Pattern matching over cast-checks.** `is` with pattern
  matching instead of `is` + cast, `as` + null-check. Enforced
  as an error.
- **Accessibility modifiers are explicit.** Every type and
  member has a modifier. `dotnet_style_require_accessibility_modifiers`
  = error.
- **Fields are `readonly` where possible.** Enforced as an error.
- **Avoid `this.` qualification** unless needed for disambiguation.
- **Use object/collection initialiser syntax** where practical.
- **Constants are `PascalCase`.** All other naming follows
  standard .NET conventions.

## Architecture and layering

- **HTTP is a transport, not a layer of business logic.**
  Controllers/minimal API handlers are thin: validate input,
  call a service, shape the response. Business rules live in
  a service or domain layer.
- **No singletons constructed at import time** beyond pure
  constants. Services are registered in DI and injected; a
  static `new DbContext()` is rejected in review.
- **Depend on abstractions.** Services accept interfaces, not
  concrete types. The composition root wires them up.
- **Keep members in execution order**, not grouped by access
  level. Override SA1201/SA1202 to favour readability over
  alphabetical/accessibility grouping.

## Input validation

- **Every external input is validated before use.** HTTP
  bodies, query strings, path params — parsed, not cast.
  Use FluentValidation, Data Annotations, or a hand-rolled
  validator; pick one per project and stick to it.
- **Validation errors return 400 with a structured error
  payload.** See `global/09-observability-and-errors.md`.

## Database and I/O

- **One ORM / data access pattern per project.** EF Core is the
  default; Dapper is acceptable for read-heavy hot paths. Do
  not mix without an ADR.
- **Transactions are explicit.** A multi-statement mutation runs
  inside a transaction scope; relying on "it usually works" is
  not a strategy.
- **Connections are pooled and bounded.** Pool size is declared
  in config and matches the database's capacity.

## Async and errors

- **Async all the way.** Do not call `.Result` or `.Wait()` on
  tasks — that deadlocks under SynchronizationContext and
  wastes threads. Use `await`.
- **`ConfigureAwait(false)` in library code.** Backend services
  targeting ASP.NET Core (no `SynchronizationContext`) may omit
  it; libraries must use it.
- **Domain errors are typed exceptions** or a Result pattern
  (discriminated union / `OneOf`). `throw new Exception("not found")`
  is rejected — use `throw new NotFoundException(...)` and let
  middleware map it.
- **Catch specific exceptions.** `catch (Exception ex)` at the
  top level only; feature code catches the narrowest type.

## Process lifecycle

- **Graceful shutdown is wired.** The host stops accepting new
  requests, drains in-flight work within a timeout, and
  disposes DI-scoped resources. A service that crashes on
  `SIGTERM` kills in-flight requests.
- **Configuration is loaded at boot and validated.** A missing
  required setting crashes on startup, not on the first
  request. Use the Options pattern with `IValidateOptions<T>`.

## Secrets and config

- **Config comes from `appsettings.json` + env vars**, loaded
  through `IConfiguration` / Options pattern. No
  `Environment.GetEnvironmentVariable("FOO")` sprinkled
  across the codebase.
- **Secrets are never logged.** The logger has a redaction
  policy; if a new secret is added, the redaction is updated
  in the same PR. See `global/08-secrets-and-data.md`.
- **No secrets in the repo.** Not in `appsettings.json`, not
  in fixtures, not in committed test config.

## Observability

- **Structured logs (JSON) only in deployed environments.** Use
  the project's declared logger (Serilog or
  `Microsoft.Extensions.Logging`). No `Console.WriteLine` in
  production code.
- **Every request has a correlation ID** propagated through
  `Activity` / `IHttpContextAccessor`. Downstream calls
  propagate it.
- **Metrics and traces** are wired through OpenTelemetry by
  default. Do not hand-roll an alternative.

## Dependencies

- **No new runtime dependencies without explicit approval.**
  If you think a dependency is needed, escalate to the
  architect.
- **Centralized package management.** Versions are declared in
  `Directory.Packages.props` (Central Package Management) or
  `Directory.Build.props`. Individual projects do not
  specify versions.
- **NuGet audit is enabled.** Vulnerabilities flagged by
  `dotnet restore` are addressed immediately.
- **Analyzers are dev-only.** Mark analyzer packages as
  `PrivateAssets="all"`.

## Imports / usings

- **Global usings are declared centrally** in a
  `GlobalUsings.cs` or `Directory.Build.props`. Do not
  `global using` inside feature files.
- **`using` directives are outside the namespace.**
- **Sort System namespaces first.**

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), API design (`04-api-design.md`), folder
structure (`05-folder-structure.md`), error handling
(`06-error-handling.md`), build/release (`07-build-and-release.md`),
and library-specific conventions (`08-library-conventions.md`)
each live in their own file. Don't pile them into this one.
