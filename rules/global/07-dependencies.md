# Dependencies

Applies to every stack. Stack rules declare the package manager,
lockfile, and upgrade tooling; this file declares the posture.

## Adding a dependency

- Prefer the standard library and existing project dependencies
  before adding something new.
- A new dependency requires a recorded reason: either a line in
  the PR description or, for anything load-bearing, an ADR.
- Check that the dependency is actively maintained, has a
  compatible licence, and is not a thin wrapper around something
  you could write in a few lines.
- Never add a dependency to work around a problem you have not
  diagnosed.

## Versioning and lockfiles

- Lockfiles are committed. A PR that changes `package.json`,
  `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, or the
  stack's equivalent must also update the lockfile.
- Do not hand-edit lockfiles. Use the package manager.
- Pin direct dependencies to a specific version or narrow range
  appropriate to the stack. Do not float to `latest`.

## Upgrading

- Security upgrades land on their own, not bundled with feature
  work.
- Major version bumps land on their own, with a note on the
  breaking changes that were reviewed.
- Do not upgrade a dependency incidentally because the lockfile
  drifted. Revert and upgrade deliberately.

## Licences and supply chain

- New dependencies must have a licence compatible with the
  project. If you are unsure, stop and escalate rather than
  guessing.
- Do not install from a fork, a gist, or a random tarball. If the
  canonical registry does not have what you need, that is a
  conversation, not a workaround.

## Automated Management

- For checking, upgrading, and securing project dependencies based on external scans (e.g. WIZ CVEs) and best practices, invoke the `/manage-dependencies` skill (which activates the `dependency-manager` persona).
- **Security Precaution:** Any installation or modification of packages MUST be explicitly approved by the user and MAY NEVER be performed automatically. Always strictly validate the exact package name and version against the official registry or the existing lockfile before executing shell commands to mitigate command injection or typo-squatting risks.
