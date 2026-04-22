# React Native Folder Structure

Feature-first organisation. Code is grouped by **domain**, not by
technical type. Extends the baseline rules in `01-constraints.md`.

---

## Top-level layout

```text
src/
├── app/              # App entry, global providers, root navigation
│   ├── navigation/   # Root navigators (RootStack.tsx, TabNavigator.tsx, linking.ts)
│   ├── App.tsx       # Main application component
│   └── providers.tsx # Global context providers (QueryClientProvider, Theme)
├── assets/           # Static assets
│   ├── images/       # PNGs, JPEGs (keep to a minimum)
│   ├── icons/        # SVGs (react-native-svg)
│   └── fonts/        # Custom TTF/OTF fonts
├── core/             # Foundational, infrastructural code — the app does not run without this
│   ├── theme/        # Global theming system
│   │   ├── colors.ts     # Semantic colour palette
│   │   ├── typography.ts # Fonts, weights, sizes
│   │   ├── spacing.ts    # Margins, padding, radii scales
│   │   └── index.ts      # Theme provider / exports
│   ├── api/          # Base HTTP client, interceptors
│   └── utils/        # System-level utilities (logger.ts, errorHandler.ts)
├── features/         # Feature modules (auth, profile, feed, …)
│   └── [feature]/
│       ├── screens/    # Feature screens (LoginScreen.tsx)
│       ├── components/ # Feature-specific UI
│       ├── hooks/      # Feature-specific hooks
│       ├── services/   # Feature-specific API calls / logic
│       ├── store/      # Feature-specific Zustand store
│       └── index.ts    # Public API for this feature (barrel)
└── common/           # Reusable code used across multiple features
    ├── components/   # Generic UI (Button, Card, TextInput, Screen wrapper)
    ├── hooks/        # Generic hooks (useKeyboard, useDeviceOrientation)
    └── utils/        # Domain-agnostic helpers (formatDate.ts, stringUtils.ts)

e2e/                  # Maestro flows
```

## `core/` vs `common/`

- **`core/`** is infrastructure: theming, base API client, logging,
  error handling. The app does not start without these. Changes
  here are reviewed carefully — they affect every feature.
- **`common/`** is generic reuse: domain-agnostic components,
  hooks, and utilities. Anything in `common/` must be usable by
  any feature without carrying domain assumptions.

If you are about to add something to `common/` that references a
specific feature, it does not belong in `common/`.

## Feature encapsulation

- **Every folder in `src/features/` has an `index.ts` barrel.**
  The barrel is the feature's public surface.
- **Other features and global code import only from the barrel.**
  `import { LoginForm } from '@/features/auth'` — yes.
  `import { LoginForm } from '@/features/auth/components/LoginForm'` —
  forbidden.
- **When code in `features/<x>/` is needed by a second feature,
  it graduates.** Move it to `common/` (UI/hook/util) or `core/`
  (infrastructure). Do not cross-import between features.

## Screens

- Feature screens live in `src/features/<feature>/screens/` and
  are named `<Name>Screen.tsx`.
- Route names in React Navigation match the screen file (see
  `06-navigation.md`).
- Every screen is wrapped with the `Screen` component from
  `@/common/components/Screen` — see `08-component-conventions.md`.

## Services

- **`core/api/`** holds the base HTTP client, interceptors, and
  any request primitives shared across features.
- **`features/<x>/services/`** holds the feature's API calls
  built on top of `core/api/`. A feature does not instantiate its
  own HTTP client.
- Nothing outside these paths talks to the network directly.

## State

- **Feature stores** live in `features/<x>/store/` and are not
  imported outside the feature's barrel.
- **A store shared across features does not exist.** If two
  features need the same state, either (a) the state belongs in
  a third feature both depend on, or (b) it is server state and
  belongs in TanStack Query.

## Tests

- Colocated with the code under test, per `02-testing.md`. No
  parallel `__tests__/` tree.
- Shared test utilities (render helpers, fixtures) live in
  `src/common/test-utils/` and are not imported from production
  code.

## Assets

- `src/assets/` for assets consumed by code via `require()` or
  `import`.
- Images ship in `@2x` and `@3x` variants where applicable, or as
  SVGs via `react-native-svg`.
- No binary assets outside `assets/`.

## What does not live where

- **No screens in `common/components/`.** A component that owns
  a full screen is a screen, and screens belong to a feature.
- **No I/O in `common/utils/` or `core/utils/`.** Utilities are
  pure. Anything that touches network, storage, or a native
  module belongs in `core/api/` or a feature service.
- **No feature code in `common/` or `core/`.** If it is
  billing-only, it lives under `features/billing/`.
- **No cross-feature imports.** If `features/checkout` needs
  something from `features/billing`, that something graduates to
  `common/` or `core/` first.
