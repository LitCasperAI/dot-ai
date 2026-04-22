# React Native Navigation

How screens, routes, and deep links are wired. This project uses
classic React Navigation — there is no file-based router.

---

## One navigation library

- **React Navigation is the navigation library.** Do not mix in
  a second router.
- **Root navigators live in `src/app/navigation/`** (e.g.
  `RootStack.tsx`, `TabNavigator.tsx`) — see
  `05-folder-structure.md`.
- **Native stack (`@react-navigation/native-stack`)** is the
  default stack navigator. JS stack is used only when a specific
  screen needs its capabilities and the reason is documented.

## Typed routes

- **Every navigator declares a typed param list.** No `navigate`
  calls against `any`.
- **Screen components receive typed `route` and `navigation`
  props** via the navigator's helper types. Do not retype them
  by hand per screen.
- **`useNavigation` is typed at the call site** with the
  navigator's generic. Untyped `useNavigation()` is rejected in
  review.

## Route names and params

- Route names are `PascalCase` and match the screen file:
  `BillingDetailsScreen` → route `BillingDetails`.
- Params are serialisable: strings, numbers, booleans, and shallow
  objects of the same. Do not pass functions, class instances, or
  React elements through route params.
- Screens do not read param defaults from random places. If a
  param is optional, the type says so and the screen handles
  `undefined`.

## Deep links

- Deep link configuration lives in one place
  (`src/app/navigation/linking.ts`). No ad-hoc
  `Linking.addEventListener` in screens.
- Every public-facing route has a deep link mapping. Internal
  routes that should not be externally reachable are explicitly
  excluded.
- Deep link params are validated before they are trusted. A URL
  is user input.

## Back behaviour

- **Android hardware back is handled explicitly** on screens
  where the default (pop the stack) is wrong — modals, wizards,
  forms with unsaved changes.
- **Gesture back on iOS is not disabled** without a recorded
  reason. Users expect it.

## Guards and auth

- Auth gating happens at the navigator level, not per screen.
  A screen does not reimplement "if not logged in, bounce to
  login."
- Loading and error states for auth checks have their own
  screens, not a spinner rendered above a half-mounted app.

## Modals and sheets

- Modals are navigation-level modals (stack presentation
  `modal` or a modal navigator), not conditional `<Modal>` tags
  sprinkled in screens.
- Bottom sheets use the project's declared sheet library (e.g.
  `@gorhom/bottom-sheet`). Do not hand-roll one.
