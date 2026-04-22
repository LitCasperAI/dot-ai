# .NET Testing

How tests are written and run in this stack. Complements the
global testing posture in `global/06-testing.md`.

---

## Frameworks

- **Unit and integration tests: xUnit.** The default for new
  .NET projects. NUnit and MSTest are not used in new projects;
  existing suites stay until migrated.
- **Assertions: FluentAssertions.** Every assertion reads like
  a sentence: `result.Should().Be(42)`. Raw `Assert.Equal` is
  rejected in new code.
- **API snapshot testing: Verify** (`Verify.Xunit`). Public
  API surfaces are snapshot-tested so breaking changes are
  caught before release. Update snapshots with
  `AcceptApiChanges.ps1` / `.sh` or the Rider Verify plugin.
- **Mocking: NSubstitute or Moq.** Pick one per project. Do
  not mix.

## What to test at which level

- **Pure functions and domain logic** have unit tests. These
  are the fastest and most valuable tests — write them
  generously.
- **Service classes** are tested with real dependencies where
  practical (real DB via Testcontainers, real file system). Mock
  only what crosses a network boundary outside your control.
- **Controllers / minimal API handlers** get integration tests
  using `WebApplicationFactory<T>`. These exercise the full
  request pipeline (middleware, routing, model binding, auth).
- **Background workers / hosted services** are tested by
  triggering the real event and asserting on the side effect,
  not by calling the handler method with a fake payload.
- **Contract tests** for outbound HTTP clients verify request
  shape against a recorded response or Pact contract. A client
  wrapper without a contract test is unfinished.

## Test naming

- **Use the pattern `When_[scenario]_Then_[expected]` or
  `Should_[expected]_When_[scenario]`.** Pick one per project
  and be consistent. Never `Test1()`.
- **Group related tests** with nested classes inside the test
  class to mirror capabilities or features.
- **AAA structure:** Arrange, Act, Assert — with comment
  markers for readability.

```csharp
public class OrderServiceTests
{
    public class PlaceOrder
    {
        [Fact]
        public void Should_create_order_when_cart_is_valid()
        {
            // Arrange
            var cart = BuildValidCart();

            // Act
            var result = sut.PlaceOrder(cart);

            // Assert
            result.Should().NotBeNull();
            result.Status.Should().Be(OrderStatus.Placed);
        }
    }
}
```

## Test file layout

- Tests live in a dedicated test project: `<ProjectName>.Tests`
  or `<ProjectName>.Specs`. Not colocated with production code.
- Integration test fixtures (seed data, Testcontainer helpers)
  live in a shared `TestUtils` project or a `_TestInfrastructure`
  folder and are not referenced from production code.

## Database in tests

- **Integration tests hit a real database** via Testcontainers
  (or a shared local instance). In-memory providers like
  `UseInMemoryDatabase` are rejected — they lie about query
  behaviour, transactions, and migrations.
- **Each test owns its data.** Use a fresh schema, a unique
  tenant id, or a transaction that rolls back. No shared
  mutable state between tests.
- **EF migrations run as part of test setup** so that schema
  drift is caught immediately.

## External services

- **Third-party HTTP calls are mocked with WireMock.NET** or
  a delegating handler stub registered in
  `WebApplicationFactory`. Never hit real third-party APIs
  in CI.

## Snapshots

- **API verification tests** use Verify to snapshot public
  types, methods, and signatures per target framework. A
  diff that cannot be explained is not accepted.
- When the change is intentional, update snapshots and note
  the breaking change in the PR description.

## Coverage

- **Coverage is a floor, not a target.** The global minimum is
  declared in `global/06-testing.md`; services with security
  or money-handling code are expected to run higher.
- **Use Coverlet** for collection, integrated via
  `coverlet.collector`. Report format: Cobertura for CI,
  HTML for local review.

## Performance and load tests

- **Load tests live in `load/`** at the repo root, using the
  project's declared tool (k6, NBomber, or BenchmarkDotNet
  for micro-benchmarks). They are not run in PR CI.
- **A claim about throughput comes with a benchmark run.**
  "It seems fast" is not evidence.
