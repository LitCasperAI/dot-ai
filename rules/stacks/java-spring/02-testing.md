# Java / Spring Boot Testing Conventions

## Unit tests

- One test class per production class, same package, `*Test`
  suffix.
- Mockito for collaborators. Use `@ExtendWith(MockitoExtension.class)`,
  not `@RunWith(MockitoJUnitRunner.class)` (JUnit 4).
- Arrange / Act / Assert structure with blank lines between
  sections.
- No test should depend on execution order. Each test sets up
  its own state.
- Assertions use AssertJ (`assertThat(…)`) — not JUnit's
  `assertEquals`. AssertJ gives better failure messages and
  fluent chaining.

## Integration tests

- Suffix: `*IT`. Maven Failsafe runs them separately from
  unit tests.
- `@SpringBootTest` only when the full context is needed.
  Prefer slices: `@WebMvcTest`, `@DataJpaTest`,
  `@ServiceTest`.
- Testcontainers for databases and brokers. `@Container`
  + `@Testcontainers` annotations. Shared containers via
  `static` fields to avoid restart per test.
- Wipe test data between tests with `@Sql` scripts or
  `@DirtiesContext` as last resort (slow).

## Test naming

`should_<expected>_when_<condition>`

Examples:
- `should_return_404_when_user_not_found`
- `should_persist_order_when_payment_succeeds`

## Coverage

- Coverage gate is set in the parent POM (JaCoCo). New code
  must not lower the coverage percentage.
- 100% coverage is not a goal. Cover behaviour, not
  getters/setters.

## Test data

- Use builder/factory methods for test fixtures, not raw
  constructors with 15 parameters.
- No production data in tests — not even anonymised. Generate
  synthetic data.

