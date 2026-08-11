# Python Folder Structure

How Python projects are organised. Two reference layouts:
installable packages/libraries and services/applications.

---

## Package/library (src layout)

```text
my-package/
├── pyproject.toml          # Build config, dependencies, tool config (ruff, mypy, pytest)
├── uv.lock                 # Committed lockfile
├── README.md
├── src/
│   └── my_package/
│       ├── __init__.py     # Public API re-exports (see 08-module-conventions.md)
│       ├── py.typed        # Marker file: this package ships type hints
│       ├── core.py
│       └── subpkg/
│           ├── __init__.py
│           └── module.py
├── tests/
│   ├── conftest.py         # Shared fixtures
│   ├── test_core.py
│   └── subpkg/
│       └── test_module.py
└── docs/                   # (optional) Sphinx / mkdocs source
```

- **`src/` layout, not a flat package at the repo root.** This
  forces tests to run against the installed package, catching
  packaging bugs that a flat layout hides.
- **`py.typed`** is required for the package's type hints to be
  respected by consumers' type checkers (PEP 561).

## Service / application

```text
my-service/
├── pyproject.toml
├── uv.lock
├── src/
│   └── my_service/
│       ├── __init__.py
│       ├── main.py         # Entry point: config, logging, app/server startup
│       ├── config.py       # Environment / settings parsing (pydantic-settings)
│       ├── api/             # HTTP routes/views (thin — parse, validate, call service)
│       │   ├── __init__.py
│       │   └── users.py
│       ├── services/        # Business logic (pure where possible)
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── models/           # Domain types, DTOs, ORM models
│       │   ├── __init__.py
│       │   └── user.py
│       ├── repositories/     # Database access
│       │   ├── __init__.py
│       │   └── user_repository.py
│       ├── errors.py         # Error types, HTTP error mapping
│       └── telemetry.py      # Logging / metrics / tracing setup
├── tests/
│   ├── conftest.py
│   ├── api/
│   ├── services/
│   └── repositories/
├── migrations/               # Alembic / Django migrations
└── scripts/                  # One-off operational scripts (not imported by the app)
```

## Key conventions

- **Tests mirror the source tree.**
  `src/my_service/services/user_service.py` →
  `tests/services/test_user_service.py`. See `02-testing.md`.
- **`pyproject.toml` is the single config file** for build
  metadata, dependencies, and tool configuration (`[tool.ruff]`,
  `[tool.mypy]`, `[tool.pytest.ini_options]`). Avoid scattering
  config across `setup.cfg`, `.flake8`, `pytest.ini` when
  `pyproject.toml` can hold it.
- **One-off scripts live in `scripts/`, not `src/`.** A script
  imported nowhere and run manually is not part of the package;
  mixing it into `src/` makes it look like it is.
- **Notebooks (if used for exploration) live outside `src/`**
  (e.g. `notebooks/`) and are never imported by application code.

## Module organisation

- **One concept per module.** `user.py` holds the `User` type and
  closely related logic. If a module exceeds ~300 lines or covers
  two distinct responsibilities, split it.
- **`__init__.py` re-exports the package's public surface**;
  internals stay unimported from the package root. See
  `08-module-conventions.md`.
- **No circular imports.** If two modules need each other, extract
  the shared piece into a third module they both depend on.

## Layering (services)

- **API/view layer is thin.** Parse the request, call a service,
  return a response. No business logic in a route handler.
- **Services own business logic** and accept repositories/clients
  as constructor or function arguments (dependency injection),
  making them testable without a running server or database.
- **Repositories wrap database access.** A repository method is a
  named domain operation (`find_active_by_tenant`), not a thin
  pass-through to raw SQL or the ORM session.
- **Outbound HTTP goes through a typed client** with timeouts and
  retry policy, not ad hoc `requests`/`httpx` calls scattered
  through service code.

## Configuration

- **Settings are parsed once at startup** (`pydantic-settings`, or
  equivalent) into a typed object. No `os.environ.get(...)` calls
  scattered through the codebase — read from the parsed settings
  object.
