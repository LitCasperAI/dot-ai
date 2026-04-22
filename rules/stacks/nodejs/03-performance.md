# Node.js Performance

Rules that keep the service responsive under realistic load. The
bar is p95 latency under the SLO the service has published, not
"feels fast on the dev laptop."

---

## Async and the event loop

- **The event loop is single-threaded.** CPU-heavy work
  (cryptography, large JSON parsing, image manipulation,
  regex pathologies) blocks every in-flight request. Move it
  to a worker thread, a queue consumer, or a different
  service.
- **`JSON.parse` on large payloads is CPU-heavy.** Stream large
  payloads with a streaming parser rather than buffering and
  parsing in one shot.
- **Do not mix sync and async I/O.** `fs.readFileSync` in a
  request handler is a bug, not a shortcut.

## Database

- **N+1 queries are rejected in review.** A loop that awaits a
  query per iteration is almost always wrong; use a join, an
  `IN` clause, or a batch loader (DataLoader).
- **Every query has an index path.** Before adding a query,
  confirm the index exists or add it in the same PR. Schema
  changes without the supporting indexes are incomplete.
- **Select only the columns you need.** `SELECT *` plus an ORM
  that hydrates every field is a hot-path performance bug.
- **Pagination is cursor-based** for anything that can grow
  unbounded. `OFFSET` pagination over large tables is a
  latency cliff.

## Caching

- **Cache with intent.** Every cache entry has a declared TTL,
  a declared invalidation path, and a reason to exist. A cache
  "just in case" is a bug generator.
- **Cache keys include a version.** A shape change in the
  cached value without a key bump serves stale data to every
  consumer.
- **Negative caching** (cache the "not found") is considered
  explicitly on read-heavy lookups — a miss storm is a real
  failure mode.

## Concurrency and parallelism

- **Independent awaits run in parallel.** `Promise.all` for
  independent work; sequential `await`s for independent calls
  are a latency bug.
- **Bound fan-out.** A `Promise.all` over a user-controlled
  array size is a DoS vector against yourself. Use
  `p-limit` or the project's declared concurrency primitive.
- **Timeouts are declared on every outbound call.** A request
  that waits forever is a resource leak; the upstream dying
  must not pin a connection.

## HTTP and networking

- **Keep-alive is on for outbound HTTP clients.** Every request
  paying a new TCP+TLS handshake is a waste.
- **Connection pools are sized to backpressure correctly.** A
  pool too small serialises work; too large overruns the
  downstream.
- **Large responses stream.** A 50 MB response buffered in
  memory is a memory incident waiting for one slow consumer.

## Memory

- **Do not accumulate unbounded state in memory.** A global
  `Map` that grows with every request is a slow leak; use a
  bounded LRU or move state out of process.
- **Large buffers are released.** Holding a reference keeps
  the buffer alive; clear locals when you're done.
- **Heap snapshots are the source of truth for leak claims.**
  "It feels like a leak" is not evidence.

## Worker threads and processes

- **Worker threads for CPU-bound work** that is too small for
  its own service. The main loop stays responsive.
- **Clustering is the runtime's job**, not the app's. Run one
  process per container and scale horizontally; do not
  reinvent `cluster` inside the app.

## Logging

- **Logging is not free.** A log line per request is fine; a
  log line per database row is a throughput bug.
- **Log levels exist.** Debug logs are off in production by
  default; turning them on is a deliberate operational act.

## Measuring

- **Claims about performance come with a measurement.**
  "Feels faster" is not evidence. Use the project's
  tracing/APM stack, `clinic.js`, or `0x` for profiling and
  paste the numbers into the PR.
- **Regressions show up in dashboards.** p50/p95/p99 latency
  and throughput dashboards exist for every service; a deploy
  that moves them without explanation gets rolled back.
