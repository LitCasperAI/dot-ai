# Java / Spring Boot Build and Release

## Build tool

- **Maven** with the Maven Wrapper (`mvnw`). CI runs
  `./mvnw verify`. Local sandbox builds use `mci` / `mcci`.
- **Parent POM manages all dependency versions** via
  `<dependencyManagement>` and Spring Boot's BOM import.
  Child modules declare dependencies without versions.
- **Plugin versions are pinned** in `<pluginManagement>`. No
  floating plugin versions.

## CI pipeline

- **Build → test → static analysis → package → publish.**
  Checkstyle, SpotBugs, and JaCoCo run as part of the
  `verify` phase.
- **Docker image built with Jib** or a multi-stage Dockerfile.
  No `mvn package` + manual `docker build` in CI — the image
  build is part of the Maven lifecycle or a dedicated CI step.
- **Artifact published to Google Artifact Registry** (GAR).
  JFrog/Artifactory references are legacy and must not be
  introduced in new modules.

## Versioning

- **Semantic versioning.** MAJOR for breaking API changes,
  MINOR for new features, PATCH for fixes.
- **Version is set in the parent POM** and inherited by all
  modules. No per-module version overrides without an ADR.
- **Release branches follow `release/<major>.<minor>`.**
  Hotfixes branch from the release branch and merge back.

## Profiles

- **`local`** — developer machine. External services point to
  Testcontainers or local Docker Compose.
- **`test`** — CI. Same as local but headless, no interactive
  prompts.
- **`production`** — deployed. Config comes from environment
  variables, never from committed files.

