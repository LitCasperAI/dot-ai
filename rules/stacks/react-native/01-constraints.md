# React Native Constraints

Hard rules for React Native code in this project. If a constraint
here conflicts with what you're about to write, stop and escalate —
don't route around it.

These are constraints, not suggestions. Every item in this file is
something that should trigger pushback in code review.

---

## Language and components

- **TypeScript only, strict mode on.** No `.js` or `.jsx` files
  in `src/`. Every new file is `.ts` or `.tsx`. `strict: true`
  in `tsconfig.json` is a hard requirement, not aspirational.
- **Functional components only.** No class components. If you
  need lifecycle behaviour, use hooks.
- **No `any` type.** Use `unknown` if the type is genuinely
  unknown and narrow it before use. If you're tempted to reach
  for `any`, that's a signal the types are modelled wrong — fix
  the model, not the escape hatch. The ban on `any` includes type
  casting (`as any`). Bypassing the type system is a failure of
  architectural standard.
- **Props are typed explicitly.** `type Props = { ... }` above
  the component. No inferring props from usage.
- **Strict Typing in Tests & Mocks.** Do NOT use `any` in test files
  or `jest-setup.js`. Use `unknown`, `jest.Mock`, or define local
  interfaces for partial mocks. If a library type is missing,
  investigate the proper `@types` or cast to a safe alternative.
- **Hermes is the JS engine.** Do not ship code that relies on
  JSC-only behaviour.

## Runtime and architecture

- **Bare React Native.** This project does not use Expo — no
  Expo SDK modules, no `app.config.ts`, no EAS. Do not introduce
  any of them without an ADR.
- **New Architecture (Fabric + TurboModules + Bridgeless) is on.**
  See `03-performance.md`. Do not flip these off to make a
  library work; replace the library or raise the blocker.
- **`ios/` and `android/` are committed and hand-maintained.**
  Native changes go through the native projects directly and are
  reviewed like any other code — see `07-build-and-release.md`.

## File and folder structure

The baseline layout is declared in `05-folder-structure.md`.
This file names only the rules that must hold regardless of how
the tree grows:

- **Feature-first.** Screens, feature-specific components, hooks,
  and services live under `src/features/<feature>/`. Classic
  React Navigation is the navigation model — there is no `app/`
  route tree.
- **Generic reuse lives in `src/common/`.** Domain-agnostic
  components, hooks, and utilities used across features.
- **Infrastructure lives in `src/core/`.** Theme, base API
  client, system-level utilities — the things the app cannot run
  without.
- **All I/O is wrapped.** The base HTTP client lives in
  `src/core/api/`; feature-specific API calls live in
  `src/features/<feature>/services/`. No direct `fetch`,
  storage, or SDK imports from components or screens.

## Styling

- **Use `StyleSheet.create`** for any component that renders
  more than once per screen, or any component exported from
  `src/common/components/`. Inline styles are acceptable only
  for one-off values in a one-off component.
- **No CSS-in-JS runtime libraries** (styled-components, emotion,
  etc.) without explicit approval. Compile-time styling
  solutions are evaluated case by case; `StyleSheet` is the
  default.
- **Design tokens come from `src/core/theme/`**, not from
  literal values in components. A hex code, raw spacing number,
  or font size in a component is a smell — import from
  `theme/colors.ts`, `theme/spacing.ts`, `theme/typography.ts`.

## State and data

- **Local UI state: `useState` or `useReducer`.** Nothing global
  for state that only one component cares about.
- **Shared client state: Zustand.** One store per feature, kept
  small, under `src/features/<feature>/store/`. Contexts are
  used for dependency injection (theme, current user, feature
  flags), not for mutable state shared across the tree — Context
  re-renders every consumer.
- **Server state: TanStack Query.** Any data fetched from an
  API lives in a query, not in a Zustand store and not in
  `useEffect` + `useState`. Mutations use `useMutation` with
  query invalidation.
- **Persistent key-value storage: MMKV**, accessed through a
  storage service. `AsyncStorage` is not used in new code. Never
  import the storage library directly outside the service.
- **Secure storage: `react-native-keychain`** for tokens,
  credentials, and anything `global/08-secrets-and-data.md`
  covers. Never put secrets in MMKV or AsyncStorage.
- **Storage keys follow the pattern `<feature>:<setting>`** and
  are declared as exported constants in the storage service, not
  as string literals at call sites.

## Dependencies

- **No new runtime dependencies without explicit approval.** If
  you think a dependency is needed, stop and escalate to the
  architect. Name what you'd add and why. Do not install
  silently.
- **Dev dependencies (types, test utilities) can be added**
  without approval, but call them out in the commit message.
- **Before adding a dependency, check if it's already
  installed.** The project template includes more than people
  remember.
- **Native-code dependencies require platform-side
  verification.** When installing a library that ships native
  code, verify the iOS `Podfile` / Pod install and the Android
  `build.gradle` / autolinking wiring before considering the
  installation complete. A successful `package.json` install
  that leaves either platform unwired is not done.
- **Jest transform coverage on every new dependency.** Verify
  that `jest.config.js` `transformIgnorePatterns` still covers
  it. Dependencies that ship untranspiled ESM break Jest the
  first time a test touches them; catch it at install, not in
  CI.

## Async and errors

- **Async functions return typed promises.** `Promise<User>`,
  not `Promise<any>` or bare inference.
- **Every async operation that can fail has explicit error
  handling.** No unhandled promise rejections. At minimum, log
  through the project's error service and either re-throw or
  return a typed result — do not silently swallow. See
  `global/09-observability-and-errors.md`.
- **No `.then().catch()` chains for new code.** Use `async/await`
  with `try/catch`, or a TanStack Query error state.

## Imports

- **Absolute imports via `tsconfig.json` paths aliases** — `@/core/…`,
  `@/features/…`, `@/common/…`. No deep relative paths like
  `../../../`.
- **Named exports only.** No `export default` for components,
  hooks, stores, or utilities. Named exports give consistent
  import names and better refactor tooling.
- **Feature boundaries are enforced.** Other features or global
  code import from a feature's `index.ts` barrel only, never
  from its internals. See `05-folder-structure.md`.

## Implementation & Validation Discipline

- **Dependency Discovery**: When building new features, you MUST perform a comprehensive search of the existing codebase to identify relevant API services, hooks, and providers. Do not implement mock data or duplicate functionality without confirming with the user that the necessary backend or service is unavailable.
- **Per-Step Verification**: After completing **every** implementation step
  defined in a plan:
  - **Format**: Run `prettier --write` on all modified files.
  - **Lint**: Run `yarn lint` (or direct `eslint` binary) to catch
    syntax and style issues.
  - **Typecheck**: Run `yarn typecheck` (or direct `tsc` binary) to
    verify type safety.
  - **Test**: Run `yarn test` for any new or affected tests.
- **Stop on Failure**: If any check fails, you **MUST** stop and fix
  the issue before moving to the next step. Never batch validation
  at the end of a feature.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), accessibility (`04-accessibility.md`),
folder structure (`05-folder-structure.md`), navigation
(`06-navigation.md`), build/release (`07-build-and-release.md`),
and component-authoring conventions (`08-component-conventions.md`)
each live in their own file. Don't pile them into this one.
