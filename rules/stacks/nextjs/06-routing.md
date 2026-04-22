# Next.js Routing

How routes, layouts, and data flow are wired in the App Router.

---

## One router

- **App Router only.** No `pages/` directory, no
  `getServerSideProps`, no `getStaticProps`. See
  `01-constraints.md`.
- **Every route is a folder under `app/`** with at least a
  `page.tsx`. Route handlers use `route.ts` in the same folder
  shape but do not export a default React component.

## Segments and params

- **Dynamic segments use `[param]`** folders and receive their
  values via the `params` prop (a `Promise` in Next 15+).
  Always `await` `params` and `searchParams` at the top of the
  component.
- **Param types are declared.** No `params: any`. Use a `type`
  alias per page: `type Params = { id: string }`.
- **Catch-all routes (`[...slug]`) are used sparingly.** They
  are the right tool for docs or CMS-backed pages; they are the
  wrong tool for a route you could have enumerated.

## Layouts

- **Layouts wrap, they do not fetch for children.** Shared
  chrome (nav, sidebar) lives in a layout; per-route data
  lives in the page.
- **Route groups `(name)/` share layouts** without affecting
  URLs. Use them for auth shell vs marketing shell vs admin
  shell.
- **A layout that `"use client"`s the whole subtree is a code
  smell.** Push the client boundary down to the leaf that
  actually needs interactivity.

## Navigation

- **Use `next/link` for internal navigation.** `<a href>` for
  internal routes is rejected — it forces a full reload.
- **Programmatic navigation uses `useRouter` from
  `next/navigation`**, not `next/router` (which is Pages
  Router).
- **`router.refresh()` is the mechanism to re-fetch server
  data** after a mutation in a client component. Prefer a
  Server Action with `revalidateTag` when the mutation is
  server-originated.

## Search params and state

- **`useSearchParams` is read-only** and returns a
  `URLSearchParams`. To update, build a new URL and use
  `router.push` or `router.replace`.
- **URL is state for filters, pagination, and sort.** A
  dashboard's state that survives refresh lives in the query
  string, not a client store.
- **Validate search params.** A URL is user input; parse with
  Zod before trusting a value.

## Route handlers

- **`route.ts` exports one function per HTTP verb**
  (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`). No single handler
  that switches on `request.method`.
- **Handlers validate request bodies with Zod** before doing
  anything with them. Return 400 with a structured error
  payload on parse failure — see
  `global/09-observability-and-errors.md`.
- **Handlers set explicit cache headers** where relevant. A
  handler that should never be cached declares
  `export const dynamic = 'force-dynamic'`.

## Server Actions

- **Server Actions live in `actions.ts`** at the feature root
  with `"use server"` at the top.
- **Every Server Action validates its input with Zod.** Even
  a single-string input. The client is hostile by default.
- **Every Server Action returns a discriminated result**
  (`{ ok: true, data } | { ok: false, error }`) or throws a
  known error type. Bare rejections become opaque to the
  client.
- **Server Actions invoke `revalidateTag` / `revalidatePath`**
  when they mutate data the UI displays. A successful mutation
  followed by stale UI is a bug.

## Middleware

- **Middleware (`middleware.ts`) is thin.** Auth redirects,
  geo rewrites, request ID stamping — yes. Business logic — no.
- **Matchers are explicit.** An unconstrained middleware runs
  on every request including static assets and costs latency.
- **Edge runtime constraints apply.** No Node-only APIs in
  middleware; the Edge runtime is non-negotiable here.

## Metadata and SEO

- **Metadata is declared**, either statically via the
  `metadata` export or dynamically via `generateMetadata`. Do
  not use `next/head`.
- **Per-route metadata overrides the root.** Define a sensible
  root default in `app/layout.tsx` and override only what each
  route needs.
- **Canonical URLs and OpenGraph tags are set for every
  public-facing route.**

## Redirects and not-found

- **`redirect()` from `next/navigation` is the canonical
  redirect.** It throws; code after it does not run. Treat it
  as control flow.
- **`notFound()` renders the nearest `not-found.tsx`.** Use it
  when a resource does not exist; do not render an inline "not
  found" div.
