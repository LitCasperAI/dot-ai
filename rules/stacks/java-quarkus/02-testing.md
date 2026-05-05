# Java / Quarkus Testing Conventions

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Unit tests

- One test class per production class, same package, `*Test` suffix.
- Mockito for collaborators. Use `@ExtendWith(MockitoExtension.class)`.
- Arrange / Act / Assert structure with blank lines between sections.
- Assertions use AssertJ (`assertThat(…)`) — not JUnit's `assertEquals`. 
  AssertJ gives better failure messages and fluent chaining.

## Integration tests

- Suffix: `*IT` or `*Test` depending on Gradle test task configuration, 
  but follow project norms.
- **`@QuarkusTest`** for tests that need the full CDI container and HTTP routing.
- **`@QuarkusIntegrationTest`** for testing the packaged application 
  (e.g., the built native executable or JVM runner).
- **RestAssured** for testing HTTP endpoints. Inject it or use the static methods.
- **Dev Services / Testcontainers** for databases and brokers. Quarkus automatically 
  spins up Dev Services for databases if no URL is provided. Rely on this or explicit 
  Testcontainers if custom setup is needed.
- Wipe test data between tests. Use `@TestTransaction` to automatically rollback 
  changes in tests, or run explicit cleanup scripts.

## Mocks in Integration Tests

- Use **`@InjectMock`** to replace a CDI bean with a Mockito mock inside a `@QuarkusTest`.
- Use **`@QuarkusTestResource`** for spinning up external dependencies that aren't 
  handled by Dev Services (e.g. WireMock).

## Test naming

Unit tests follow: `<methodUnderTest>_<expectedBehavior>_when_<condition>`

Examples:
- `validatePath_throwsUnauthenticated_whenTokenHasNoTenantId`
- `processOrder_persistsOrder_whenPaymentSucceeds`

Integration tests can use broader behavioral names that describe the flow being tested (e.g., `testPutAndGetLink_success_withValidDto`).

## Coverage

- Coverage gate is set in `build.gradle` (JaCoCo). New code must not lower the coverage percentage.
- 100% coverage is not a goal. Cover behaviour, not getters/setters.

## Test data

- Use builder/factory methods for test fixtures, not raw constructors with 15 parameters.
- No production data in tests — not even anonymised. Generate synthetic data.