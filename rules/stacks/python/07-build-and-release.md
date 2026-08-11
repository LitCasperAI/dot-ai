# Python Build and Release

How the project is built, linted, type-checked, and shipped.
Stack-specific expansion of `global/05-version-control.md` and
`global/07-dependencies.md`.

---

## Toolchain

- **`pyproject.toml` declares `requires-python`** and all build
  metadata (PEP 517/518). No `setup.py` in new projects unless a
  dependency forces it.
- **`uv` (or the project's declared tool — Poetry) manages the
  venv, dependency resolution, and the lockfile.** Every
  developer and CI agent installs from the same lockfile.
- **The Python version is pinned** (`.python-version`, or in CI
  config) so local and CI runs use the same interpreter.

## Formatting and linting

- **`ruff format` on every save and in CI.** `ruff format --check`
  fails the build if formatting drifts.
- **`ruff check` is mandatory** for linting (replaces
  flake8/isort/pyupgrade in projects that have adopted it). CI
  runs it with the project's configured rule set — don't
  suppress a rule inline without a comment explaining why.
- **Lint suppressions are scoped.** `# noqa: RULE123` on the
  offending line, never a blanket ignore for a whole file unless
  the file is generated code.

## Type checking

- **`mypy` or `pyright` runs in CI**, per the project's choice,
  and failures block merge. Untyped or `# type: ignore`d code
  that isn't genuinely unavoidable is a review blocker.
- **`# type: ignore[code]` is scoped to the specific error code**
  with a comment explaining why, not a bare `# type: ignore`.

## Dependency auditing

- **`pip-audit` (or the project's declared tool)** checks
  installed dependencies against known vulnerabilities; runs in
  CI on every PR and on a schedule.
- **Dependabot / Renovate** opens PRs for dependency updates; CI
  validates them like any other change before merge.
- **Lockfile changes are reviewed**, not rubber-stamped — a
  dependency bump can carry a transitive vulnerability or a
  breaking change.

## Continuous integration

- **Minimum pipeline:** `ruff format --check` → `ruff check` →
  type check (`mypy`/`pyright`) → `pytest` → dependency audit.
- **Cache the venv / `uv` cache** between CI runs — reinstalling
  the full dependency set on every push is wasted time.
- **Tests run against the same Python version(s) the project
  supports.** If `requires-python` spans multiple minor
  versions, CI runs the matrix.

## Packaging (libraries)

- **`hatchling` (or the project's declared backend) builds
  wheels and sdists** via `pyproject.toml` — no hand-rolled
  `setup.py build`.
- **`pyproject.toml` metadata is complete:** `description`,
  `license`, `authors`, `readme`, `classifiers`,
  `project.urls`.
- **Publish only from tagged commits**, via `uv publish` /
  `twine upload` in CI — never a manual publish from a laptop.
- **Changelog** follows Keep a Changelog format, updated in the
  same PR as the version bump.

## Packaging (services)

- **Multi-stage Docker builds.** Install dependencies in a
  builder stage; copy only the venv/site-packages and
  application code into a slim runtime image
  (`python:3.x-slim`, not the full `python:3.x`).
- **Don't bake secrets into the image.** Configuration comes from
  environment variables or a mounted secrets store at runtime.
- **Health check endpoints** (`/healthz`, `/readyz`) are wired and
  verified by the container orchestrator.
- **Graceful shutdown on `SIGTERM`:** stop accepting new work,
  drain in-flight requests, close DB/connection pools before
  exit.

## Versioning

- **Semver.** See `04-api-design.md` for what constitutes a
  breaking change.
- **Single source of truth for the version number** — either
  `pyproject.toml` or a `__version__` derived from it via
  `importlib.metadata`, never both maintained by hand.
- **Pre-release versions** (`1.0.0a1`, `1.0.0rc1`) for unstable
  APIs, per PEP 440.
