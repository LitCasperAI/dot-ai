# Java / Spring Boot API Design

## REST conventions

- **Resource-oriented URLs.** `/api/v1/orders/{id}`, not
  `/api/v1/getOrder`. Verbs come from HTTP methods, not paths.
- **HTTP methods match semantics.** GET is safe and idempotent.
  PUT is idempotent. POST creates. PATCH partially updates.
  DELETE is idempotent.
- **Status codes are correct.** 201 for creation with
  `Location` header. 204 for successful delete with no body.
  400 for validation errors. 404 for missing resources. 409
  for conflicts. 500 is never returned intentionally.
- **RFC 7807 Problem Detail** for all error responses. The
  global `@RestControllerAdvice` handles mapping.

## Request/response

- **Records for request and response bodies.** Validated with
  Jakarta Bean Validation (`@NotNull`, `@Size`, `@Pattern`,
  etc.) and `@Valid` on the controller parameter.
- **No entity exposure.** Never return a JPA entity directly
  from a controller. Map to a response record. This prevents
  lazy-loading exceptions, circular references, and leaking
  internal fields.
- **Pagination response shape** follows Spring's `Page<T>`
  serialisation or a project-specific wrapper declared in
  `src/core/api/`.

## Versioning

- **URL-based versioning** (`/api/v1/`, `/api/v2/`). Breaking
  changes bump the version. Non-breaking additions (new
  optional fields) do not.
- **Deprecation is explicit.** `@Deprecated` + OpenAPI
  `deprecated: true` + a sunset date in the response header.

## Documentation

- **OpenAPI spec is generated from code** (springdoc-openapi).
  Hand-written specs drift; generated specs don't. Annotations
  (`@Operation`, `@Schema`) enrich the output.

