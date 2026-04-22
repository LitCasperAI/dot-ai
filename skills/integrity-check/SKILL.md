---
name: integrity-check
description: Report on the local health of a consumer .ai/ installation. Runs four categories of checks — installation gate, content-presence, pointer-resolution, version-record — and prints a Markdown report. Read-only; makes no changes. Invoked explicitly by the user, never automatically.
---

## Inputs

None. The skill operates on what it finds on disk, rooted at
the current working directory from which it is invoked.
"Current working directory" is the concrete v1 meaning of
"installation root" — not the git repository root, not
`$HOME`.

## Personas

None. The skill is mechanical. It enumerates checks, records
outcomes, prints a report, and stops.

## Rules loaded

**None** — and this is a deliberate deviation from other
scaffold skills. Most skills begin by reading
`.ai/project.yaml` and loading everything under `rules.load`.
This skill does not, because `.ai/project.yaml` is itself a
content-bearing file that the skill must validate: it appears
in the content-presence manifest (Step 2). If Step 1 tried to
load `project.yaml`, the skill would be unable to run — and
fail loudly — in exactly the case that matters most, when
`project.yaml` is the broken thing.

The skill does not interpret rules. It applies a fixed set of
structural checks defined in this file.

## Steps

1. **Installation gate.** Check whether `.ai/` exists as a
   directory at the current working directory. If it does
   not, record a single check:

   ```
   category: installation
   target:   .
   outcome:  FAIL
   detail:   not a scaffold installation (no .ai/ at current working directory)
   ```

   Emit the report per Step 6 with only this entry and stop.
   "Categories run" lists `installation — 1` only; the other
   three categories are omitted (not rendered as `0`).

2. **Build the content-presence manifest.** By scaffold
   convention (not by reading `project.yaml`), the following
   paths are content-bearing and are added to the manifest:

   - `.ai/AGENTS.md`
   - `.ai/project.yaml`
   - every `.ai/personas/*.md`
   - every `.ai/rules/**/*.md`
   - every `.ai/skills/*/SKILL.md`
   - every `.ai/templates/*.md`

   Resolve via glob. `.ai/overrides/` and `.ai/rules/local/`
   are allowed to be empty and are **not** in the manifest.
   `.ai/SCAFFOLD_VERSION` is handled separately by Step 5,
   not here.

3. **Content-presence checks.** For every manifest entry
   resolved in Step 2:

   - If the file does not exist on disk → `FAIL — missing`.
   - If the file exists and its size is 0 bytes →
     `FAIL — empty`. (This is the Issue 7 regression.)
   - Otherwise → `PASS`.

   Additionally, for each expected-populated directory —
   `.ai/personas/`, `.ai/rules/global/`, `.ai/skills/`,
   `.ai/templates/` — if the glob for that directory returns
   no entries, record one extra check:
   `FAIL — expected-populated directory is empty` against the
   directory path.

   v1 flags zero-byte files only. Below-threshold size
   detection is deferred; see ADR 0001.

4. **Pointer-resolution checks.** Two sub-checks:

   4a. **Symlinks under `.ai/`.** Walk `.ai/` recursively.
   For every symlink encountered, resolve its target. If the
   target does not exist on disk → `FAIL — broken symlink
   <link> -> <target>`. Otherwise → `PASS`.

   4b. **Frontmatter `related.*` pointers across all docs.**
   For every `*.md` under `docs/briefs/` (both `active/` and
   `archive/`), `docs/specs/` (both), `docs/plans/` (both),
   and `docs/decisions/`, parse YAML frontmatter. For every
   non-null value under `related.*`:

   - String value (e.g. `related.spec: docs/specs/active/...`):
     treat as a path. `FAIL` if the path does not resolve to
     a file on disk; `PASS` otherwise.
   - List value (e.g. `related.decisions: [0001, 0002]`):
     for each id, `FAIL` if no file matching
     `docs/decisions/NNNN-*.md` exists; `PASS` per id
     otherwise.
   - Null values are declarations of absence and are not
     checked.

   Archive-directory docs are included by choice (ADR 0001).
   Issue 16's archive-time pointer rewrite means archived
   pointers should still resolve; if they don't, that is a
   real finding, not a false positive.

5. **Version-record check.** Read `.ai/SCAFFOLD_VERSION`.

   - If the file is missing or its content is empty (zero
     bytes, or whitespace-only) → `FAIL — no scaffold version
     recorded`.
   - If present and non-empty → `PASS — <value>`, where
     `<value>` is the file's content trimmed of surrounding
     whitespace.

   v1 does not validate format beyond non-emptiness; see ADR
   0002. A value of `hello` passes. Format enforcement is a
   future version-tracking work item, not this skill's job.

6. **Emit the report.** Print to the agent's conversation
   output in this Markdown structure:

   ```markdown
   # Integrity check — YYYY-MM-DD

   **Summary:** <passed>/<total> checks passed. <failed> failures.

   ## Failures

   _None._
   <or>
   - `<category>` — `<target>` — <detail>
   - ...

   ## Passes

   _None._
   <or>
   - `<category>` — `<target>` [— <detail>]
   - ...

   ## Categories run

   - <category> — <n>
   - ...
   ```

   - `_None._` is the literal rendering when a section has
     no entries. The section is never omitted.
   - "Categories run" lists only categories that had at
     least one check. Zero-count categories are omitted, not
     printed as `0`. This keeps the installation-gate
     single-check report clean.
   - The date in the header is today's date (local time) at
     invocation.

   Stop. The skill writes nothing to disk. Running it twice
   in a row on an unchanged tree produces identical reports.

## Outputs

- A Markdown report printed to the agent's conversation
  output. No files are created, modified, or deleted. No
  frontmatter is touched. No dashboard is refreshed (this
  skill is read-only by design — the dashboard-refresh
  invariant in `rules/global/04-doc-lifecycle.md` applies
  to skills that mutate docs, not to this one).
