# Node.js Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **Unit and integration tests: Vitest.** Fast, native ESM,
  first-class TS. Jest and Mocha are not used in new projects;
  existing suites stay until migrated.
- **HTTP-level tests: the framework's own injection API**
  (Fastify's `app.inject`, Express + supertest). No real port
  binding for unit-level HTTP tests.
- **Mocking timers and async: Vitest fake timers
  (`vi.useFakeTimers`) with `vi.advanceTimersByTimeAsync`.** Do
  not hand-roll sleeps.

## What to test at which level

- **Pure functions in `src/common/utils/`, `src/core/utils/`,
  and feature `helpers.ts`** have unit tests. These are the
  fastest and most valuable tests — write them generously.
- **Service functions in `src/features/<x>/services/`** are
  tested with real dependencies where practical (real DB, real
  cache) via Testcontainers; mock only what crosses a network
  boundary outside your control (third-party APIs).
- **Route handlers** get integration tests that exercise the
  full request/response cycle through the framework's
  injection API, hitting a real (Testcontainer-backed) DB.
- **Background workers / queue consumers** are tested by
  enqueuing a real message and asserting on the side effect,
  not by calling the handler function with a fake payload.
- **Contract tests** for outbound HTTP clients verify request
  shape against a recorded response or Pact contract. A client
  wrapper without a contract test is unfinished.

## Test file layout

- Tests colocate with the code they test: `foo.ts` →
  `foo.test.ts` in the same folder. No parallel `__tests__/`
  tree.
- Integration test fixtures (seed data, Testcontainer helpers)
  live in `src/common/test-utils/` and are not imported from
  production code.

## Database in tests

- **Integration tests hit a real database** via Testcontainers
  (or the project's declared equivalent). Mocked ORMs and
  in-memory DB shims are rejected — they drift from production
  behaviour and hide migration bugs.
- **Each test owns its data.** A test either creates the rows
  it reads in a transaction that is rolled back, or uses a
  unique scope (tenant id, run id) so parallel tests don't
  collide.
- **Global test-DB cleanup is a fallback, not a strategy.** A
  suite that relies on "the next suite will clean up" is
  flaky.

## External services

- **Third-party HTTP calls are mocked with MSW** (or
  `nock` for low-level needs). Never hit real third-party
  APIs in CI.
- **Record / replay is a tool, not a crutch.** Recorded
  fixtures go stale; a contract test that runs against the
  provider's sandbox in a nightly job catches drift.

## Snapshots

- Snapshot tests are allowed only for pure, stable output
  (error payload shapes, generated SQL, config
  serialisation). No snapshots of whole HTTP responses.
- A snapshot diff is not a passing test. If you cannot explain
  the diff, do not accept it.

## Coverage

- **Coverage is a floor, not a target.** The global minimum is
  declared in `global/06-testing.md`; services with security
  or money-handling code are expected to run higher.
- **Coverage numbers do not justify missing tests on critical
  paths.** 90% line coverage with the payment flow untested is
  a failing grade.

## Performance and load tests

- **Load tests live in `load/`** at the repo root, using the
  project's declared tool (k6 by default). They are not run in
  PR CI; they are run on a cadence and on release candidates.
- **A claim about throughput comes with a k6 run.** "It seems
  fast" is not evidence.
