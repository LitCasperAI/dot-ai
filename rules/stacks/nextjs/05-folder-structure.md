# Next.js Folder Structure

Feature-first organisation with the App Router at the edge.
Code is grouped by **domain**, not by technical type. Extends
the baseline rules in `01-constraints.md`.

---

## Top-level layout

```text
app/                     # App Router — thin route shells only
├── layout.tsx           # Root layout (providers, fonts, metadata)
├── page.tsx             # Landing page
├── (marketing)/         # Route group for public pages
│   └── pricing/page.tsx
├── (app)/               # Route group for authenticated app
│   ├── layout.tsx       # Auth guard layout
│   ├── dashboard/page.tsx
│   └── billing/page.tsx
├── api/                 # Route handlers (route.ts)
│   └── webhooks/stripe/route.ts
├── error.tsx            # Root error boundary
├── not-found.tsx        # 404
└── loading.tsx          # Root streaming fallback

src/
├── core/                # Foundational infrastructure
│   ├── theme/           # Design tokens beyond Tailwind
│   ├── api/             # Base HTTP client, server fetchers
│   ├── db/              # Database client, schema, migrations
│   ├── auth/            # Auth primitives (session, RBAC)
│   └── utils/           # logger.ts, errorHandler.ts
├── features/            # Feature modules (auth, billing, dashboard, …)
│   └── [feature]/
│       ├── components/  # Feature-specific UI (server + client)
│       ├── hooks/       # Feature-specific client hooks
│       ├── services/    # Feature-specific server-side logic
│       ├── actions.ts   # Server Actions for this feature
│       ├── schemas.ts   # Zod schemas (inputs/outputs)
│       ├── store/       # Feature-specific Zustand store (if any)
│       └── index.ts     # Public API for this feature (barrel)
└── common/              # Reusable code used across multiple features
    ├── components/      # Generic UI (Button, Card, Dialog)
    ├── hooks/           # Generic client hooks
    └── utils/           # Domain-agnostic helpers (formatDate.ts)

e2e/                     # Playwright specs
```

## `app/` is thin

- **Route files (`page.tsx`, `layout.tsx`) contain only the
  route shell.** Data-fetching logic, UI composition, and
  business logic live under `src/features/`.
- A `page.tsx` that is 300 lines of JSX is a signal the feature
  has no module — extract to `src/features/<x>/` and import a
  component.
- `app/api/.../route.ts` dispatches to a service in
  `src/features/<x>/services/` — the handler is a thin adapter,
  not the logic itself.

## `core/` vs `common/`

- **`core/`** is infrastructure: theming, base API client,
  database client, auth, logging, error handling. The app does
  not start without these. Changes here are reviewed carefully.
- **`common/`** is generic reuse: domain-agnostic components,
  hooks, and utilities. Anything in `common/` must be usable by
  any feature without carrying domain assumptions.

If you are about to add something to `common/` that references
a specific feature, it does not belong in `common/`.

## Feature encapsulation

- **Every folder in `src/features/` has an `index.ts` barrel.**
  The barrel is the feature's public surface.
- **Other features and global code import only from the
  barrel.** `import { BillingPanel } from '@/features/billing'`
  — yes. Deep imports — forbidden.
- **When code in `features/<x>/` is needed by a second feature,
  it graduates.** Move it to `common/` (UI/hook/util) or
  `core/` (infrastructure). Do not cross-import between
  features.

## Server / client split

- **Server-only modules declare it.** Import
  `'server-only'` at the top of modules that must not cross to
  the client (database clients, secret-using services).
- **Client-only modules declare it.** Import
  `'client-only'` at the top of modules that must not cross to
  the server (`window`-touching utilities).
- **Server Actions live in `actions.ts`** at the feature root
  with `"use server"` at the top. Do not colocate Server
  Actions with client components in the same file.

## Route groups and parallel routes

- **Use route groups `(name)/`** to share layouts (auth shell,
  marketing shell) without affecting URLs.
- **Parallel routes `@slot`** are acceptable for genuine
  parallel UI (modals, dashboards with independent panes).
  They are not a workaround for poor component composition.

## Tests

- Colocated with the code under test, per `02-testing.md`. No
  parallel `__tests__/` tree.
- Shared test utilities (render helpers, fixtures) live in
  `src/common/test-utils/` and are not imported from production
  code.

## What does not live where

- **No page-level components in `common/components/`.** A
  component that owns a full page is a page, and pages belong
  under a route in `app/` and a feature in `src/features/`.
- **No I/O in `common/utils/` or `core/utils/`.** Utilities are
  pure. Anything that touches network, database, or `fs`
  belongs in `core/` or a feature service.
- **No feature code in `common/` or `core/`.** If it is
  billing-only, it lives under `features/billing/`.
- **No cross-feature imports.** If `features/checkout` needs
  something from `features/billing`, that something graduates
  to `common/` or `core/` first.
