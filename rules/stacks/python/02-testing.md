# Python Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **`pytest` for everything.** No `unittest.TestCase` classes in
  new code — plain functions with `assert` and fixtures.
- **Fixtures over `setUp`/`tearDown`.** Shared setup is a
  `@pytest.fixture`, scoped (`function`, `module`, `session`) to
  match its actual lifetime cost.
- **`unittest.mock` (via `pytest-mock`'s `mocker`) for
  mocking.** Prefer designing for testability (dependency
  injection, small pure functions) over mocking frameworks —
  a test with five patches is testing the mock, not the code.
- **`hypothesis` for property-based tests** on functions with a
  wide input domain: parsers, serializers, numeric code.

## What to test at which level

- **Pure functions and data transformations** get unit tests —
  the fastest, most valuable tests. Write them generously.
- **Public module functions** are tested through their public
  signature, not by reaching into private helpers (`_foo`)
  directly. If a private helper needs its own test, that's a
  sign it should be a public function.
- **I/O and network code** (HTTP calls, DB access, file I/O) is
  wrapped behind a thin interface and mocked in unit tests;
  integration tests exercise the real thing against a test
  database or a recorded fixture (`responses`, `vcr.py`) — never
  a live third-party API in CI.
- **CLI entry points** are tested with `click.testing.CliRunner`
  (or the equivalent for the project's CLI framework), not by
  shelling out to a subprocess.

## Test naming

- **Test functions are named for the scenario**, not the
  implementation: `test_parse_rejects_malformed_utf8`, not
  `test_parse_2`. A failing test name should tell you what broke
  without opening the file.
- **Group related tests in a class only when they share a
  fixture**, not for cosmetic organization. A `class TestParser:`
  with no shared state is just indentation.

## Test file layout

- **Tests live in `tests/`, mirroring the package structure.**
  `src/pkg/data/parser.py` → `tests/data/test_parser.py`. This
  is the default; see `05-folder-structure.md` for the full
  layout.
- **One test file per source module.** A test file that grows to
  cover three unrelated modules should split.
- **Fixtures shared across a directory go in that directory's
  `conftest.py`.** Fixtures shared project-wide go in the root
  `conftest.py`. Don't import fixtures directly between test
  files — pytest's discovery makes that unnecessary.
- **Test fixtures (sample files, golden outputs)** live in
  `tests/fixtures/` or `tests/data/`, never inside `src/`.

## Parametrization

- **`@pytest.mark.parametrize` for input/output tables**, not a
  loop inside a single test function. Parametrized cases show up
  individually in test output and can fail independently.

  ```python
  @pytest.mark.parametrize(
      "raw, expected",
      [
          ("123", 123),
          ("-5", -5),
          ("", None),
      ],
  )
  def test_parse_int(raw: str, expected: int | None) -> None:
      assert parse_int(raw) == expected
  ```

## Mocking and fakes

- **Prefer fakes over mocks for anything with real behavior.** A
  small in-memory fake repository is more trustworthy than a
  mock asserting on call arguments.
- **Patch where the name is looked up, not where it's defined.**
  `mocker.patch("pkg.module.func")`, not
  `mocker.patch("other_pkg.func")` — a classic `mock.patch`
  footgun.
- **Never mock the function under test.** If you're patching the
  thing the test is supposed to verify, the test is vacuous.

## Coverage

- **Coverage is a floor, not a target.** The global minimum is
  declared in `global/06-testing.md`. Use `pytest-cov` /
  `coverage.py` for collection.
- **Branches matter, not just lines.** Run with
  `--cov-branch`; a line that's "covered" by a test that never
  exercises its `else` isn't really covered.

## Fixtures for external services

- **`pytest-httpserver` or `responses`** for HTTP dependencies.
- **A disposable test database** (SQLite in-memory, or a
  containerized Postgres via `testcontainers`) for DB tests —
  never point tests at a shared dev or staging database.
- **Freeze time with `freezegun` or `time-machine`** for any test
  whose assertions depend on the current time.

## Async tests

- **`pytest-asyncio`** (`@pytest.mark.asyncio`, or
  `asyncio_mode = "auto"` in config) for testing coroutines.
  Don't wrap async code in `asyncio.run()` inside a sync test —
  let the plugin manage the event loop.
