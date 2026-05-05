# Node.js Folder Structure

Feature-first organisation. Code is grouped by **domain**, not
by technical type. Extends the baseline rules in
`01-constraints.md`.

---

## Top-level layout

```text
src/
├── app.ts               # Framework app factory (registers plugins, routes)
├── server.ts            # Process entry: config, logger, app, listen, shutdown
├── core/                # Foundational infrastructure — the service does not run without this
│   ├── config/          # Env parsing + Zod validation
│   │   └── index.ts
│   ├── logger/          # Pino setup, redaction, context
│   │   └── index.ts
│   ├── db/              # Database client, schema, migrations
│   │   ├── client.ts
│   │   ├── schema/      # Drizzle schemas / Prisma schema fragments
│   │   └── migrations/
│   ├── api/             # Outbound HTTP clients (wrapped, timed, retried)
│   ├── auth/            # Token verification, session, RBAC primitives
│   ├── errors/          # Base error classes, HTTP mapping
│   └── utils/           # System-level utilities (ids.ts, time.ts)
├── features/            # Feature modules (users, billing, orders, …)
│   └── [feature]/
│       ├── routes.ts    # HTTP routes (thin, validate + call service)
│       ├── services/    # Feature business logic (pure where possible)
│       ├── repositories/# DB access for this feature
│       ├── schemas.ts   # Zod schemas for inputs and outputs
│       ├── types.ts     # Domain types (often derived from schemas)
│       ├── errors.ts    # Feature-specific domain errors
│       ├── workers/     # Queue consumers / background jobs (if any)
│       └── index.ts     # Public API for this feature (barrel)
└── common/              # Reusable code used across multiple features
    ├── middleware/      # Generic middleware (request id, auth, rate limit)
    ├── utils/           # Domain-agnostic helpers (formatDate.ts, slug.ts)
    └── test-utils/      # Shared test helpers, fixtures, Testcontainer setup

load/                    # k6 or project's load-test scripts
```

## `core/` vs `common/`

- **`core/`** is infrastructure: config, logger, database
  client, auth primitives, base error types, outbound HTTP
  clients. The service does not start without these. Changes
  here are reviewed carefully — they affect every feature.
- **`common/`** is generic reuse: middleware, utilities, test
  helpers. Anything in `common/` must be usable by any feature
  without carrying domain assumptions.

If you are about to add something to `common/` that references
a specific feature, it does not belong in `common/`.

## Feature encapsulation

- **Every folder in `src/features/` has an `index.ts` barrel.**
  The barrel is the feature's public surface — typically the
  route registrar, the domain types, and a small service API
  that other features may call.
- **Other features and global code import only from the
  barrel.** `import { registerBillingRoutes } from
'@/features/billing'` — yes. Deep imports — forbidden.
- **When code in `features/<x>/` is needed by a second feature,
  it graduates.** Move it to `common/` (utility), `core/`
  (infrastructure), or expose it through a service call from
  the owning feature. Do not cross-import between features'
  internals.

## Routes vs services vs repositories

- **`routes.ts`** registers HTTP routes. Each handler: validate
  with Zod → call a service → shape the response. No business
  logic here.
- **`services/`** contains business logic. Services are
  testable without a live framework; they take inputs, call
  repositories or other services, and return typed results.
- **`repositories/`** wraps database access. A repository
  method is a named domain operation (`findActiveByTenant`),
  not a thin pass-through to the ORM. If every repository
  method is a one-liner that re-exports the ORM, the
  repository is redundant — model at a higher level.
- **Outbound HTTP** goes through clients in `src/core/api/` or
  a feature-owned client in `features/<x>/services/`. No
  direct `fetch` from handlers or services bodies.

## Workers and queues

- **Queue consumers live in `features/<x>/workers/`** and are
  wired to the same service functions the HTTP layer uses. A
  worker and a route handler that do the same work must call
  the same service function, not duplicate logic.
- **Each worker has a declared queue, concurrency, and
  retry/backoff policy** in one place, typically
  `features/<x>/workers/index.ts`.

## Migrations

- **Migrations live in `src/core/db/migrations/`** and are
  named with a sortable timestamp prefix. They are
  forward-only; see `07-build-and-release.md`.
- **A migration PR is its own PR** unless the migration is
  small, additive, and inseparable from the feature (adding a
  nullable column consumed in the same release). Complex
  migrations are never bundled with feature work.

## Tests

- Colocated with the code under test, per `02-testing.md`. No
  parallel `__tests__/` tree.
- Shared test utilities (Testcontainer helpers, request
  builders, seed data) live in `src/common/test-utils/` and
  are not imported from production code.

## What does not live where

- **No route files outside `features/<x>/routes.ts`.** Every
  route belongs to a feature.
- **No direct DB access from route handlers.** Handlers call
  services, services call repositories.
- **No I/O in `common/utils/` or `core/utils/`.** Utilities are
  pure. Anything that touches network, database, or `fs`
  belongs in `core/api/`, `core/db/`, or a feature service.
- **No feature code in `common/` or `core/`.** If it is
  billing-only, it lives under `features/billing/`.
- **No cross-feature imports** into other features' internals.
  If `features/orders` needs something from `features/billing`,
  call it through the barrel or graduate the shared code.
