# Java / Quarkus API Design

How HTTP APIs are shaped. Consistent APIs let callers build against us without guessing.

---

## REST conventions

- **Resource-oriented URLs.** `/api/v1/orders/{id}`, not `/api/v1/getOrder`. 
  Verbs come from HTTP methods, not paths.
- **HTTP methods match semantics.** GET is safe and idempotent. PUT is idempotent. 
  POST creates. PATCH partially updates. DELETE is idempotent.
- **Status codes are correct.** 201 for creation with `Location` header. 
  204 for successful delete with no body. 400 for validation errors. 
  404 for missing resources. 409 for conflicts. 500 is never returned intentionally.
- **Consistent error responses.** Use a global `ExceptionMapper` to catch unhandled exceptions. Return standard JAX-RS `WebApplicationException` responses for known HTTP errors, and simple, generic error strings or JSON for 500s to avoid leaking stack traces.

## Request/response

- **Generated POJOs for request and response bodies.** Because we use API-First design, models are generated from `api-docs.yaml`. They are validated with Jakarta Bean Validation (`@NotNull`, `@Size`, `@Pattern`, etc.) and `@Valid` on the resource method parameter.
- **No entity exposure.** Never return a database entity (Panache, JPA, or Spanner domain objects) directly from a REST resource. Map it to a generated response model. This prevents leaking internal fields and circular references.
- **Pagination response shape** follows a project-specific wrapper or standard offset/limit 
  metadata included in the response.

## Versioning

- **URL-based versioning** (`/api/v1/`, `/api/v2/`). Breaking changes bump the version. 
  Non-breaking additions (new optional fields) do not.
- **Deprecation is explicit.** `@Deprecated` + OpenAPI `@Operation(deprecated = true)`.

## Documentation

- **API-First Design.** The `api-docs.yaml` spec is the source of truth. 
  Code (models and interfaces) is generated from the OpenAPI spec using the OpenAPI Generator plugin. 
  SmallRye OpenAPI may be used to expose the UI, but the spec itself is hand-written or centrally managed, not generated from Java annotations.