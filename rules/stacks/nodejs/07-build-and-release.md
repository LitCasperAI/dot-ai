# Node.js Build and Release

How the service is built, containerised, and deployed.
Stack-specific expansion of `global/05-version-control.md` and
`global/07-dependencies.md`.

---

## Build system

- **Production builds are produced by CI**, not on developer
  machines. Local builds are for debugging.
- **CI lives in `.github/workflows/`** (or the project's
  declared CI tool). Build, test, and deploy pipelines are
  reviewed through the same PR process as application code.
- **Build is reproducible.** A given Git SHA produces the
  same image byte-for-byte modulo the base image digest,
  which is pinned. "It built yesterday" is not a strategy.
- **`tsc --noEmit` runs in CI.** The project ships transpiled
  output (via `tsc`, `tsup`, or the declared bundler) but
  the type-check is a separate, mandatory step.

## Containerisation

- **One service per image.** A sidecar belongs in its own
  container.
- **Images are built from a pinned base** (digest, not tag).
  `FROM node:lts` is rejected; `FROM node:20.18.1-slim@sha256:...`
  is correct.
- **Images run as a non-root user.** A Dockerfile that leaves
  `USER root` is rejected.
- **Only production dependencies ship in the final image.**
  Multi-stage build: build stage has `devDependencies`,
  runtime stage has `node_modules --production` (or the
  bundled output).
- **Images are scanned.** Trivy (or the project's declared
  scanner) runs in CI and blocks on high-severity findings.

## Environment configuration

- **Config comes from env vars**, loaded and validated once at
  startup in `src/core/config/`. A missing required variable
  crashes on boot.
- **`.env.example` lists every variable a developer needs.**
  Production secrets live in the host's secret store, never in
  the repo.
- **No defaults in code for secrets.** A default database URL
  pointing at `localhost` is fine for dev; a default API key
  is a vulnerability.

## Versioning

- **Service version is tracked in `package.json`.** Release
  tags match the `package.json` version.
- **Version bumps follow semver** for any shared library
  published from this repo. For a service, semver is advisory
  but still used for release notes.
- **A version bump is its own PR** when it's not part of a
  feature shipping; do not smuggle bumps into unrelated work.

## Deployment

- **The declared host is the only deployment target.** Changes
  to another platform are an ADR, not a PR.
- **Deployments are progressive.** Canary or blue/green, with
  automated rollback on health-check or error-rate regression.
  A full-fleet deploy on merge to `main` is rejected.
- **Health checks are real.** `/healthz` verifies DB
  connectivity and the service's own invariants; a 200 that
  only proves the HTTP server is up is a false signal.
- **Readiness is distinct from liveness.** Readiness fails
  while the service is warming up or draining; liveness fails
  only when the process is wedged.

## Database migrations

- **Migrations run as a separate CI step** before the new
  version starts receiving traffic.
- **Forward-only migrations.** A down-migration is a
  last-resort escalation, not a default.
- **Schema changes that are not backwards-compatible** ship in
  two releases: first the additive change, then the removal
  once no old code is live. A "deploy the app, then run the
  migration that drops the column the old app still reads"
  sequence causes an outage.

## Release notes

- **Release notes are written before deploy**, committed with
  the version bump, and published to the project's declared
  channel (CHANGELOG, internal doc, release email — pick one
  and hold to it).
- **Breaking changes are flagged prominently.** A silently
  breaking API change is an incident.

## Feature flags

- **Risky changes ship dark** behind a flag until validated.
  The project's declared flag system (LaunchDarkly, Unleash,
  or a built-in toggle) is the single source of truth.
- **Flag cleanup is part of the feature.** A flag that has
  been at 100% for two weeks is tech debt; remove it in the
  follow-up PR.

## Observability

- **Every production build ships with tracing, metrics, and
  structured logs wired** (OpenTelemetry + the project's
  declared backend). A build without them is not production.
- **Release identifiers match the Git SHA** so a reported
  error maps to real code.
- **Dashboards exist before launch.** A service without a
  latency, error-rate, and saturation dashboard is not
  operable.

## Rollback

- **Rollback is a one-command path**, rehearsed. The last
  N production images are kept and redeployable.
- **A rollback is not "just redeploy the old version"** if
  the new version ran a non-reversible migration. Migrations
  are designed so the previous version keeps working.
