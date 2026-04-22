# .NET Build and Release

How the solution is built, packaged, and deployed.
Stack-specific expansion of `global/05-version-control.md`
and `global/07-dependencies.md`.

---

## Build system

- **Nuke is the default build orchestrator** for libraries.
  Backend services use the project's declared CI tool (GitHub
  Actions, Azure Pipelines). Either way, the build is
  reproducible: `dotnet build` or `./build.ps1` from a clean
  clone produces the same output.
- **`global.json` pins the SDK version.** Every developer and
  CI agent runs the same .NET SDK. Do not rely on "whatever
  is installed".
- **`Directory.Build.props`** holds shared properties:
  `LangVersion`, `TreatWarningsAsErrors`, `Nullable`,
  analyzer packages, common metadata. Individual `.csproj`
  files do not repeat these.
- **`Directory.Packages.props`** (Central Package Management)
  declares all NuGet versions in one place. Individual
  projects reference packages without a version attribute.

## Analyzers and static analysis

- **Analyzers run on the newest target framework only.** For
  multi-target libraries, enable `RunAnalyzersDuringBuild`
  only for the newest TFM to keep the build fast.
- **Standard analyzer set:**
  - `Microsoft.CodeAnalysis.BannedApiAnalyzers`
  - `StyleCop.Analyzers`
  - `CSharpGuidelinesAnalyzer`
  - `Roslynator.Analyzers`
  - `Meziantou.Analyzer`
- **All analyzers are `PrivateAssets="all"`.** They do not
  flow to consumers.
- **New analyzer warnings are addressed in the same PR** that
  upgrades the analyzer. Do not suppress without a comment.

## Versioning

- **GitVersion (GitHubFlow or GitFlow)** derives the version
  from the branch and tags. No manual version bumps in
  `.csproj` files.
- **Version components are set by the build:**
  `AssemblyVersion`, `FileVersion`, `InformationalVersion`,
  `PackageVersion` are all derived from GitVersion's output.
- **Pre-release labels** follow the branch:
  - `main` → stable release (e.g. `1.2.3`)
  - `develop` → alpha (e.g. `1.3.0-alpha.4`)
  - `release/*` → rc (e.g. `1.3.0-rc.1`)
  - PRs → `pr<number>` suffix

## Continuous integration

- **CI runs on every push and PR.** The pipeline at minimum:
  restore → build → test → pack (for libraries) or publish
  (for services).
- **Fetch depth 0 for GitVersion.** Git history is required
  for version calculation; a shallow clone breaks it.
- **Deterministic builds are enabled.** Set
  `ContinuousIntegrationBuild=true` during pack/publish so
  that builds are reproducible and source-link works.

## Packaging (libraries)

- **`dotnet pack` produces the NuGet package.** The `.nupkg`
  is the only shipping artifact.
- **Package metadata** (authors, description, license,
  repository URL, icon, readme) is declared in
  `Directory.Build.props` or the library's `.csproj`.
- **Source Link is enabled** so consumers can step into library
  source during debugging.
- **A package README** is extracted from the repo README (the
  Nuke `PreparePackageReadme` target) and included via
  `<PackageReadmeFile>`.

## Publishing (backend services)

- **Container images are built with `dotnet publish` +
  multi-stage Dockerfile.** The runtime image is
  `mcr.microsoft.com/dotnet/aspnet` (not SDK).
- **Health checks** (`/healthz`, `/readyz`) are wired in the
  host and verified by the container orchestrator before
  traffic is routed.
- **Migrations run as a startup step**, either in `Program.cs`
  or a dedicated migration job. They do not run on every
  replica simultaneously — use a distributed lock.

## Dependency updates

- **Dependabot or Renovate runs weekly** for NuGet packages
  and GitHub Actions. PRs are auto-created and CI validates
  them.
- **Security advisories are addressed immediately**, not on
  the weekly cadence.

## Release notes

- **Auto-generated from PR labels.** Categories:
  Breaking Changes, New Features, Improvements, Fixes,
  Documentation, Others.
- **Breaking changes are called out explicitly** in the PR
  title and the release notes.

## License scanning

- **PackageGuard or a declared license scanner** checks that
  new transitive dependencies carry an approved license. A
  dependency with an incompatible license is blocked by CI.
