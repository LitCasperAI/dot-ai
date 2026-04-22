---
name: prepare-release
description: Drive the repository from a green main branch to a release-ready state — version bump, release notes, environment verification, and CI trigger. Stops before any external submission so a human can approve the final push. Activates security-reviewer if the release includes changes flagged during review-change.
---

## Inputs

- Optional: `version=<semver>` to force a specific version. If
  omitted, the skill proposes a bump based on the commits since
  the last release tag:
  - breaking changes (per ADRs or commit markers) → major,
  - new user-visible behaviour → minor,
  - fixes and internal changes only → patch.
- Optional: `channel=<name>` if the stack's release configuration
  defines multiple channels (staging, beta, production). Defaults
  to the stack's declared production channel.

## Personas

1. `release-engineer` (from `.ai/personas/release-engineer.md`,
   plus any `.ai/overrides/<stack>/release-engineer.md`).
   Primary.
2. `security-reviewer` (conditional) — activated if any change
   included in this release touched paths flagged during
   `review-change` (auth, PII, payments, crypto). The skill
   requires evidence of security sign-off for those changes
   before proceeding.

## Rules loaded

From `.ai/project.yaml`: all entries under `rules.load`,
particularly `global/05-version-control.md`,
`global/08-secrets-and-data.md`, and the stack's build-and-release
rule file. Stack rules name the concrete tools (CI provider,
signing tool, submission tool); the skill does not hardcode
them.

## Steps

1. **Orient.** Read `.ai/project.yaml`. Resolve `paths.*`. Load
   every rule file listed under `rules.load`. Load the
   `release-engineer` persona.

2. **Preflight (release-engineer).** Confirm:
   - The current branch is the project's declared release branch
     (`main` or the configured default).
   - The working tree is clean.
   - CI for the latest commit is green. Red or missing CI is a
     stop.
   - No plan under `<paths.plans>/active/` has `status:
     in-progress` that is tagged for this release. In-progress
     work does not ship.
   Any failure here stops the skill with a clear message.

3. **Gather changes (release-engineer).** List commits since the
   last release tag (or since repo root if none). Group into:
   - **User-visible** — behaviour changes a user would notice.
   - **Internal** — refactors, test changes, infrastructure.
   - **Security-sensitive** — commits touching paths that would
     have activated `security-reviewer` in `review-change`.
   If any security-sensitive change lacks a linked security
   sign-off (ADR, PR review, or explicit acknowledgement in the
   commit trail), stop and surface — the release does not
   proceed without it.

4. **Propose the version (release-engineer).** If `version=` was
   supplied, validate it is greater than the current version and
   follows semver. Otherwise compute the proposed bump per the
   input rules and present it to the user. Wait for confirmation
   before editing files.

5. **Apply the version bump (release-engineer).** Edit the
   version fields named by the stack's build-and-release rule
   file. The skill does not guess file locations — if the stack
   rule does not name them explicitly, stop and surface. Commit
   the bump on its own, with a conventional message (e.g.
   `chore(release): v<version>`).

6. **Write release notes (release-engineer).** Compose release
   notes from step 3's grouping:
   - **Highlights** — user-visible changes, one line each.
   - **Fixes** — bug fixes, one line each.
   - **Internal** — brief summary, not item-by-item.
   - **Security** — present only if security-sensitive changes
     shipped.
   Save to the path the stack's build-and-release rule names
   (e.g. `CHANGELOG.md`, `docs/releases/<version>.md`). Commit
   alongside the version bump or as a second commit — the stack
   rule decides. Do not post to a store listing from this skill.

7. **Tag and push (release-engineer, requires user approval).**
   Create the annotated release tag (`v<version>`). Per
   `global/02-agent-conduct.md`, pushing the tag is a shared-
   state action — confirm with the user before pushing.

8. **Trigger CI (release-engineer, requires user approval).**
   The release build is produced by CI, never locally. Kick off
   the release pipeline as the stack rule prescribes (tag push,
   manual workflow dispatch, Fastlane lane, etc.). Surface the
   pipeline URL or log location.

9. **Stop before submission.** The skill does **not** submit to
   a store, publish a package, or deploy. Submission is a
   separate human-approved step, handled by the stack's
   submission tooling. Surface the next action the user should
   take.

## Outputs

- Version bump commit(s) on the release branch.
- Release notes written to the path the stack rule names.
- An annotated release tag (pushed only with user approval).
- A triggered CI run (only with user approval).
- A summary delivered to the user: version, notes path, tag,
  CI URL, and the exact next action required to submit.
- **No** store submissions, **no** package publishes, **no**
  production deploys. Those are explicit human steps.
