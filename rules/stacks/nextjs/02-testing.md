# Next.js Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **Unit tests: Vitest.** Fast, native ESM, first-class TS.
  Jest is not used in new projects; existing Jest suites stay
  until migrated.
- **Component tests: Vitest + React Testing Library
  (`@testing-library/react`).** No Enzyme. No shallow rendering.
- **End-to-end tests: Playwright.** Cypress is not used in new
  projects.
- **Mocking timers and async: Vitest fake timers
  (`vi.useFakeTimers`) with `vi.advanceTimersByTimeAsync`.** Do
  not hand-roll sleeps.

## What to test at which level

- **Hooks in `src/common/hooks/` and `src/features/<x>/hooks/`**
  have unit tests using `renderHook` from React Testing Library.
- **Client components** have render tests that exercise their
  public props. Query by role or accessibility label, not by
  `data-testid` unless nothing else identifies the element.
- **Server components** are tested by rendering through the
  route (via Playwright) or by extracting the data-layer logic
  into a plain async function and unit-testing that function.
  Do not invoke server components directly in Vitest — the RSC
  test story is not stable enough to build on.
- **Route handlers (`route.ts`)** are tested by calling the
  exported `GET` / `POST` / etc. with a real `Request` object
  and asserting on the `Response`. No mocking of Next.js
  internals.
- **Server Actions** are tested by importing the function and
  calling it. Treat them like the server-side functions they
  are.
- **Critical user journeys** (auth, checkout, first-run
  onboarding) have a Playwright flow. The flow is the spec.

## Test file layout

- Tests colocate with the code they test: `Foo.tsx` →
  `Foo.test.tsx` in the same folder. No parallel `__tests__/`
  tree.
- Playwright specs live in `e2e/` at the repo root, named for
  the journey.

## Queries

- Prefer `getByRole`, `getByLabelText`, `getByText` in that
  order. Fall back to `getByTestId` only when the element has
  no accessible identity and cannot be given one.
- A test that queries by `data-testid` for something the user
  can see is a signal the component is missing an accessible
  role or label — fix the component, not the test.

## Snapshots

- Snapshot tests are allowed only for pure, stable render output
  (icons, static SVGs, error payload shapes). No snapshots of
  pages or anything involving async state.
- A snapshot diff is not a passing test. If you cannot explain
  the diff, do not accept it.

## Network and data

- **Tests do not hit real network.** Use MSW (Mock Service
  Worker) for component-level request mocking; stub the data
  function directly for server-side unit tests.
- **Database-backed tests** run against a real database spun
  up for the test run (Testcontainers or equivalent), not a
  mock ORM. See `global/06-testing.md`.

## Playwright specifics

- One worker per project in CI; parallelism comes from shards,
  not concurrent workers against a shared DB.
- `test.describe.configure({ mode: 'serial' })` is a smell —
  if tests must run in order, they are sharing state they
  shouldn't be.
- `page.waitForTimeout` is banned. Wait on a condition, not a
  clock.
