# Python Module Conventions

How individual modules are authored, split, and composed. This
file covers _within-module_ structure; `05-folder-structure.md`
covers _between-module_ organisation.

---

## One concern per file

- **Each module has one reason to change.** A service module, a
  repository module, a schema module — separate files. A
  1,000-line `utils.py` that everything imports from is rejected
  in review.
- **Split when a file exceeds ~300 lines** or its exports cover
  two distinct responsibilities. Don't split pre-emptively into
  ten-line files.

## `__init__.py` as the public surface

- **`__init__.py` re-exports the package's public API**; internal
  modules stay unimported from the package root.

  ```python
  # my_package/__init__.py
  from my_package.core import process_order
  from my_package.errors import OrderError, ValidationError

  __all__ = ["process_order", "OrderError", "ValidationError"]
  ```

- **`__all__` is explicit wherever a module or package has a
  public API.** It documents the contract and controls
  `from module import *` (which itself is discouraged, per
  `01-constraints.md`).
- **Internal-only modules are prefixed with `_`**
  (`_internal.py`) or kept out of `__init__.py`'s re-exports —
  either signals "not part of the contract."

## Imports

- **Absolute imports within the project package.** `from
  my_package.services.user import create_user`, not deep
  relative chains (`from ...services.user import create_user`).
- **Relative imports (`.`, `..`) are acceptable within a
  package for closely related siblings** (`from .errors import
  AppError` inside the same subpackage), not for reaching across
  the package tree.
- **No circular imports.** If module A needs B and B needs A,
  extract the shared piece into a module both depend on, or
  invert the dependency.
- **Import ordering: standard library → third-party → local**,
  each group separated by a blank line, alphabetized within each
  group. `ruff` enforces this — don't hand-order against it.

## Functions and classes

- **A function does one thing its name says it does.** A
  `get_or_create_user()` should not also send a welcome email as
  a hidden side effect.
- **Dependencies are passed in, not imported at call time inside
  the function.** A service function that does
  `from my_package.db import get_session` inline is hard to test
  in isolation; accept the session/client as a parameter.
- **Prefer functions over classes when there's no state to
  hold.** A class with only `__init__` and one method that uses
  its attributes once is a function with extra ceremony.
- **Classmethods for alternate constructors**
  (`@classmethod def from_dict(cls, data): ...`), not a
  constructor with a dozen optional parameters covering every
  input format.

## Docstrings and comments

- **Every public module, class, and function has a docstring**
  (Google or NumPy style, matching the project's existing
  convention) — see `04-api-design.md` for what belongs in it.
- **Comments explain why, not what.** `# retry because the
  upstream API rate-limits in bursts` is useful; `# increment
  counter` above `counter += 1` is not.

## Configuration and globals

- **No module-level mutable state** that multiple call sites
  mutate (a module-level `list`/`dict` used as shared cache or
  registry). If shared state is genuinely needed, make it
  explicit — a class instance passed around, not an implicit
  module global.
- **No `os.environ.get(...)` scattered through modules.**
  Configuration is read once at startup into a typed settings
  object; modules receive what they need as arguments. See
  `05-folder-structure.md`.

## Logging inside modules

- **Each module gets its own logger:**
  `logger = logging.getLogger(__name__)`. Never a single
  root-logger call site shared across the codebase without a
  module name — it makes log lines unattributable.
- **Log at boundaries** (entering/leaving an external call, a
  DB transaction), not on every function call. Per-call logging
  is noise, not signal.
