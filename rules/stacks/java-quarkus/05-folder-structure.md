# Java / Quarkus Folder Structure

Organised by domain, not by technical type.

---

## Standard layout

```text
<service>/
├── build.gradle                   ← Gradle build file
└── src/
    ├── main/
    │   ├── java/com/company/<service>/
    │   │   ├── feature/
    │   │   │   └── <name>/
    │   │   │       ├── <Name>Resource.java     ← JAX-RS endpoint / gRPC service
    │   │   │       ├── <Name>Service.java      ← Business logic
    │   │   │       ├── <Name>Repository.java   ← Database access
    │   │   │       ├── <Name>Entity.java       ← Database entity
    │   │   │       └── <Name>Mapper.java       ← MapStruct / manual mapper
    │   │   └── core/
    │   │       ├── config/
    │   │       ├── exceptions/
    │   │       └── security/
    │   └── resources/
    │       ├── application.yaml
    │       └── db/migration/                   ← Flyway/Liquibase scripts
    └── test/
        ├── java/com/company/<service>/        ← Mirrors main/
        └── resources/
            └── application-test.yaml
```

## Legacy / Alternative layout

Older or highly specialized projects (like those heavily utilizing Spanner and generated DTO flows) may use a layered technical packaging layout (e.g., `grpc/`, `service/`, `spanner/`, `openapi/`). This is tolerated for existing codebases, but new services should aim for feature-first packaging.

## Rules

- **Feature-first packaging.** Group by business capability, not by technical layer. 
  `feature/users/` contains the resource, service, repository, and models for users.
  No layered packaging (`grpc/`, `services/`, `repositories/`) at the top level for new code.
- **Core package.** Infrastructure code, global exception mappers, security filters, 
  and base configurations live in `core/`.
- **Package-private by default.** Classes are package-private unless they need 
  to be accessed from another package. Public is an explicit decision.
- **One public class per file**, matching the filename. No inner classes that 
  grow past 50 lines — extract them.
- **`src/test/` mirrors `src/main/`.** Same package, same folder depth. Test fixtures 
  live alongside their tests or in a shared `testutil/` package.