---
name: integrity-check
description: Report on the local health of a scaffold installation (Source or Consumer). Runs four categories of checks — installation gate, content-presence, pointer-resolution, version-record — and prints a Markdown report. Read-only; makes no changes. Invoked explicitly by the user, never automatically.
---

## Inputs

None. The skill operates on what it finds on disk, rooted at
the current working directory from which it is invoked.

## Personas

None. The skill is mechanical. It enumerates checks, records
outcomes, prints a report, and stops.

## Rules loaded

**None** — this skill does not interpret rules. It applies a fixed set of
structural checks defined in this file.

## Steps

1. **Mode Detection.** Detect the scaffold mode and root:

   - If `./.ai/SCAFFOLD_VERSION` exists:
     Set `MODE=CONSUMER`, `ROOT=.ai/`, and `PROJECT_YAML=.ai-local/project.yaml`.
   - Else if `./SCAFFOLD_VERSION` exists:
     Set `MODE=SOURCE`, `ROOT=./`, and `PROJECT_YAML=project.yaml.example`.
   - Otherwise, record a single check and stop:
     ```
     category: installation
     target:   .
     outcome:  FAIL
     detail:   not a scaffold installation (no SCAFFOLD_VERSION found)
     ```

2. **Build the content-presence manifest.** Add the following paths to the manifest (prefixed by `ROOT` where applicable):

   - `<ROOT>AGENTS.md`
   - `<ROOT>design-rationale.md`
   - `<ROOT>design-system.md`
   - `<ROOT>intro.html`
   - `<PROJECT_YAML>`
   - every `<ROOT>personas/*.md`
   - every `<ROOT>rules/**/*.md`
   - every `<ROOT>skills/*/SKILL.md`
   - every `<ROOT>templates/*.md`
   - every `<ROOT>terminology/*.md`
   
   If `MODE=SOURCE`, also add:
   - every `.scripts/*.sh`
   - every `.scripts/*.ps1`

   Resolve via glob. `<ROOT>.ai-local/overrides/`, `<ROOT>.ai-local/rules/`,
   and `<ROOT>.ai-local/terminology/` are allowed to be empty and are
   **not** in the manifest.
   `<ROOT>SCAFFOLD_VERSION` is handled separately by Step 5.

3. **Content-presence checks.** For every manifest entry resolved in Step 2:

   - If the file does not exist on disk → `FAIL — missing`.
   - If the file exists and its size is 0 bytes → `FAIL — empty`.
   - Otherwise → `PASS`.

   Additionally, for each expected-populated directory:
   - `<ROOT>personas/`
   - `<ROOT>rules/global/`
   - `<ROOT>skills/`
   - `<ROOT>templates/`
   - `<ROOT>terminology/`
   If the glob for that directory returns no entries, record:
   `FAIL — expected-populated directory is empty` against the directory path.

4. **Pointer-resolution checks.**

   4a. **Symlinks.** Walk `ROOT` recursively.
   For every symlink encountered, resolve its target. If the target does not exist on disk → `FAIL — broken symlink <link> -> <target>`. Otherwise → `PASS`.

   4b. **Frontmatter `related.*` pointers.** CONSUMER mode only — in SOURCE mode, skip this check entirely (the bare scaffold carries no `docs/` tree of its own to validate).

   In CONSUMER mode, read `paths.briefs`, `paths.specs`, `paths.plans`, and `paths.decisions` from `PROJECT_YAML` (`.ai-local/project.yaml`). If `PROJECT_YAML` is missing or any of those keys is unset, record `FAIL — PROJECT_YAML missing required paths.* keys` and skip the rest of 4b.

   Otherwise, for every `*.md` under the resolved `paths.briefs`, `paths.specs`, and `paths.plans` directories, parse YAML frontmatter. For every non-null value under `related.*`:
   - String path: `FAIL` if the path does not resolve; `PASS` otherwise.
   - List value: for each id, `FAIL` if no file matching `<paths.decisions>/NNNN-*.md` exists; `PASS` per id otherwise.

5. **Version-record check.** Read `<ROOT>SCAFFOLD_VERSION`.

   - If missing or empty → `FAIL — no scaffold version recorded`.
   - Otherwise → `PASS — <value>` (trimmed content).

6. **Semantic Scope checks.**

   - **Global rules.** For every `*.md` under `<ROOT>rules/global/` (excluding `README.md`):
     - Scan content for forbidden stack/project terms: `react-native`, `nextjs`, `nodejs`, `react`, `vue`, `angular`, `flutter`, `electron`.
     - `FAIL — semantic violation: global rule <file> contains restricted term <term>` if any are found.
     - Otherwise → `PASS`.

   - **Stack rules.** For every `*.md` under `<ROOT>rules/stacks/` (excluding `README.md`):
     - Scan content for forbidden project-specific terms: `pmview`.
     - `FAIL — semantic violation: stack rule <file> contains restricted term <term>` if any are found.
     - Otherwise → `PASS`.

7. **Emit the report.** Print to the agent's conversation output in this Markdown structure:

   ```markdown
   # Integrity check (<MODE>) — YYYY-MM-DD

   ## Passes
   - `<category>` — `<group_path>` — `<count> files`
   ...

   ## Categories run
   - <category> — <n>
   ...

   **Summary:** <passed>/<total> checks passed. <failed> failures.

   ## Failures
   - `<category>` — `<target>` — <detail>
   ...
   ```

## Outputs

- A Markdown report printed to the agent's conversation output.
