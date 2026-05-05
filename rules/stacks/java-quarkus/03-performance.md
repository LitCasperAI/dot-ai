# Java / Quarkus Performance

Rules that keep the service responsive under realistic load.

---

## JVM vs Native

- **Deployment target is documented.** Quarkus supports JVM mode and Native mode (GraalVM). 
  If Native mode is required, the build pipeline and dependencies must be compatible. 
  Do not introduce dependencies that heavily rely on reflection without testing native compilation.
- **Container-aware JVM flags** are used if running in JVM mode. Use `-XX:MaxRAMPercentage` 
  rather than fixed `-Xmx`.

## Reactive vs Imperative

- **RESTEasy Reactive is the default.** You can write both blocking and non-blocking code.
- **Blocking I/O:** If a method blocks (e.g., JDBC database access), annotate it with `@Blocking` 
  or ensure the signature doesn't return `Uni`/`Multi`. Quarkus routes these to worker threads.
- **Non-blocking I/O:** If a method is purely reactive (e.g., Reactive Hibernate, reactive HTTP client), 
  it runs on the event loop. **Never block the event loop.**
- **Virtual threads (Project Loom):** On JDK 21+, use `@RunOnVirtualThread` for blocking workloads 
  to run on virtual threads instead of the standard worker pool, improving concurrency without 
  the cognitive overhead of reactive programming.

## Database

- **N+1 queries are a blocking review finding.** Use `fetch join` in JPQL or entity graphs. 
  Lazy loading inside a loop is rejected.
- **Pagination is mandatory for list endpoints.** No unbounded `listAll()` in Panache. 
  Use `PanacheQuery<T>.page()`.
- **Index changes require a load test** or at minimum an `EXPLAIN ANALYZE` on representative data.

## Caching

- **Quarkus Cache extension** (`@CacheResult`, `@CacheInvalidate`) for hot-path reads. 
  Cache names are declared in annotations, config and TTLs in `application.yaml`.
- **No hand-rolled caches for domain data.** Do not use raw `ConcurrentHashMap` to cache business entities or API responses. Use the cache abstraction so eviction, metrics, and distributed caching work uniformly.
- **Infrastructure caching.** Using `ConcurrentHashMap` is acceptable *only* for caching thread-safe infrastructure components or clients (e.g., GCP PubSub Publishers, gRPC channels) where the standard cache extension adds unnecessary overhead.

## HTTP client

- **Quarkus REST Client (MicroProfile REST Client)** with explicit connect and read timeouts. 
  No default-timeout HTTP calls.
- **Fault Tolerance (SmallRye Fault Tolerance)** for retries (`@Retry`) and circuit breakers 
  (`@CircuitBreaker`) on calls to external services. Configuration is externalised.