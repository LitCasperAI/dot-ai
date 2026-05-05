# Java / Quarkus Constraints

Hard rules for Java and Quarkus code in this project. If a
constraint here conflicts with what you're about to write, stop
and escalate — don't route around it.

These are constraints, not suggestions. Every item in this file
is something that should trigger pushback in code review.

---

## Language and runtime

- **Java 21 LTS minimum** unless `project.yaml` specifies 25.
  Do not use preview features without an ADR.
- **Quarkus 3.x only.** No legacy Quarkus 2.x modules within the same service.
  Migration from 2 to 3 is a dedicated effort, not a drive-by change.
- **Java 21+ features preferred, but Lombok is allowed.** Use Java records for simple internal DTOs and value objects. However, Lombok is permitted where it significantly reduces boilerplate (e.g., `@RequiredArgsConstructor` for constructor injection or `@Slf4j` for logging).
- **Generated DTOs.** We use Protobuf (`.proto`) and OpenAPI (`api-docs.yaml`) definitions as the source of truth, heavily relying on the generated classes (builders/POJOs). When hand-rolling internal DTOs, Java Records are preferred.
- **`var` is encouraged** for local variables when the type is obvious from the right-hand side. Do not use `var` when the type is ambiguous.

## Project structure

- **Feature-first packaging.**
  `com.company.<service>.feature.<name>` — resource/controller, service,
  repository, model, and DTOs live together. Layered technical packaging (e.g., `grpc/`, `service/`, `spanner/`) is acceptable only in older or specialized projects.
- **No circular dependencies.** The build and framework enforce this,
  but ensure architectural boundaries remain clean.

## Dependency injection

- **Constructor injection.** 
  Constructor injection is the standard for mandatory dependencies. This is often achieved by marking fields as `private final` and annotating the class with Lombok's `@RequiredArgsConstructor`.
- **`@ApplicationScoped` / `@Singleton` / `@RequestScoped`** — use 
  standard CDI/Jakarta annotations. Do not use Spring `@Service` or `@Component` 
  annotations even via the Spring compatibility extension unless migrating.

## REST API design

- **Jakarta REST (JAX-RS) with RESTEasy Reactive.** Use `@Path`, `@GET`, `@POST`.
- **Request and response bodies are generated**, and validated with
  `@Valid` + Jakarta Bean Validation annotations. No raw `Map`
  or `JsonNode` in public APIs.
- **Consistent error responses.** Use `ExceptionMapper` to map exceptions 
  to RFC 7807 Problem Detail responses. No handler-level `try/catch` that
  returns ad-hoc error shapes.
- **API versioning via URL path prefix** (`/api/v1/…`). No
  header-based versioning without an ADR.

## Data access

- **Hibernate ORM with Panache.** Use the Repository pattern (`PanacheRepository`) 
  or Active Record pattern (`PanacheEntity`) for relational databases. Pick one pattern per project and stick to it.
- **NoSQL / Specialized Databases.** For specialized or NoSQL databases (e.g., GCP Spanner, Bigtable), use the direct client (e.g., `DatabaseClient`) and explicit manual transactions.
- **Transactions are explicit.** `@Transactional` on the service method that defines the unit of work for relational DBs. Use manual transactions (`readWriteTransaction`) for Spanner.

## Testing

- **JUnit 5 + Mockito.** No JUnit 4 imports in new test files.
- **`@QuarkusTest` for integration tests.** This boots the Quarkus context.
- **Quarkus Dev Services / Testcontainers** for databases and brokers. 
  Quarkus automatically starts containers if configured correctly.
- **Test naming: `should_<expected>_when_<condition>`.** The name
  is a sentence that describes the behaviour under test.

## Observability

- **Lombok `@Slf4j` or JBoss Logging.** Logger is automatically injected via Lombok or defined as a `private static final` field.
- **Structured logging with MDC.** Correlation ID, user context,
  and request metadata go into MDC at the filter level.
- **Micrometer for metrics.** Use the Micrometer extension.
- **SmallRye Health.** Enable liveness and readiness probes.

## Security

- **Quarkus Security is configured, not disabled.**
- **Secrets come from GCP Secret Manager.** Use the Quarkus Google Cloud Secret Manager extension and reference secrets in `application.yaml` using the `${sm//<secret-name>}` syntax (e.g., `${sm//auth0-${quarkus.oidc-client.client-id}}`). Never commit secrets in configuration files or fall back to plain environment variables for sensitive credentials if Secret Manager is available.

## Build

- **Gradle wrapper (`gradlew`) is committed.** CI and local builds
  use `./gradlew`, not a globally installed `gradle`.
- **Dependency versions are managed via Quarkus BOM.**
  `enforcedPlatform` imports `quarkus-bom` and `quarkus-google-cloud-services-bom`.
- **Spotless formatting.** The codebase is strictly formatted using the Spotless Gradle plugin with the Google Java Format.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), API design (`04-api-design.md`), folder
structure (`05-folder-structure.md`), error handling
(`06-error-handling.md`), and build/release (`07-build-and-release.md`) 
each live in their own file. Don't pile them into this one.