# React Native Performance

Rules that keep the app responsive on mid-range Android hardware,
which is the bar — if it works there, it works on iOS.

---

## New Architecture

- **The New Architecture (Fabric + TurboModules) is on.** Do not
  disable it to work around a library. If a library does not
  support the New Architecture, raise it rather than flipping the
  flag.
- **Bridgeless mode stays on** once enabled. Code that assumes
  the legacy bridge (synchronous native calls, global event
  emitter hacks) is rejected in review.

## Lists

- **Long or unbounded lists use FlashList**, not `FlatList`.
  `ScrollView` with a `.map()` is acceptable only for known-small,
  known-bounded collections.
- **Every list item has a stable `keyExtractor`.** Array index is
  not a stable key for anything that can reorder, insert, or
  delete.
- **`estimatedItemSize` (FlashList) is set to a realistic value.**
  An order-of-magnitude guess is worse than measuring one render.

## Rendering and memoization

- **Do not reach for `React.memo`, `useMemo`, or `useCallback`
  reflexively.** Measure first. Gratuitous memoization adds cost.
- **A component that re-renders on every parent render is fine
  unless a profile says otherwise.** The fix is usually a
  structural change (lifting or lowering state), not a memo wrap.
- **Avoid inline object and array literals in props on hot
  paths** — list items, gesture handlers, animated views. Hoist
  or memoize.

## Animations and gestures

- **Animations use Reanimated 3 worklets** running on the UI
  thread. `Animated` from `react-native` is legacy; do not use it
  for new code.
- **Gesture recognition uses `react-native-gesture-handler`.**
  `PanResponder` is not used in new code.
- **No JS-thread animations for anything the user is touching.**
  If a gesture feels laggy, the fix is almost always a worklet,
  not a higher frame budget.

## Images

- **Images use `react-native-fast-image`** (or the project's
  declared image library), accessed through a wrapper in
  `src/common/components/` — no direct imports in feature code.
  Raw `<Image>` from `react-native` does not cache aggressively
  enough for list-heavy screens.
- **Remote images declare explicit width and height** so layout
  does not shift when they load.
- **Assets are sized for the device**, not the largest case.
  Shipping 4k PNGs to a phone is a bug.

## Startup

- **Do not do work at module top level** beyond cheap constant
  setup. Anything that touches storage, network, or native
  modules happens lazily or after first render.
- **Splash screen is hidden only after the first screen has
  data it can render.** A blank app is worse than a splash.

## Measuring

- **Claims about performance come with a measurement.** "Feels
  faster" is not evidence. Use Flipper, the Hermes profiler, or
  platform tooling and paste the numbers into the PR.
