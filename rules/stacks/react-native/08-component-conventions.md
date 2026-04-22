# React Native Component Conventions

How individual components are authored, split, and wrapped. This
file covers *within-component* structure; `05-folder-structure.md`
covers *between-component* organisation.

---

## Co-location pattern

Components that grow beyond a simple presentation layer are split
into co-located files within their own directory.

**Structure:**

```text
LoginForm/
├── LoginForm.tsx             # Main component logic and JSX
├── LoginForm.styles.ts       # StyleSheet.create
├── LoginForm.types.ts        # Props interface and local types
├── LoginForm.helpers.ts      # Pure functions extracted from the component
├── LoginForm.constants.ts    # Component-specific constants
├── LoginForm.test.tsx        # Unit / render tests
└── index.ts                  # Named re-export of the component
```

**When to split:**

- Split when the component file exceeds ~150 lines, or when
  types, helpers, or constants would otherwise clutter the main
  file.
- Do not pre-emptively create empty `.types.ts` or `.helpers.ts`
  files for components that do not need them. A three-line
  `.types.ts` is clutter.
- Simple, single-file components (a `Text` wrapper, a
  purely-presentational icon button) stay single-file.

## Sub-components

When a component file becomes too large, break it into smaller
focused sub-components.

- **Private sub-components** — only used by their parent — live
  in a `components/` directory colocated with the parent:

  ```text
  ParentComponent/
  ├── ParentComponent.tsx
  ├── ParentComponent.types.ts
  ├── ParentComponent.helpers.ts
  └── components/
      ├── index.ts           # Barrel for private sub-components
      ├── ChildOne/
      │   └── ChildOne.tsx
      └── ChildTwo/
          └── ChildTwo.tsx
  ```

- **Nesting depth**: at most **two levels** of nested
  `components/` below the original parent. Three levels deep is
  a signal the domain is too complex for one component tree —
  split it at the feature level instead.
- **Public sub-components** — reused by other components —
  graduate out of the private `components/` folder into the
  feature's `components/` directory, or into `common/components/`
  if truly generic.

## Exports

- **Named exports only.** Per `01-constraints.md`, no
  `export default` for components, hooks, stores, or utilities.
- **Each component folder has an `index.ts`** that re-exports
  the component by name: `export { LoginForm } from './LoginForm';`.
  Import sites import from the folder, not from the implementation
  file.

## Props and types

- **Props are defined in the component's `.types.ts`** (or inline
  at the top of the component file for simple components) as
  `type Props = { … }`. Exported consumer-facing types use
  descriptive names (`LoginFormProps`), not `Props`.
- **No prop destructuring with defaults inside nested children**
  of the same render — destructure once at the top of the
  component.

## The `Screen` wrapper

- **Every feature screen is wrapped with the `Screen` component
  from `@/common/components/Screen`.**
- `Screen` owns: `SafeAreaView`, `StatusBar`, the custom
  `ScreenHeader` (back navigation and title), `ScrollView`, and
  `KeyboardAvoidingView`. Feature code does not use these
  primitives directly.
- `isHeaderVisible={false}` is used for screens that do not need
  a header (login, tab root screens).
- Header actions on the right side are passed via the
  `headerRight` prop. Do not build a bespoke header inside a
  feature screen.
- If a screen needs something `Screen` does not yet support, the
  change goes into `Screen` (and its tests), not into a one-off
  workaround.

## Import ordering

Imports in every file are grouped and ordered as follows,
separated by a blank line:

1. React and React Native core imports.
2. Third-party library imports (`zustand`, `@tanstack/react-query`,
   etc.).
3. Absolute internal imports (`@/core/…`, `@/features/…`,
   `@/common/…`).
4. Relative local imports (`./styles`, `../utils`).

Within each group, imports are alphabetised. The linter enforces
this — do not hand-order against the configured rule.
