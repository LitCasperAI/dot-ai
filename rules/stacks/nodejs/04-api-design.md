# Node.js API Design

How HTTP and message APIs are shaped. Consistent APIs let
callers build against us without guessing.

---

## HTTP shape

- **REST for resource-oriented APIs** (default). URLs name
  resources (`/users/:id/orders`), verbs are HTTP verbs, state
  changes map to `POST`/`PUT`/`PATCH`/`DELETE`.
- **RPC-over-HTTP (`POST /rpc/<action>`) is acceptable** for
  actions that are not resource-shaped (`/rpc/rotate-keys`).
  Do not force a REST shape onto something that is not a
  resource.
- **GraphQL is an ADR.** This project does not ship a GraphQL
  endpoint without a written decision covering schema
  ownership, query-cost control, and caching strategy.

## URLs

- **`kebab-case` in paths, `camelCase` in JSON bodies.** Do
  not mix.
- **Version at the edge.** `/v1/...` in the URL for
  externally-facing APIs. Internal service-to-service APIs may
  skip the prefix if the service itself is versioned through
  its deployment.
- **Pluralise resource collections.** `/users`, `/orders`, not
  `/user` and `/order`.
- **IDs are opaque strings.** Clients do not parse them. If we
  want to change from integer IDs to ULIDs, clients should not
  have to care.

## Status codes

- **Use the right code.** 200 for success with a body, 201 for
  created with a `Location` header, 204 for success with no
  body, 400 for client input errors, 401 for missing/invalid
  auth, 403 for authorised-but-not-permitted, 404 for absent
  resource, 409 for conflict, 422 for semantic validation
  failure, 429 for rate limit, 5xx for our mistakes.
- **Do not return 200 with `{ "ok": false }`.** HTTP has
  status codes for a reason; a client that has to parse bodies
  to know if the request failed is being asked to do our job.
- **5xx is our fault.** A 500 returned because the client sent
  a bad payload is a mis-mapped error.

## Request bodies

- **JSON only for new endpoints.** `multipart/form-data` is
  acceptable for file upload. `application/x-www-form-urlencoded`
  is legacy.
- **Every body is validated with Zod** before use. See
  `01-constraints.md`.
- **Unknown fields are rejected by default.** Zod's
  `.strict()` on top-level schemas; an unrecognised field is a
  probable bug on the caller.

## Response bodies

- **Successful responses return the resource**, not a wrapper
  with `{ data: ... }` (unless the top-level shape genuinely
  includes metadata — pagination, etc.). Consistency within a
  service matters; pick one and hold to it.
- **Pagination uses a consistent envelope.** The project's
  declared shape (cursor-based by default):

  ```json
  {
    "items": [...],
    "nextCursor": "..." | null
  }
  ```

- **Dates are ISO 8601 UTC strings** (`2026-04-17T12:00:00Z`).
  Unix timestamps are for internal metrics, not wire format.
- **Money is an integer in minor units plus a currency code**.
  Never a float. Never a formatted string.

## Errors

- **One error shape across the service.** See
  `06-error-handling.md`.
- **Error responses include a `code` field** (machine-readable,
  stable) and a `message` field (human-readable, may change).
  Clients switch on `code`, never on `message`.
- **Validation errors list per-field failures** under
  `details`, each with `path` and `message`.

## Idempotency

- **Mutating endpoints that can be retried accept an
  `Idempotency-Key` header.** The server stores the key and
  returns the same response on replay within a window.
- **`PUT` is idempotent; `POST` is not by default.** If you
  want a `POST` to be retry-safe, make it explicit with an
  idempotency key.

## Auth

- **Auth on every endpoint.** Public endpoints are explicitly
  marked in a central route table; by default a handler
  without auth is rejected.
- **Authorisation is separate from authentication.** A valid
  token says who the caller is; it does not say what they can
  do. Check permissions at the service layer, not just the
  route.
- **Tokens are never in query strings.** Headers only.
  Query-string tokens land in access logs.

## Rate limiting

- **Every public endpoint has a rate limit.** The limit lives
  in config, not in code.
- **Rate limit responses include `Retry-After`.** A 429
  without guidance is a client that hammers you harder.

## Pagination, filtering, sorting

- **Cursor pagination is the default** for anything that can
  grow unbounded. Offset pagination is rejected for user-
  facing lists.
- **Filter parameters are explicit.** `?status=active` — yes;
  a generic `?q=` that parses free text is rejected unless it
  is the endpoint's explicit purpose (search).
- **Sort parameters are whitelisted.** `?sort=createdAt:desc`
  where `createdAt` is in a server-side allow list. Arbitrary
  user-chosen sort columns hit the database without an index
  path.

## Versioning and deprecation

- **Breaking changes ship as a new version.** v1 stays live
  while clients migrate to v2; v1 gets a `Deprecation` header
  and a sunset date.
- **Additive changes (new optional fields, new endpoints) do
  not need a new version.** A new required field in an
  existing request is breaking, even if it's "optional for
  now" — ship it as v2.

## Documentation

- **Every endpoint is documented.** OpenAPI generated from Zod
  schemas (via `zod-to-openapi` or the project's declared
  tooling) is the single source of truth; hand-written docs
  drift.
- **Examples are runnable.** A documented request that 400s
  against the real server is worse than no example.
