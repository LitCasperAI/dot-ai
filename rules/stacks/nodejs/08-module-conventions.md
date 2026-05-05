# Node.js Module Conventions

How individual modules are authored, split, and composed. This
file covers _within-module_ structure; `05-folder-structure.md`
covers _between-module_ organisation.

---

## One concern per file

- **Each file has one reason to change.** A service module,
  a repository module, a schema module — separate files. A
  2,000-line `index.ts` with everything in it is rejected in
  review.
- **Split when a file exceeds ~300 lines** or when its
  exports cover two distinct responsibilities. Do not split
  pre-emptively into three-line files.

## Co-location pattern

Features group related files by domain, not by technical type:

```text
features/billing/
├── index.ts          # Barrel: the feature's public surface
├── routes.ts         # HTTP routes (thin)
├── schemas.ts        # Zod schemas for inputs and outputs
├── types.ts          # Domain types (often derived from schemas)
├── errors.ts         # Feature-specific domain errors
├── services/
│   ├── chargeCard.ts
│   ├── chargeCard.test.ts
│   ├── issueInvoice.ts
│   └── issueInvoice.test.ts
├── repositories/
│   ├── invoiceRepository.ts
│   └── invoiceRepository.test.ts
└── workers/
    └── retryFailedCharges.ts
```

- **A service function and its test live next to each other.**
  No parallel `__tests__/` tree, per `02-testing.md`.
- **Types derived from Zod schemas live in `types.ts`**; the
  schema lives in `schemas.ts`. Don't hand-write the type.

## Exports

- **Named exports only.** No `export default` for services,
  repositories, handlers, schemas, or utilities. Named exports
  give consistent import names and better refactor tooling.
- **Each feature's `index.ts` is the barrel**, and it exports
  the feature's public API:
  - The route registrar (`registerBillingRoutes`).
  - Service functions callable by other features (only those
    intended for cross-feature use).
  - Public domain types.
  - Public domain errors.
    Internals (repositories, private helpers) are not re-exported.
- **`export *` from a barrel is rejected.** Be explicit about
  what the feature exposes.

## Imports

- **Absolute imports via `tsconfig.json` paths aliases** —
  `@/core/…`, `@/features/…`, `@/common/…`. No deep relative
  paths like `../../../`.
- **Relative imports are for within-module references only.**
  `import { formatAmount } from './helpers'` inside
  `features/billing/services/` — yes. Reaching across
  features with `../../../features/...` — rejected; use the
  barrel or absolute path.
- **Feature boundaries are enforced.** Other features or
  global code import from a feature's `index.ts` barrel only.

## Import ordering

Imports in every file are grouped and ordered as follows,
separated by a blank line:

1. Node built-ins (`node:crypto`, `node:fs/promises`).
2. Third-party library imports (`zod`, `fastify`, `drizzle-orm`).
3. Absolute internal imports (`@/core/…`, `@/features/…`,
   `@/common/…`).
4. Relative local imports (`./helpers`, `../types`).

Within each group, imports are alphabetised. The linter
enforces this — do not hand-order against the configured rule.

## Service functions

- **A service function takes typed inputs and returns a typed
  result.** Its signature is the contract.
- **Dependencies are passed in, not imported.** A service
  function that imports the database client directly cannot
  be tested without a live DB; take the client as an argument
  (or resolve it from a small composition root).
- **Pure where practical.** A function that computes a value
  from its inputs is trivially testable; push side effects to
  the edges.
- **No service function returns `any` or `unknown` without a
  narrowing step at the call site.** Shape the contract at
  the service, not at every caller.

## Repositories

- **Repository methods are named domain operations**, not
  thin pass-throughs. `findActiveByTenant(tenantId)` — yes;
  `query(sql)` — no.
- **A repository owns its table(s).** Two repositories writing
  to the same table without coordination is a recipe for
  schema drift.
- **Transactions cross repositories through a unit-of-work
  primitive** (the ORM's transaction API), not by smuggling a
  shared client through module scope.

## Schemas and types

- **Zod schemas are the source of truth.** TypeScript types
  derive from them via `z.infer<typeof Schema>`.
- **One schema per wire shape.** Request body, response body,
  event payload — each named and exported.
- **Internal domain types can diverge from wire types.** The
  wire type is what goes over the network; the domain type is
  what the service reasons about. Map between them explicitly.

## Errors

- **Domain errors for a feature live in
  `features/<x>/errors.ts`.** Cross-cutting base classes
  (`AppError`, `NotFoundError`, `ValidationError`) live in
  `src/core/errors/`.
- **Every domain error declares a stable `code`**; see
  `06-error-handling.md`.

## Configuration

- **No `process.env` reads outside `src/core/config/`.** The
  config module parses and validates once at boot and exports a
  typed object; the rest of the code reads from that object.
- **Feature-specific config lives in the feature.** A billing
  retry window is declared in `features/billing/`, not bolted
  onto the global config.

## Logging inside modules

- **Each module gets a child logger with a module name.**
  `const log = logger.child({ module: 'billing.chargeCard' })`.
  Log lines are attributable without grepping call sites.
- **Log the start and end of cross-boundary operations**
  (outbound HTTP, DB transactions). Don't log every function
  call — that's noise, not signal.
