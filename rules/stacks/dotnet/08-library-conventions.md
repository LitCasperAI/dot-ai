# .NET Library Conventions

Rules specific to authoring NuGet packages. Backend services
follow `05-folder-structure.md`; this file covers libraries
that ship to consumers.

Heavily informed by the
[dotnet-library-starter-kit](https://github.com/dennisdoomen/dotnet-library-starter-kit)
and its battle-tested patterns from FluentAssertions.

---

## Public API surface

- **Every public type and member is intentional.** Default to
  `internal`; make something `public` only when it is part of
  the library's contract. A type that escapes by accident is a
  breaking change to remove.
- **API snapshot tests prevent accidental breaks.** Use Verify
  (`Verify.Xunit`) to generate a `.txt` per target framework
  containing every public type and member. A diff that cannot
  be explained is not accepted.
- **Updating snapshots** is done via `AcceptApiChanges.ps1` /
  `.sh` or the Rider Verify plugin, never by hand-editing
  the `.txt` files.

## Multi-targeting

- **Target the widest supportable set.** Typical:
  `net8.0;net6.0;netstandard2.1;netstandard2.0;net472`. Check
  the project's declared targets in `Directory.Build.props`.
- **Conditional compilation for framework-specific code.** Use
  `#if NET8_0_OR_GREATER` sparingly; prefer runtime feature
  detection or polyfills.
- **Analyzers run on the newest TFM only** to keep the build
  fast. The code is the same across targets.

## Package metadata

- **Required properties** (all in `Directory.Build.props`):
  `PackageId`, `Authors`, `Description`, `PackageLicenseExpression`,
  `RepositoryUrl`, `RepositoryType`, `PackageReadmeFile`,
  `PackageIcon`.
- **Source Link is enabled** so consumers can step into source.
  Set `<EmbedUntrackedSources>true</EmbedUntrackedSources>`
  and `<IncludeSymbols>true</IncludeSymbols>` with
  `<SymbolPackageFormat>snupkg</SymbolPackageFormat>`.

## Dependencies

- **Minimize runtime dependencies.** Every dependency is a
  compatibility and versioning burden on consumers. If the
  functionality can be implemented in < 50 lines without a
  dependency, do so.
- **Pin dependency version ranges conservatively.** Use
  `[1.0.0, 2.0.0)` ranges, not open-ended `>=`. A consumer's
  `dotnet restore` must not pull a major version you haven't
  tested against.
- **No transitive analyzer leaks.** All analyzers are
  `PrivateAssets="all"`.

## Extensibility

- **Sealed by default.** Mark classes `sealed` unless they are
  explicitly designed for inheritance. Unsealed classes are
  part of the public contract and harder to evolve.
- **Virtual members are deliberate extension points.** A
  `virtual` method without a documented override scenario is an
  accidental contract.
- **Prefer composition over inheritance.** Expose interfaces
  and extension methods rather than deep class hierarchies.

## Exceptions

- **Throw `ArgumentException` / `ArgumentNullException` for
  public API misuse.** These are programming errors, not
  runtime failures.
- **Use `[DoesNotReturn]` and `[DoesNotReturnIf]`** attributes
  on throw helpers so the compiler and analyzers understand
  control flow.
- **Custom exception types are `[Serializable]`** and have the
  standard three constructors if the library targets
  `netstandard2.0` / `net472`.

## Documentation

- **Public API members have XML doc comments.** The library's
  NuGet package includes the XML doc file so consumers get
  IntelliSense.
- **XML doc is the source of truth**, not a separate docs
  site. If the docs site exists, it is generated from the XML
  comments.
- **Examples use `<example>` and `<code>` tags** in XML doc
  so they render in IDE tooltips.

## Testing (library-specific)

- **Functional tests use xUnit + FluentAssertions.** Test class
  naming: `<Feature>Specs` with nested classes per capability.
- **API verification tests** use Verify to snapshot the public
  API per target framework. Breaking changes are caught before
  merge.
- **Test the consumer experience.** A test that constructs the
  library's types the way a consumer would catches usability
  problems that internal tests miss.

## Release

- **GitVersion drives the version.** No manual version bumps.
- **`dotnet pack` is the single packaging command.** The Nuke
  build orchestrates version injection, README preparation,
  and packaging.
- **Push to NuGet.org only from tagged commits.** The CI
  pipeline checks `refs/tags/*` before publishing.
  `--skip-duplicate` prevents failures on re-runs.

## Template-driven consistency

- **The starter kit uses Scriban templates** to generate
  multiple project variants (binary/source-only,
  OSS/internal, GitHub/AzDo). If this library was scaffolded
  from the template, respect the generated structure.
- **Do not rearrange the generated solution layout** without
  updating the template itself. Drift between template and
  generated projects makes future re-scaffolding painful.
