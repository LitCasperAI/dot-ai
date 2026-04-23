# Rust Performance

Rules that keep the service responsive under realistic load.
Rust gives you the tools to be fast by default — these rules
make sure you don't give that back.

---

## Allocation discipline

- **Minimise heap allocations on the hot path.** Prefer stack
  allocation, `&str` over `String`, `&[T]` over `Vec<T>` for
  read-only data. Profile before optimising, but don't
  allocate carelessly.
- **Reuse buffers.** A `Vec` that is created, filled, and
  dropped every iteration is a waste. Clear and reuse, or use
  an object pool.
- **`String::with_capacity` / `Vec::with_capacity`** when the
  size is known or estimable. Repeated reallocations are a
  measurable cost in tight loops.
- **Avoid `clone()` on the hot path** unless profiling shows
  the copy is cheaper than the borrow-checker gymnastics.
  `clone()` is a tool, not a default.
- **`Cow<'_, str>` / `Cow<'_, [T]>`** when a function
  sometimes borrows and sometimes owns. Avoids unconditional
  allocation.

## Iterators and functional chains

- **Prefer iterator chains over manual loops.** `.filter()`,
  `.map()`, `.flat_map()`, `.collect()` — the compiler
  optimises these to the same (or better) code as hand-written
  loops, and they're more readable.
- **Lazy evaluation.** Iterator chains are lazy by default;
  `.collect()` materialises them. Avoid collecting into a
  `Vec` only to iterate again — chain instead.
- **Use `and_then`, `or_else`, `unwrap_or_else`** (lazy)
  instead of `and`, `or`, `unwrap_or` (eager) when the
  alternative involves computation.

## Data structures

- **`Vec` is the default collection.** For small N, linear
  scan beats hash lookup due to cache locality. Use `HashMap`
  / `BTreeMap` only when lookup-by-key is genuinely needed.
- **`SmallVec` or `ArrayVec` for bounded, small collections**
  that are allocated frequently. Stack-allocated up to the
  declared capacity, heap-allocated beyond.
- **`Box<[T]>` for fixed-size heap arrays** when you know the
  size after construction and don't need `Vec`'s growth.

## Async and the runtime

- **Do not block the async executor.** CPU-bound or
  synchronous I/O work in an `async` task starves other
  tasks. Use `tokio::task::spawn_blocking` (or equivalent)
  for blocking work.
- **Limit task fan-out.** A `join_all` over an unbounded
  iterator is a resource bomb. Use `FuturesUnordered` with
  a concurrency cap or `tokio::sync::Semaphore`.
- **`select!` with cancellation safety.** Every branch in a
  `tokio::select!` must be cancellation-safe or documented as
  not. A future that is dropped mid-`.await` must not corrupt
  state.

## Database

- **N+1 queries are rejected in review.** A loop that awaits a
  query per iteration is almost always wrong; batch or join.
- **Select only the columns you need.** An ORM (Diesel,
  SeaORM) that hydrates every field when you need two is a
  hot-path cost.
- **Connection pooling is mandatory.** Use `deadpool`,
  `bb8`, or `r2d2`. A new connection per request is a
  latency cliff under load.

## Serialization

- **`serde` is the default.** Use `#[derive(Serialize, Deserialize)]`.
  For hot paths, consider `serde_json::from_slice` (zero-copy)
  or a binary format (`bincode`, `rkyv`, `postcard`).
- **Avoid `serde_json::Value` as a data model.** Parse into
  typed structs. `Value` is a dynamic map with allocation on
  every access.

## Measuring

- **Claims about performance come with a benchmark.** Use
  `criterion` for micro-benchmarks, the project's APM stack
  for production. Paste the numbers in the PR.
- **`cargo flamegraph`** for CPU profiling.
  `dhat` or `heaptrack` for allocation profiling.
- **Regressions show up in CI benchmarks** (if the project
  runs them). A deploy that moves p95 without explanation
  gets rolled back.
