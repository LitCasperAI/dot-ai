# Java / Spring Boot Constraints

Hard rules for Java and Spring Boot code in this project. If a
constraint here conflicts with what you're about to write, stop
and escalate — don't route around it.

These are constraints, not suggestions. Every item in this file
is something that should trigger pushback in code review.

---

## Language and runtime

- **Java 21 LTS minimum** unless `project.yaml` specifies 25.
  Do not use preview features without an ADR.
- **Spring Boot 3.x only.** No mixing of Spring Boot 2 and 3
  modules within the same service. Migration from 2 to 3 is a
  dedicated effort, not a drive-by change.
- **No Lombok in new code.** Use Java records for DTOs and value
  objects. Existing Lombok usage is tolerated but not extended.
  If you need a builder, write a static factory method or use
  the record canonical constructor.
- **Records for DTOs and value types.** Mutable POJOs are
  rejected for request/response models, events, and config
  objects.
- **`var` is encouraged** for local variables when the type is
  obvious from the right-hand side. Do not use `var` when the
  type is ambiguous.

## Project structure

- **Multi-module Maven project.** Each module has a single
  responsibility. A module that grows beyond its charter gets
  split, not padded.
- **Feature-first packaging within a module.**
  `com.<org>.<service>.feature.<name>` — controller, service,
  repository, model, and DTOs live together. No layered
  packaging (`controller/`, `service/`, `repository/`) at the
  top level.
- **No circular module dependencies.** If module A depends on B,
  B must not depend on A — not even transitively. The build
  enforces this.

## Dependency injection

- **Constructor injection only.** No `@Autowired` on fields or
  setters. All dependencies are `final` fields assigned in the
  constructor.
- **`@Component` / `@Service` / `@Repository` stereotype
  annotations** — one per class, matching its role. Do not use
  `@Component` as a catch-all.
- **No `@Value` for injecting config into business classes.**
  Create a `@ConfigurationProperties` record and inject that.

## REST API design

- **`@RestController` with explicit `@RequestMapping`** at the
  class level. Method-level mappings use `@GetMapping`,
  `@PostMapping`, etc.
- **Request and response bodies are records**, validated with
  `@Valid` + Jakarta Bean Validation annotations. No raw `Map`
  or `JsonNode` in public APIs.
- **Consistent error responses.** Use a global
  `@RestControllerAdvice` that maps exceptions to RFC 7807
  Problem Detail responses. No handler-level `try/catch` that
  returns ad-hoc error shapes.
- **API versioning via URL path prefix** (`/api/v1/…`). No
  header-based versioning without an ADR.

## Data access

- **Spring Data JPA for relational data.** Repository interfaces
  extend `JpaRepository` or `JpaSpecificationExecutor`. Custom
  queries use `@Query` with JPQL or native SQL — named queries
  are discouraged.
- **Flyway for schema migrations.** Every schema change is a
  versioned migration script under `db/migration/`. No Hibernate
  `ddl-auto` in production profiles.
- **Transactions are explicit.** `@Transactional` on the service
  method that defines the unit of work. Read-only operations use
  `@Transactional(readOnly = true)`.
- **No `EntityManager` injection in service classes** unless
  there is a documented reason. Repositories own persistence
  logic.

## Testing

- **JUnit 5 + Mockito** for unit tests. No JUnit 4 imports in
  new test files.
- **`@SpringBootTest` only for integration tests** that need the
  full context. Prefer `@WebMvcTest`, `@DataJpaTest`, or
  `@ServiceTest` slices to keep tests fast.
- **Testcontainers for integration tests** against databases,
  message brokers, or external services. No in-memory H2 as a
  stand-in for PostgreSQL.
- **Test naming: `should_<expected>_when_<condition>`.** The name
  is a sentence that describes the behaviour under test.

## Observability

- **SLF4J + Logback.** No `System.out.println` or direct Log4j
  usage. Logger is a `private static final` field obtained via
  `LoggerFactory.getLogger(ClassName.class)`.
- **Structured logging with MDC.** Correlation ID, user context,
  and request metadata go into MDC at the filter level and
  propagate through the call chain.
- **Micrometer for metrics.** Custom metrics use the Micrometer
  API, not raw Prometheus client. Spring Boot Actuator endpoints
  are enabled and secured.
- **Health checks in Actuator.** Every external dependency
  (database, message broker, downstream service) has a health
  indicator.

## Security

- **Spring Security is configured, not disabled.** No
  `@SpringBootApplication(exclude = SecurityAutoConfiguration)`
  or blanket `permitAll()` without an ADR.
- **Secrets come from environment variables or a secret
  manager.** No secrets in `application.yml`, not even for
  `local` profile. Use `${ENV_VAR}` placeholders.
- **Input is sanitized.** SQL injection is prevented by
  parameterized queries (JPA handles this). XSS is prevented by
  not reflecting unsanitized input.

## Build

- **Maven wrapper (`mvnw`) is committed.** CI and local builds
  use `./mvnw`, not a globally installed `mvn`.
- **In the sandbox, use `mci` / `mcci`** — never raw `mvn` or
  `mvnd` on bind-mounted repos. See `GEMINI.md` /
  `CLAUDE.md` for details.
- **Checkstyle and SpotBugs run on every build.** Violations
  fail the build. Do not suppress without a comment explaining
  why.
- **Dependency versions are managed in the parent POM** via
  `<dependencyManagement>`. No version declarations in child
  module POMs unless overriding with justification.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance
(`03-performance.md`), API design (`04-api-design.md`), folder
structure (`05-folder-structure.md`), error handling
(`06-error-handling.md`), build/release (`07-build-and-release.md`),
and module conventions (`08-module-conventions.md`) each live in
their own file. Don't pile them into this one.

