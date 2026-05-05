# Java / Spring Boot Folder Structure

## Standard multi-module layout

```
<service>/
├── pom.xml                        ← parent POM
├── <module-api>/                  ← DTOs, interfaces, shared contracts
│   └── src/main/java/com/<org>/<service>/api/
├── <module-core>/                 ← business logic
│   └── src/main/java/com/<org>/<service>/
│       └── feature/
│           └── <name>/
│               ├── <Name>Controller.java
│               ├── <Name>Service.java
│               ├── <Name>Repository.java
│               ├── model/
│               └── dto/
├── <module-infra>/                ← Spring config, adapters, DB migrations
│   └── src/main/resources/
│       ├── application.yml
│       └── db/migration/
└── <module-app>/                  ← Boot application, entry point
    └── src/main/java/com/<org>/<service>/Application.java
```

## Rules

- **Feature-first packaging** within a module. Group by
  business capability, not by technical layer.
- **Package-private by default.** Classes are package-private
  unless they need to be accessed from another package. Public
  is an explicit decision.
- **One public class per file**, matching the filename. No
  inner classes that grow past 50 lines — extract them.
- **`src/test/` mirrors `src/main/`.** Same package, same
  folder depth. Test fixtures live alongside their tests or in
  a shared `testutil/` package.

