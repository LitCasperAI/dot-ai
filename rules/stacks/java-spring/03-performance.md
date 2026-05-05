# Java / Spring Boot Performance

## JVM tuning

- **Container-aware JVM flags** are set in the Dockerfile or
  helm values, not hardcoded in application code. Use
  `-XX:MaxRAMPercentage` rather than fixed `-Xmx`.
- **GC choice is documented.** G1 is the default. ZGC or
  Shenandoah require an ADR noting the latency profile that
  motivated the switch.
- **Virtual threads (Project Loom)** may be used on JDK 21+ for
  I/O-bound workloads. Do not mix virtual threads with
  `synchronized` blocks that guard long I/O — use
  `ReentrantLock` instead.

## Database

- **N+1 queries are a blocking review finding.** Use
  `@EntityGraph` or join-fetch in the query. Lazy loading is
  fine, but lazy loading inside a loop is not.
- **Pagination is mandatory for list endpoints.** No unbounded
  `findAll()` in controllers. Use `Pageable` and return
  `Page<T>`.
- **Index changes require a load test** or at minimum an
  `EXPLAIN ANALYZE` on representative data. An index without
  evidence is a guess.

## Caching

- **Spring Cache abstraction** (`@Cacheable`, `@CacheEvict`)
  for hot-path reads. Cache names and TTLs are declared in
  config, not annotations.
- **No hand-rolled caches** (raw `ConcurrentHashMap` for
  domain data). Use the cache abstraction so eviction, metrics,
  and distributed caching work uniformly.

## HTTP client

- **WebClient or RestClient** with explicit connect and read
  timeouts. No default-timeout HTTP calls. Retries use
  exponential backoff with jitter.
- **Circuit breakers (Resilience4j)** on calls to external
  services. Configuration is externalised, not hardcoded.

## Startup

- **Lazy initialization is off by default** — Spring Boot
  validates the full context at startup. If startup time
  matters (e.g., serverless), enable lazy init with an ADR
  noting the tradeoff (slower first request, deferred wiring
  errors).

