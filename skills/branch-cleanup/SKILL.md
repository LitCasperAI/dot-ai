---
name: branch-cleanup
description: Audit local and remote git branches in the current repository. Identify merged, stale, and orphaned branches. Present a report and propose deletions — execute only with explicit user approval.
---

## Inputs

- **Repository**: The current working directory (must be a git repo).
- **Main branch** (optional): User can specify. If not given, auto-detect
  from `HEAD` of `origin` (may be `main`, `master`, `develop`, etc.).

## Personas

1. `implementer` — executes the cleanup procedure.
2. `reviewer` — validates the report before destructive actions.

## Rules loaded

From `.ai/project.yaml`: all entries under `rules.core` and
`rules.contextual`.

## Tooling

This skill ships with a **Python script** that handles classification
and report generation deterministically:

```
.ai/skills/branch-cleanup/branch-cleanup.py
```

The agent **must** run this script rather than reimplementing the logic.
This ensures consistent formatting, correct tag analysis, and proper
Markdown output across all invocations.

### Script usage

```bash
python3 .ai/skills/branch-cleanup/branch-cleanup.py \
    [--main BRANCH]        \   # Override main branch detection
    [--repo-name NAME]     \   # Override repo name resolution
    [--output DIR]         \   # Report output directory (default: cwd)
    [--json]                   # Also emit JSON summary for agent parsing
```

The script:
- Resolves the repo name (sandbox `.repoN` → human-readable symlink)
- Auto-detects the main branch
- Runs `git fetch --prune origin`
- Classifies all local and remote branches
- Analyses `release/*` and `hotfix/*` branches against tags (Step 4a)
- Prints a truncated terminal report (max 20 per category)
- Saves a **full Markdown report** with proper list formatting to
  `<output>/branch-cleanup-report-<YYYY-MM-DD>.md`
- With `--json`, appends a machine-readable summary

## Steps

1. **Orient.**
   Read `.ai/project.yaml` if present. Confirm the current directory is a
   git repository (`git rev-parse --git-dir`). If not, stop with a clear
   error.

   **Resolve the repository name** for the report header.
   Follow the resolution procedure in
   `.ai/rules/global/00-target-repo-discovery.md` § "Repository name
   resolution". Never use a raw `.repoN` identifier in the report.

   **Check out the main branch** before running the audit. This ensures
   no branch is protected as "current" during classification, allowing
   all non-main branches to be evaluated for cleanup:

   ```bash
   git fetch origin main
   git checkout main
   git pull --ff-only origin main
   ```

   If there are uncommitted changes, stash them first and note the
   original branch so the user can return to it after cleanup.

2. **Run the audit script.**
   Execute the bundled Python script to classify branches and generate
   the report:

   ```bash
   python3 .ai/skills/branch-cleanup/branch-cleanup.py \
       --output temp/ --json
   ```

   Pass `--main <branch>` if the user specified one. Pass
   `--repo-name <name>` if the resolved name differs from auto-detection.

   The script performs Steps 2a–6a internally:

   - **2a. Detect the main branch** — symbolic-ref → probe main/master/develop.
   - **3a. Fetch + prune** — `git fetch --prune origin`.
   - **4a. Classify local branches** — merged, squash-merged, stale, active, current.
   - **4b. Analyse release/hotfix branches (tag check):**

     For every branch matching `release/*` or `hotfix/*`, determine
     whether a corresponding tag exists and where it points. Tag name
     patterns checked: `<version>`, `v<version>`, `release/<version>`,
     `hotfix/<version>`, `release-<version>`, `hotfix-<version>`.

     | Sub-category | Condition | Classification |
     |---|---|---|
     | **Tagged at HEAD** | Tag points to the branch tip. | 🟢 Safe to delete. |
     | **Tagged behind HEAD** | Tag exists but points to an ancestor — branch has post-tag commits. | 🟠 Needs inspection. |
     | **Untagged** | No matching tag found. | 🟠 Needs inspection. |

   - **5a. Classify remote branches** — same categories plus orphaned-local.
   - **6a. Generate reports** — terminal (truncated) + Markdown file (full).

3. **Present the report.**
   Show the terminal output from the script to the user. Note the saved
   file path.

4. **Propose actions.**
   Based on the script's JSON summary, present a numbered action plan:

   ```
   📋 Proposed Actions
   ═══════════════════

   [1] Delete N local merged branches (includes tagged releases)
   [2] Delete N remote merged branches (git push origin --delete)
   [3] Delete N local stale branches (⚠️ not merged — data loss possible)
   [4] Delete N remote stale branches (⚠️ not merged — data loss possible)
   [5] Review N release/hotfix branches needing inspection (🟠 — listed individually)

   Enter action numbers to execute (e.g. "1,2") or "none" to abort:
   ```

   - Actions [1] and [2] are **safe** — branches are fully merged or
     release/hotfix branches whose tag covers the branch tip.
   - Actions [3] and [4] are **destructive** — mark them with ⚠️ and
     require explicit confirmation per branch before deleting.
   - Action [5] is **interactive** — show each 🟠 release/hotfix branch
     one by one with its tag status, and ask the user to keep or delete.
   - Never auto-execute. Always wait for user input.
   - If no branches to clean, say "✨ Repository is clean — no stale or
     merged branches found." and stop.

5. **Execute approved actions.**
   For each approved action:
   - **Local delete**: `git branch -d <name>` for merged,
     `git branch -D <name>` for stale (after per-branch confirmation).
     Note: squash-merged and upstream-gone branches require `-D` since
     git does not consider them "fully merged" — this is safe because
     the remote branch was already deleted after the PR was merged.
   - **Remote delete**: `git push origin --delete <name>`.
   - **Release/hotfix inspection** (action [5]): For each 🟠 branch,
     show the tag status and ask "Delete / Keep / Skip all remaining?".
     Delete only branches the user explicitly approves.
   - Print each deletion as it happens.
   - On error (e.g., permission denied on remote), log the error and
     continue with remaining branches.

6. **Summary.**
   Print a final summary:
   ```
   ✅ Cleanup complete
      Deleted: N local, M remote
      Skipped: K (user declined or errors)
      Report:  <path-to-saved-report>
   ```

## Safety Rules

- **Never delete the main branch** (or `master`/`develop` if that is the
  default).
- **Never delete the currently checked-out branch.**
- **Never force-delete a branch that has unmerged commits** without
  explicit per-branch user approval.
- **Never push `--delete` to a protected branch.** If the remote rejects
  the push, report the error and move on.
- **Release/hotfix branches require tag verification.** Only auto-classify
  a `release/*` or `hotfix/*` branch as safe to delete if a matching tag
  points at the branch's HEAD commit. All other release/hotfix branches
  require explicit user inspection (Step 4a).
- **Dry-run by default**: The report (Steps 6–7) is always shown before
  any mutations. The user must opt in to each action group.

## Edge Cases

- **Detached HEAD**: Use `git symbolic-ref HEAD` to detect. If detached,
  note it in the report and skip "current branch" logic.
- **No remote**: If `origin` doesn't exist, skip all remote operations
  and note "no remote configured".
- **Broker shim timeout**: In the sandbox, git commands route through the
  broker shim. If a command times out, note "timeout" for that branch
  and continue.
- **Many branches**: When the repo has >50 branches in any category,
  the terminal report should show the first 20 with a count summary
  (e.g., "… and 57 more"). The saved file report always lists all
  branches.
- **Tag naming conventions vary**: When checking for release/hotfix tags,
  try all common patterns: `<version>`, `v<version>`, `release/<version>`,
  `hotfix/<version>`, `release-<version>`, `hotfix-<version>`. A single
  match is sufficient.

