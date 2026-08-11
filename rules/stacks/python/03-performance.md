# Python Performance

Rules that keep Python code fast enough for its workload. Python
does not give you speed by default — these rules say where to
spend the effort of getting it, and where not to bother.

---

## Measure first

- **Claims about performance come with a profile.** Use
  `cProfile` + `snakeviz`, or `py-spy` (sampling, works on a
  running process without instrumentation) before changing code
  for speed. "It seems slow" is not evidence.
- **`scalene`** for CPU + memory profiling together, useful when
  a "slow" function is actually thrashing memory.
- **Don't micro-optimize cold paths.** A script run once a day
  doesn't need the attention a request handler on the hot path
  does.

## The GIL and where parallelism actually helps

- **Threads help I/O-bound work, not CPU-bound work.** The GIL
  means only one thread runs Python bytecode at a time; use
  threads (or `asyncio`) for concurrent I/O, `multiprocessing`
  (or a process pool) for CPU-bound parallelism.
- **`asyncio` for high-concurrency I/O.** Thousands of concurrent
  network connections are cheaper as coroutines than as OS
  threads. See `01-constraints.md` for the async/sync boundary
  rules.
- **Vectorize numeric work.** A Python `for` loop over a NumPy
  array or Pandas column is orders of magnitude slower than the
  vectorized equivalent (`arr * 2`, `df["col"].sum()`). If you're
  iterating over rows, you're probably fighting the library.

## Data structures

- **`set`/`dict` for membership tests, not `list`.** `x in list`
  is O(n); `x in set` / `x in dict` is O(1). This is the single
  most common easy win in review.
- **`collections.deque` for queues.** `list.pop(0)` is O(n);
  `deque.popleft()` is O(1).
- **`collections.Counter` / `defaultdict`** instead of hand-rolled
  counting or `dict.setdefault` loops.
- **Generators for large or unbounded sequences.** A function
  that returns a `list` when the caller only iterates once is
  paying an unnecessary memory cost — `yield` instead.

## Allocation and object overhead

- **`__slots__` on classes instantiated in bulk.** A class with
  many short-lived instances (parsed rows, graph nodes) pays a
  real memory and attribute-access cost without `__slots__`.
- **Avoid unnecessary copies.** Slicing a large list/array
  (`data[:]`), or passing large structures by value where a view
  or reference would do, adds up on the hot path.
- **`functools.lru_cache` / `functools.cache`** for pure functions
  with a small, repeating input space. Don't cache functions with
  side effects or unbounded input domains without an explicit
  `maxsize`.

## Database and I/O

- **N+1 queries are rejected in review.** A loop that awaits or
  calls a query per iteration is almost always wrong; batch with
  a single query, or use the ORM's eager-loading
  (`select_related`/`prefetch_related` in Django,
  `joinedload`/`selectinload` in SQLAlchemy).
- **Select only the columns you need.** Hydrating a full ORM
  model when two fields are needed is a hot-path cost,
  especially at scale.
- **Connection pooling is mandatory** for any service making
  repeated DB or HTTP calls. A new connection per request is a
  latency cliff.
- **Batch outbound HTTP calls** where the API supports it, and
  use an async or pooled client (`httpx.Client` with
  `limits=`) rather than opening a new connection per call.

## Serialization

- **`orjson` (or `ujson`) over stdlib `json` on the hot path** if
  profiling shows JSON (de)serialization as a bottleneck. Stdlib
  `json` is fine everywhere else — don't add the dependency
  speculatively.
- **Pydantic models validate once at the boundary**, not
  repeatedly downstream. Re-validating the same data on every
  function call is wasted work.

## Startup and import cost

- **Avoid heavy work at module import time.** Importing a module
  should not hit the network, read large files, or do expensive
  computation — that cost is paid on every process start
  (including every test run that imports the module).
- **Lazy-import optional or heavy dependencies** (large ML
  libraries, optional integrations) inside the function that
  needs them if they're not always required.
