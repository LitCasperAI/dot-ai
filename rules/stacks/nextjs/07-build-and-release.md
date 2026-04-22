# Next.js Build and Release

How the app is built, deployed, and promoted. Stack-specific
expansion of `global/05-version-control.md` and
`global/07-dependencies.md`.

---

## Build system

- **Production builds are produced by CI**, not on developer
  machines. Local `next build` is for debugging.
- **CI lives in `.github/workflows/`** (or the project's
  declared CI tool). Build, test, and deploy pipelines are
  reviewed through the same PR process as application code.
- **`next build` must complete with zero TypeScript errors and
  zero ESLint errors.** `ignoreBuildErrors` and
  `ignoreDuringBuilds` are disabled — if CI fails, fix the
  code.

## Deployment

- **The declared host is the only deployment target.**
  Whichever platform the project uses (Vercel, AWS, self-hosted
  Node) is the supported target; experimental alternative
  adapters are an ADR, not a PR.
- **Preview deployments per PR are required.** Every PR gets a
  unique URL for manual QA; a PR without a live preview is not
  reviewable.
- **Promotion to production is a deliberate step**, not an
  auto-merge side effect. A merge to `main` builds and either
  auto-promotes or gates on approval — whichever the project
  has declared — but the path is explicit.

## Environment configuration

- **Environment variables are declared in `.env.example`.**
  Anything a developer needs to run the app has a placeholder
  there.
- **Real secrets never hit the repo.** Per
  `global/08-secrets-and-data.md`. Production secrets live in
  the host's secret store.
- **`NEXT_PUBLIC_` is public.** Any variable with that prefix
  ships in the client bundle; do not put secrets there. A
  common mistake is stamping an API key with `NEXT_PUBLIC_` to
  "just make it work" — that key is now public.
- **Server-only variables are asserted at boot.** A missing
  required env var crashes on startup, not on the first
  request.

## Versioning

- **App version is tracked in `package.json`** and bumped
  deliberately. Release tags match the `package.json` version.
- **Version bumps follow semver** for any shared library
  published from this repo. For an application, semver is
  advisory but still used for release notes.
- **A version bump is its own PR** when it's not part of a
  feature shipping; do not smuggle bumps into unrelated work.

## Release notes

- **Release notes are written before deploy**, committed with
  the version bump, and published to the project's declared
  channel.
- **Breaking changes are flagged prominently.** A silently
  breaking change is an incident.

## Feature flags

- **User-visible changes ship dark** behind a flag until
  validated. The project's declared flag system (LaunchDarkly,
  Unleash, or a built-in toggle) is the single source of truth.
- **Flag cleanup is part of the feature.** A flag that has
  been at 100% for two weeks is tech debt; remove it in the
  follow-up PR.

## Edge and Node builds

- **Mixing runtimes per route is allowed**, but each route
  declares its runtime explicitly. Implicit Edge via a
  dependency that assumes it is rejected.
- **Edge builds have hard limits** (bundle size, no Node
  APIs). If a handler is flirting with the limit, move it to
  Node and document why.

## Database migrations

- **Migrations live in `src/core/db/migrations/`** and run as
  a separate CI step before the app starts receiving traffic.
- **Forward-only migrations.** A down-migration is a
  last-resort escalation, not a default.
- **Schema changes that are not backwards-compatible** ship in
  two releases: first the additive change, then the removal
  once no old code is live.

## Crash and error reporting

- **Every production build ships with crash reporting wired**
  (Sentry, Datadog, or the project's declared provider). A
  build without it is not production.
- **Source maps are uploaded at build time**, automated
  through CI. A build whose maps did not upload is treated as
  a failed build.
- **Release identifiers in the error service match the Git
  SHA** so a reported stack trace maps to real code.
