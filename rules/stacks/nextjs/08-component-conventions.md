# Next.js Component Conventions

How individual components are authored, split, and composed
across the server/client boundary. This file covers
_within-component_ structure; `05-folder-structure.md` covers
_between-component_ organisation.

---

## Server vs client

- **Default to Server Components.** Add `"use client"` only
  when the component needs state, effects, refs, event
  handlers, or browser-only APIs.
- **Push the client boundary as far down the tree as
  possible.** A client-only toggle does not need its parent
  layout to be a client component.
- **Server Components can render Client Components.** The
  reverse requires passing the server tree as `children` —
  don't try to import a Server Component from a Client
  Component.

## Co-location pattern

Components that grow beyond a simple presentation layer are
split into co-located files within their own directory.

**Structure:**

```text
LoginForm/
├── LoginForm.tsx             # Main component logic and JSX
├── LoginForm.module.css      # CSS Module (if not using Tailwind for this one)
├── LoginForm.types.ts        # Props interface and local types
├── LoginForm.helpers.ts      # Pure functions extracted from the component
├── LoginForm.constants.ts    # Component-specific constants
├── LoginForm.test.tsx        # Unit / render tests
└── index.ts                  # Named re-export of the component
```

**When to split:**

- Split when the component file exceeds ~150 lines, or when
  types, helpers, or constants would otherwise clutter the
  main file.
- Do not pre-emptively create empty `.types.ts` or
  `.helpers.ts` files for components that do not need them. A
  three-line `.types.ts` is clutter.
- Simple, single-file components (a typography wrapper, a
  purely-presentational icon button) stay single-file.

## Sub-components

When a component file becomes too large, break it into smaller
focused sub-components.

- **Private sub-components** — only used by their parent —
  live in a `components/` directory colocated with the parent:

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

- **Named exports only** for components, hooks, stores, and
  utilities. The exceptions are Next.js framework files
  (`page.tsx`, `layout.tsx`, `error.tsx`, `loading.tsx`,
  `not-found.tsx`, `route.ts`), which require specific default
  or named exports — follow the framework, not the convention.
- **Each component folder has an `index.ts`** that re-exports
  the component by name:
  `export { LoginForm } from './LoginForm';`. Import sites
  import from the folder, not from the implementation file.

## Props and types

- **Props are defined in the component's `.types.ts`** (or
  inline at the top of the component file for simple
  components) as `type Props = { … }`. Exported consumer-facing
  types use descriptive names (`LoginFormProps`), not `Props`.
- **No prop destructuring with defaults inside nested children**
  of the same render — destructure once at the top of the
  component.
- **Server component props must be serialisable.** If the prop
  is a function, it has to be a Server Action; if it's a class
  instance, it cannot cross. A non-serialisable prop at the
  boundary is a type error waiting to happen at runtime.

## Data fetching inside components

- **Server Components fetch directly** with `await fetch(...)`
  or an `await db.query(...)`. No `useEffect` + `useState`
  dance — that is a Client Component pattern.
- **Client Components do not fetch in `useEffect` when a Server
  Component could do it.** If you find yourself fetching initial
  data in `useEffect`, rethink the boundary.
- **Parallel fetches use `Promise.all`.** Sequential `await`s
  for independent data are a performance bug.

## The `PageShell` wrapper

- **Authenticated app pages are wrapped with `PageShell`** from
  `@/common/components/PageShell` (the project's equivalent
  name), which owns the common header, breadcrumbs, and
  content container.
- `PageShell` is a Server Component. Do not reach for it from
  a client component; wrap your client pieces as children
  instead.
- If a page needs something `PageShell` does not yet support,
  the change goes into `PageShell` (and its tests), not into a
  one-off workaround.

## Import ordering

Imports in every file are grouped and ordered as follows,
separated by a blank line:

1. React and Next.js core imports (`react`, `next/link`,
   `next/navigation`, `next/image`).
2. Third-party library imports (`zustand`, `zod`,
   `@tanstack/react-query`, etc.).
3. Absolute internal imports (`@/core/…`, `@/features/…`,
   `@/common/…`).
4. Relative local imports (`./styles`, `../utils`).

Within each group, imports are alphabetised. The linter
enforces this — do not hand-order against the configured rule.
