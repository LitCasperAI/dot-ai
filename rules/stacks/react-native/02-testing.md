# React Native Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **Unit and component tests: Jest + React Native Testing
  Library (`@testing-library/react-native`).** No Enzyme. No
  shallow rendering.
- **End-to-end tests: Maestro.** Detox is not used in new
  projects; existing Detox suites stay until migrated.
- **Mocking timers and async: Jest fake timers (`jest.useFakeTimers`)
  with `jest.advanceTimersByTimeAsync`.** Do not hand-roll sleeps.

## What to test at which level

- **Hooks in `src/hooks/`** have unit tests using
  `renderHook` from React Native Testing Library.
- **Components in `src/components/`** have render tests that
  exercise their public props, not their internals. Query by role
  or accessibility label, not by `testID` unless nothing else
  identifies the element.
- **Services in `src/services/`** are tested against mocks of
  the external dependency (network, storage, SDK), never against
  the real service.
- **Screens** get a smoke test (renders without throwing given
  sensible props and navigation context) plus at least one test
  per distinct user flow on the screen.
- **Critical user journeys** (auth, checkout, first-run onboarding)
  have a Maestro flow. The flow is the spec.

## Test file layout

- Tests colocate with the code they test: `Foo.tsx` →
  `Foo.test.tsx` in the same folder. No parallel `__tests__/`
  tree.
- Maestro flows live in `e2e/` at the repo root, one YAML per
  flow, named for the journey.

## Queries

- Prefer `getByRole`, `getByLabelText`, `getByText` in that
  order. Fall back to `getByTestId` only when the element has no
  accessible identity and cannot be given one.
- A test that queries by `testID` for something the user can see
  is a signal the component is missing an accessibility label —
  fix the component, not the test.

## Snapshots

- Snapshot tests are allowed only for pure, stable render output
  (icons, static SVGs). No snapshots of screens or anything
  involving async state.
- A snapshot diff is not a passing test. If you cannot explain
  the diff, do not accept it.

## Jest and transforms

- Every new dependency is checked against
  `jest.config.js` `transformIgnorePatterns` at install time, per
  `01-constraints.md`. Do not wait for CI to find the mismatch.
- Do not globally mock React Native modules in `jest.setup.ts`
  unless the team has agreed. Prefer per-test mocking.
