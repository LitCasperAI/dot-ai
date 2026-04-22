# .NET Performance

Rules that keep the service responsive under realistic load.
The bar is p95 latency under the SLO the service has published,
not "feels fast on the dev laptop."

---

## Async and the thread pool

- **Async all the way.** A sync-over-async call (`.Result`,
  `.Wait()`, `.GetAwaiter().GetResult()`) blocks a thread-pool
  thread and can deadlock. There is no "safe" usage in request
  handlers.
- **Do not use `Task.Run` to fake async.** Wrapping sync I/O in
  `Task.Run` does not make it non-blocking — it moves the
  block to a pool thread while consuming two threads.
- **CPU-intensive work uses dedicated threads** (via
  `Task.Run` on a background service, or a queue consumer),
  not the request thread. Image processing, heavy
  serialization, or regex over large inputs blocks the pool.
- **`ValueTask` for hot paths** that complete synchronously
  most of the time (cache hits, pooled buffers).
  `Task` is fine everywhere else.

## Database

- **N+1 queries are rejected in review.** A loop that awaits a
  query per iteration is almost always wrong; use `Include`,
  a join, a projection, or a batch query.
- **Every query has an index path.** Before adding a query,
  confirm the index exists or add it in the same PR. EF
  migrations without supporting indexes are incomplete.
- **Select only the columns you need.** `context.Users.ToListAsync()`
  when you need two fields is a hot-path performance bug.
  Use `.Select()` projections.
- **Pagination is keyset-based** (a.k.a. cursor / seek) for
  anything that can grow unbounded. `Skip(n).Take(m)` over
  large tables is a latency cliff.
- **No tracking for read-only queries.** Use
  `AsNoTracking()` on EF queries that do not mutate the
  returned entities. Tracking is memory and CPU overhead.
- **Compiled queries for hot paths.** `EF.CompileAsyncQuery`
  eliminates expression-tree compilation on every call.

## Memory and allocations

- **Avoid allocations on the hot path.** Use
  `Span<T>` / `Memory<T>`, `ArrayPool<T>`, and
  `string.Create` instead of `string.Concat` in tight loops.
- **`StringBuilder` for string concatenation** beyond 3–4
  parts. `string + string + string` in a loop allocates on
  every iteration.
- **Do not accumulate unbounded state in memory.** A static
  `Dictionary` that grows with every request is a slow leak;
  use a bounded cache or move state out of process.
- **IDisposable is disposed.** Every object that implements
  `IDisposable` is in a `using` block or owned by the DI
  container. Undisposed `HttpClient`, `DbConnection`, or
  `Stream` instances are resource leaks.
- **Use `IHttpClientFactory`**, not `new HttpClient()`. The
  factory manages pooling and DNS rotation; a manually
  constructed client leaks sockets.

## Caching

- **Cache with intent.** Every cache entry has a declared TTL,
  a declared invalidation path, and a reason to exist. A cache
  "just in case" is a bug generator.
- **`IMemoryCache` for single-instance caches, `IDistributedCache`
  for shared.** Do not hand-roll a `ConcurrentDictionary`-
  based cache without eviction.
- **Cache keys include a version.** A shape change in the
  cached value without a key bump serves stale data.

## Serialization

- **System.Text.Json is the default serializer.** Newtonsoft
  is accepted for legacy or when a specific feature is needed
  (polymorphic deserialization pre-.NET 7). Do not reference
  both in the same project without an ADR.
- **Source-generated serializers for hot paths.** Use
  `[JsonSerializable]` attributes to avoid runtime reflection.
- **Do not serialize to string when bytes will do.** Use
  `Utf8JsonWriter` and `ReadOnlySpan<byte>` on high-throughput
  endpoints to avoid the UTF-16 → UTF-8 roundtrip.

## HTTP and networking

- **`IHttpClientFactory` with named or typed clients.** Each
  downstream has a configured client with timeout, retry
  (Polly), and circuit-breaker policies.
- **Timeouts are declared on every outbound call.** A request
  that waits forever is a resource leak.
- **Response compression is enabled** in the middleware
  pipeline for responses above 1 KB.

## Measuring

- **Claims about performance come with a measurement.**
  Use BenchmarkDotNet for micro-benchmarks, the project's
  APM stack for production, and paste the numbers in the PR.
- **Regressions show up in dashboards.** p50/p95/p99 latency
  and throughput dashboards exist; a deploy that moves them
  without explanation gets rolled back.
