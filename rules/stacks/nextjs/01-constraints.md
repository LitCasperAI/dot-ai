# Next.js Constraints

Hard rules for Next.js code in this project. If a constraint
here conflicts with what you're about to write, stop and escalate —
don't route around it.

These are constraints, not suggestions. Every item in this file is
something that should trigger pushback in code review.

---

## Language and components

- **TypeScript only, strict mode on.** No `.js` or `.jsx` files
  in `src/` or `app/`. Every new file is `.ts` or `.tsx`.
  `strict: true` in `tsconfig.json` is a hard requirement, not
  aspirational.
- **Functional components only.** No class components. If you
  need lifecycle behaviour, use hooks or Server Component data
  fetching.
- **No `any` type.** Use `unknown` if the type is genuinely
  unknown and narrow it before use. If you're tempted to reach
  for `any`, that's a signal the types are modelled wrong — fix
  the model, not the escape hatch.
- **Props are typed explicitly.** `type Props = { ... }` above
  the component. No inferring props from usage.

## Runtime and architecture

- **App Router only.** This project does not use the Pages
  Router — no `pages/` directory, no `getServerSideProps`, no
  `getStaticProps`. Do not mix routers without an ADR.
- **Server Components are the default.** Add `"use client"` only
  when the component needs interactivity, state, effects, or
  browser-only APIs. A `"use client"` at the top of a leaf file
  is fine; a `"use client"` at the top of a layout is almost
  always wrong.
- **Node runtime is the default.** Use the Edge runtime
  (`export const runtime = "edge"`) only when the route's
  latency and payload justify it, and the dependencies support
  it. Do not flip runtimes to work around a bundle error.
- **React Server Components cannot import client-only code.**
  Keep the server/client split honest; if a module pulls in
  `window`, it does not belong in a server component.

## Routing and files

- **Route segments live under `app/`.** Every route has its own
  folder with `page.tsx`, optional `layout.tsx`, `loading.tsx`,
  `error.tsx`, and `route.ts` for handlers.
- **Route handlers (`route.ts`) are for JSON APIs and webhooks.**
  They are not a dumping ground for arbitrary server work — if
  the logic is page-bound, colocate it with the page as a Server
  Action or server component fetch.
- **Server Actions (`"use server"`) validate their inputs.**
  Treat a Server Action like a public API endpoint, because it
  is one. No trusting a client-sent shape.

## Data fetching

- **Fetch in Server Components by default.** `fetch()` in a
  server component is the simplest model; reach for SWR or
  React Query only when the data is client-interactive.
- **Cache explicitly.** Every `fetch()` declares its cache
  behaviour — `cache: 'force-cache'`, `cache: 'no-store'`, or
  `next: { revalidate: N, tags: [...] }`. Relying on Next.js
  defaults silently is a bug waiting to happen.
- **`revalidateTag` and `revalidatePath` are called from Server
  Actions or route handlers**, never sprinkled across components.
- **No direct database access from client components.** The
  database layer is reached through a server component, Server
  Action, or route handler.

## Styling

- **Tailwind CSS is the default styling system**, configured
  once in `tailwind.config.ts`. CSS Modules are acceptable for
  component-scoped CSS that does not fit a utility model.
- **No CSS-in-JS runtime libraries** (styled-components, emotion
  runtime) without explicit approval. They defeat RSC streaming
  and hurt TTFB.
- **Design tokens come from `src/core/theme/`** or
  `tailwind.config.ts`, not from literal values in components. A
  hex code in a component is a smell.

## State and data

- **Local UI state: `useState` or `useReducer`**, inside client
  components only.
- **Shared client state: Zustand.** One store per feature, kept
  small. Context is used for dependency injection (theme, user,
  feature flags), not for mutable state shared across the tree.
- **Server state that is interactive: TanStack Query** (SWR is
  acceptable if already established). Any data fetched from a
  Server Component does not need either.
- **URL is state.** Filter, pagination, and sort state belongs
  in the query string via `useSearchParams`, not in a client
  store that desyncs on refresh.

## Dependencies

- **No new runtime dependencies without explicit approval.** If
  you think a dependency is needed, stop and escalate to the
  architect.
- **Check bundle impact before adding a client-side dependency.**
  A 200 KB library that lands in every page load is an incident.
  Server-only dependencies (used inside server components or
  route handlers) have a much lower bar.
- **Before adding a dependency, check if it's already installed.**

## Async and errors

- **Async functions return typed promises.** `Promise<User>`,
  not `Promise<any>` or bare inference.
- **Every `error.tsx` is a real error boundary**, not a copy of
  the default. Log through the project's error service and
  offer a recovery action — at minimum a reset button.
- **`notFound()` and `redirect()` are used deliberately.** A
  404 thrown from deep in a data function changes the route's
  behaviour; treat it like a control-flow decision, not a
  convenience.

## Imports

- **Absolute imports via `tsconfig.json` paths aliases** —
  `@/core/…`, `@/features/…`, `@/common/…`. No deep relative
  paths like `../../../`.
- **Named exports only** for components, hooks, and utilities.
  The one exception is `page.tsx`, `layout.tsx`, `error.tsx`,
  `loading.tsx`, and `not-found.tsx`, which Next.js requires as
  default exports.
- **Feature boundaries are enforced.** Other features or global
  code import from a feature's `index.ts` barrel only, never
  from its internals. See `05-folder-structure.md`.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), accessibility (`04-accessibility.md`),
folder structure (`05-folder-structure.md`), routing
(`06-routing.md`), build/release (`07-build-and-release.md`),
and component-authoring conventions (`08-component-conventions.md`)
each live in their own file. Don't pile them into this one.
