# Java / Quarkus Build and Release

How the application is built, packaged, and deployed.

---

## Build tool

- **Gradle** with the Gradle Wrapper (`gradlew`). CI runs `./gradlew build` or similar tasks.
- **Spotless Plugin** is used for formatting the codebase to adhere to the Google Java Format.
- **OpenAPI Generator** is often used via Gradle plugins to generate API stubs and models from `api-docs.yaml`.
- **Quarkus platform management.** Dependencies are managed using `enforcedPlatform` with `quarkus-bom` and other relevant BOMs. Do not specify versions for Quarkus extensions directly.
- **Plugin versions are pinned.** No floating plugin versions in `build.gradle`.

## CI pipeline

- **Build → test → static analysis → package → publish.**
- **Artifact published to artifact repository.** Docker images and Maven packages are pushed to your artifact repository as specified in the service manifests.
- **Deployment via manifest.** The service configuration, regions, scaling rules, and deployment specifications are managed in your service manifest. CI/CD pipelines use this to automate deployments to the appropriate environments.

## Configuration and Profiles

- **Configuration format:** `application.yaml` is commonly used instead of `.properties` (via `quarkus-config-yaml`).
- **Profiles:** Quarkus uses `%dev`, `%test`, and `%prod` profiles natively. 
  `application.yaml` can contain profile-specific sections.
- **Production config comes from environment variables.** 
  Use standard MicroProfile Config mapping (e.g., `QUARKUS_DATASOURCE_USERNAME`). 
  Never commit production secrets in configuration files.

## Versioning

- **Semantic versioning.** MAJOR for breaking API changes, MINOR for new features, PATCH for fixes.
- **Release branches follow `release/<major>.<minor>`.** Hotfixes branch from the release branch and merge back.