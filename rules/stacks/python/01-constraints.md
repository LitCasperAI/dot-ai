# Python Constraints

Hard rules for Python code in this project. If a constraint here
conflicts with what you're about to write, stop and escalate —
don't route around it.

---

## Language and toolchain

- **Latest stable CPython the project declares.** The minimum
  version lives in `pyproject.toml` (`requires-python`). Do not
  use syntax newer than that floor.
- **`uv` (or the project's declared tool) manages the venv and
  dependencies.** Never `pip install` into the system
  interpreter. Always activate the project venv first.
- **`ruff` is the linter and formatter.** It replaces
  flake8/isort/black for projects that have adopted it. Do not
  hand-format against what `ruff format` would produce.
- **Static type checking is mandatory** (`mypy` or `pyright`,
  per the project's config). Untyped code is not "faster to
  write" here — it's unreviewable.

## Type safety

- **Type-hint every function signature.** Parameters and return
  type, including `-> None`. An untyped `def` is incomplete, not
  a stylistic choice.
- **No bare `Any` to make a type error go away.** If the type is
  genuinely dynamic, narrow it at the boundary (`isinstance`,
  `TypedDict`, a `Protocol`) rather than laundering it through
  `Any`.
- **Dataclasses or Pydantic models for domain data**, not `dict`
  with string keys. A `dict[str, Any]` passed between functions
  hides its shape from the type checker and the next reader.
- **`Enum` (or `Literal`) over booleans for flags with meaning.**
  A function that takes `strict: bool` is unreadable at the call
  site if `strict` isn't self-evidently the only axis of
  variation; a status/mode argument is an enum.
- **`@dataclass(frozen=True)` for value objects.** Mutable
  dataclasses are for state that's meant to change; everything
  else should be immutable by default.

## Mutability

- **Never use a mutable default argument.** `def f(items=[])` is
  a shared, mutating trap. Default to `None` and construct
  inside the function.
- **Prefer returning new values over mutating arguments in
  place**, except where the function's whole purpose is the
  mutation (and its name says so: `sort`, not `sorted_copy`).

## Error handling

- **Never use a bare `except:`.** Catch the specific exception
  type(s) you can actually handle. A bare `except` (or
  `except Exception` used as a catch-all) swallows bugs along
  with the expected failure.
- **Raise specific, project-defined exceptions**, not `Exception`
  or built-ins reused for domain meaning. See
  `06-error-handling.md`.
- **Chain exceptions with `raise ... from e`** when re-raising in
  a different type, so the original traceback survives.

## Concurrency

- **The GIL means threads don't parallelize CPU-bound work.** Use
  `multiprocessing` (or a process pool) for CPU-bound parallelism;
  threads only help for I/O-bound concurrency.
- **`asyncio` is for I/O concurrency, not CPU work.** Do not put
  CPU-bound computation on the event loop — it blocks every other
  coroutine. Offload to a process pool
  (`loop.run_in_executor`) or a task queue.
- **Do not mix blocking I/O into async code paths.** A synchronous
  `requests.get()` inside an `async def` blocks the whole event
  loop; use an async client (`httpx.AsyncClient`, `aiohttp`) or
  run it in an executor.

## Dependencies

- **No new runtime dependencies without explicit approval.**
  Escalate to the architect. Check whether the standard library
  or an existing dependency already covers the need.
- **Dev-only dependencies** (test, lint, type-check tooling) can
  be added without approval, but call them out in the commit
  message.
- **Lockfile is committed and CI-enforced.** `uv.lock` (or
  `poetry.lock`) pins exact versions; CI fails if it's out of
  sync with `pyproject.toml`.

## Naming

- **PEP 8.** `snake_case` for functions, methods, variables,
  modules; `PascalCase` for classes; `UPPER_SNAKE_CASE` for
  constants.
- **Private module members prefixed with `_`.** A single leading
  underscore signals "not part of the public API" — respect it
  from other modules even though Python doesn't enforce it.
- **Dunder methods (`__init__`, `__repr__`, …) only for their
  documented protocol meaning.** Don't repurpose them as
  general-purpose hooks.

## Imports

- **Import order: standard library, then third-party, then
  local — each group separated by a blank line.** `ruff`
  (isort rules) enforces this; don't hand-order against it.
- **No wildcard imports (`from x import *`)** outside of a
  deliberate `__init__.py` re-export documented as such.
- **Absolute imports within the project package**, not deep
  relative imports (`from ...pkg.sub import x`).

## Things out of scope for this file

Testing (`02-testing.md`), performance (`03-performance.md`),
API design (`04-api-design.md`), folder structure
(`05-folder-structure.md`), error handling
(`06-error-handling.md`), build/release
(`07-build-and-release.md`), and module conventions
(`08-module-conventions.md`) each live in their own file.
