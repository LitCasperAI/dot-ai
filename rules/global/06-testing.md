# Testing

Stack-agnostic testing discipline. Stacks declare *how* to run
tests and *which* frameworks to use; this file declares *what*
good coverage looks like regardless of stack.

## What must be tested

- Every behavioural change lands with a test that would fail
  without it. If you cannot write one, stop and explain why.
- Every bug fix lands with a regression test that reproduces the
  original failure.
- Public contracts (exported APIs, CLI flags, HTTP routes, event
  shapes) have tests. Private helpers do not need their own tests
  if they are covered through their callers.

## What not to mock

- Do not mock the thing you are trying to verify. If the point of
  the test is that the database migration works, the test runs
  against a database.
- Do not mock internal collaborators you control and can exercise
  for real. Reserve mocking for external systems, slow I/O, and
  non-determinism.
- When a mock is required, the fixture lives next to the test and
  is named for what it represents, not for the function it
  replaces.

## Flakiness

- A flaky test is a broken test. Do not retry-loop around it; find
  the race, the time dependency, or the shared state and fix it.
- Never disable a failing test to unblock a merge. If a test must
  be skipped, open an issue, link it in the skip reason, and flag
  it in the PR.

## Test hygiene

- Tests are readable top-to-bottom without jumping between
  helpers. Setup, action, assertion.
- One behaviour per test. A test named `it_works` is not a test.
- Tests do not depend on each other's order. Each test sets up
  and tears down its own state.

## Coverage

- Coverage numbers are a smell detector, not a goal. A file at 95%
  that never exercises the error path is worse than a file at 70%
  that does.
- New code should not regress coverage without a stated reason.
