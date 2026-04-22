# .NET API Design

How HTTP APIs are shaped. Consistent APIs let callers build
against us without guessing.

---

## HTTP shape

- **REST for resource-oriented APIs** (default). URLs name
  resources (`/users/{id}/orders`), verbs are HTTP verbs, state
  changes map to `POST`/`PUT`/`PATCH`/`DELETE`.
- **Minimal APIs are the default for new endpoints** on .NET 7+.
  Controllers are acceptable in existing projects; do not mix
  both styles in a single project without an ADR.
- **RPC-style (`POST /api/<action>`) is acceptable** for actions
  that are not resource-shaped. Do not force a REST shape onto
  something that is not a resource.

## URLs

- **`kebab-case` in paths, `camelCase` in JSON bodies.** Do
  not mix.
- **Version at the edge.** `/api/v1/...` in the URL for
  externally-facing APIs.
- **Pluralise resource collections.** `/users`, `/orders`.
- **IDs are opaque strings.** Clients do not parse them. If
  we change from `int` to ULID, clients should not care.

## Status codes

- **Use the right code.** 200 for success with a body, 201 for
  created with a `Location` header, 204 for success with no
  body, 400 for input errors, 401 for missing auth, 403 for
  forbidden, 404 for absent resource, 409 for conflict, 422 for
  semantic validation failure, 429 for rate limit, 5xx for our
  mistakes.
- **Do not return 200 with `{ "ok": false }`.** HTTP has status
  codes for a reason.
- **5xx is our fault.** A 500 returned because the client sent
  a bad payload is a mis-mapped error.

## Request / response bodies

- **JSON only for new endpoints.** `multipart/form-data` for
  file upload.
- **Every body is validated** before use. See
  `01-constraints.md`.
- **Dates are ISO 8601 UTC strings.** Unix timestamps are for
  internal metrics, not wire format.
- **Money is an integer in minor units plus a currency code.**
  Never a `decimal` serialised to JSON.

## Error responses

- **One error shape across the service.** Use RFC 7807 Problem
  Details (`ProblemDetails` / `ValidationProblemDetails`) as
  the base. Every error response includes `type`, `title`,
  `status`, and optionally `detail` and `errors`.
- **Validation errors list per-field failures** under `errors`,
  each with a property path and message.
- **Error responses include a `traceId`** from the current
  `Activity` for correlation.

## Idempotency

- **Mutating endpoints that can be retried accept an
  `Idempotency-Key` header.** The server stores the key and
  returns the same response on replay within a window.
- **`PUT` is idempotent; `POST` is not by default.** If you
  want a `POST` to be retry-safe, make it explicit.

## Auth

- **Auth on every endpoint.** Anonymous endpoints are
  explicitly marked with `[AllowAnonymous]`; by default a
  handler without auth is rejected.
- **Authorization is separate from authentication.** A valid
  token says who the caller is; policies say what they can do.
  Use policy-based authorization, not role checks in handlers.
- **Tokens are never in query strings.** Headers only.

## Pagination, filtering, sorting

- **Keyset pagination is the default** for anything that can
  grow unbounded. Offset pagination is rejected for
  user-facing lists.
- **Sort parameters are whitelisted.** Arbitrary user-chosen
  sort columns hit the database without an index path.

## Versioning and deprecation

- **Breaking changes ship as a new version.** v1 stays live
  while clients migrate to v2. Use `Asp.Versioning.Http` or
  the project's declared versioning library.
- **Additive changes (new optional fields, new endpoints) do
  not need a new version.** A new required field in an
  existing request is breaking.

## Documentation

- **Every endpoint is documented.** OpenAPI generated from
  code (Swashbuckle, NSwag, or `Microsoft.AspNetCore.OpenApi`)
  is the single source of truth; hand-written docs drift.
- **Examples are runnable.** A documented request that 400s
  against the real server is worse than no example.
