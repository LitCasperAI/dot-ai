# Python API Design

How public package APIs and HTTP service APIs are shaped.

---

## Package/library API design

- **Every public function and class has a type-hinted
  signature.** The signature is the contract; a caller should
  not need to read the body to know what to pass.
- **Accept the most general type that works, return the most
  specific.** Accept `Iterable[str]` instead of `list[str]` if
  you only iterate once; return a concrete `list[str]` so the
  caller doesn't have to guess what operations are valid.
- **Keyword-only arguments for anything beyond two or three
  positional parameters**, especially booleans:
  `def resize(image, *, width: int, height: int) -> Image`.
  A call site with three positional booleans is unreadable.
- **`@dataclass` or Pydantic models for structured return
  values**, not `tuple` for anything beyond a pair, and never a
  bare `dict`. `def parse(s) -> tuple[str, int, bool]` forces
  every caller to remember field order.
- **`__all__` in every module that has a public API**, listing
  exactly what's exported. Anything not listed is implementation
  detail, even if importable.
- **Docstrings on every public function/class** (Google or NumPy
  style, per the project's existing convention) with Args,
  Returns, and Raises. See `08-module-conventions.md`.

## HTTP API design (services)

- **REST for resource-oriented APIs** (default), using the
  project's declared framework (FastAPI, Flask, Django REST
  Framework). Handlers/views are thin: parse, validate, call a
  service, respond.
- **Request and response bodies are typed models** (Pydantic in
  FastAPI, serializers in DRF) — never raw `dict` parsed ad hoc
  from `request.json()`.
- **`snake_case` in JSON bodies** unless the project has an
  established `camelCase` convention for a specific client;
  pick one per project and hold to it.
- **Status codes are correct and consistent:** 200 (success),
  201 (created), 204 (no content), 400 (malformed request), 401
  (unauthenticated), 403 (unauthorized), 404 (not found), 409
  (conflict), 422 (validation failure), 429 (rate limited), 5xx
  (server error). These rules are language-agnostic — see
  `nodejs/04-api-design.md` for the same table.
- **One error shape across the service.** A structured JSON
  error body with `code` (machine-readable), `message`
  (human-readable), and optional `details`. See
  `06-error-handling.md`.

## Naming (PEP 8 / public surface)

- **`snake_case` functions and methods, `PascalCase` classes,
  `UPPER_SNAKE_CASE` constants.**
- **Boolean-returning functions read as predicates:** `is_valid`,
  `has_permission`, `can_retry` — not `valid`, `check_permission`.
- **Factory functions are named `create_x` / `from_x` / `make_x`**,
  not overloaded onto `__init__` with a dozen optional
  parameters.

## Versioning

- **Follow semver.** A removed public function, a changed
  signature, or a behavior change on an existing code path is a
  major bump. New additive functionality is minor. Bug fixes are
  patch.
- **Deprecate before removing.** Use the `warnings` module
  (`warnings.warn(..., DeprecationWarning, stacklevel=2)`) for at
  least one minor release before deleting a public function.
- **Changes to a public HTTP API are versioned in the URL or a
  header** (`/v2/...` or `Accept-Version`), per the project's
  convention — never a silent breaking change to an existing
  endpoint.

## Predictability

- **No out-parameters.** Return a new value instead of mutating a
  passed-in argument, unless the function's name says it mutates
  (`list.sort()`, not `def process(items)` that mutates
  `items` silently).
- **A function does one thing implied by its name.** A
  `get_user()` that also creates the user as a side effect is a
  predictability bug waiting to bite the next caller.
- **Operators (`__eq__`, `__lt__`, `__add__`) do the unsurprising
  thing.** Overloading `+` on a domain object to mean something
  other than combination is a footgun for every future reader.
