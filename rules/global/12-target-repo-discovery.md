# Target repository convention discovery

When working on files inside an imported repository (mounted under
`/.mnt/.repoX/` in-container, or under the host `GIT_ROOT` path),
the agent **must** check that repository's root for local convention
files before applying sandbox-level rules.

## Probe order

Check the target repo root for these files, in order:

1. `.ai/project.yaml` — full AI scaffold (same format as this sandbox)
2. `.ai/AGENTS.md`
3. `CLAUDE.md`
4. `GEMINI.md`
5. `.github/copilot-instructions.md`
6. `conductor/workflow.md` — Conductor-style workflow conventions

If any are found, read them. Directives in these files — especially
regarding **commit message format**, **branch naming**, **workflow
steps**, and **code style** — take precedence over the sandbox's
global and stack rules on the same topic.

## Precedence

The full rule chain when working inside a target repo is:

1. Sandbox `global/*` — baseline (lowest priority)
2. Sandbox `stacks/<stack>/*` — stack constraints
3. **Target repo conventions** — from the files listed above
4. Sandbox `local/*` — sandbox-specific overrides (highest priority,
   but should only cover sandbox-internal concerns)

When the target repo defines a convention that conflicts with a
sandbox global rule (e.g., the repo requires Jira-prefixed commits
while the sandbox global says plain imperative), **follow the target
repo's convention**.

## Repository name resolution

In the sandbox, the agent's working directory may be a raw bind-mount
path (`/workspace/.mnt/.repoN`) instead of the human-readable symlink
(`/workspace/<project-name>`). **Always resolve to the human-readable
name** using this procedure:

1. If `cwd` starts with `/workspace/<name>` where `<name>` does **not**
   start with `.`, use `<name>`.
2. If `cwd` starts with `/workspace/.mnt/.repoN`, scan symlinks in
   `/workspace/`: find the link whose `readlink` target equals
   `.mnt/.repoN` and use its `basename`.
3. Fallback: `basename` of `git rev-parse --show-toplevel`.

**Never use a raw `.repoN` identifier** in reports, commit messages,
PR titles, branch names, or any user-facing output. If resolution
fails, ask the user for the human-readable name.

## What this means in practice

- If <project-name> `conductor/workflow.md` says commits
  must be prefixed with `PLT-1234:`, do that — not the sandbox's
  generic imperative style.
- If a repo's `GEMINI.md` defines branch naming, follow it.
- If the target repo has no convention files, the sandbox globals
  apply as normal.
