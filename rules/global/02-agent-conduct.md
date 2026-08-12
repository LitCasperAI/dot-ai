# Agent conduct

Rules for any AI coding agent (Claude Code, Gemini CLI, Copilot,
Cursor, Codex, or otherwise) operating in this repo. Stack-agnostic.
Stack rules may add to these; they may not weaken them.

## Read before you write

- Read the file before editing it. Do not edit from memory or from
  a summary.
- Do not invent file paths, function names, flags, or APIs. If you
  cannot confirm a symbol exists in the current tree, do not
  recommend it.
- When a rule, persona, or skill points at another file, load that
  file before acting on the pointer.

## Scaffolding-First

- **Source of Truth**: Treat the `.ai/` directory as your primary source of behavioral truth. Regardless of the user's prompt phrasing, you MUST map every request to the most relevant skill in `.ai/skills/`. Do not improvise workflows or bypass established skill procedures.
- **Entry Point**: Every session must begin by reading `.ai-local/project.yaml` and `.ai/AGENTS.md` to ensure full alignment with project-specific AI governance.

## Scope discipline

- Match the scope of your change to what was asked. Do not
  refactor, rename, or reformat files outside the task. The test:
  every changed line should trace directly to the user's request.
- Do not add speculative abstractions, feature flags, or
  backwards-compatibility shims for scenarios that are not
  required.
- If the task is unclear or underspecified, stop and ask. Silent
  guessing is worse than a paused task. If multiple interpretations
  exist, present them — do not pick one silently.

## Destructive and irreversible actions

Confirm with the user before running any action that is hard to
reverse or affects shared state. Examples:

- `git push --force`, `git reset --hard`, `git clean -fd`, branch
  or tag deletion, rewriting published history.
- `rm -rf`, dropping database tables, truncating data, deleting
  cloud resources.
- Bypassing safety checks (`--no-verify`, `--force`, disabling
  hooks or signing).
- Publishing: releases, package pushes, production deploys,
  sending messages to shared channels.

A user approving one risky action does not authorise future ones.
Scope of authorisation is exactly what was asked.

## Execution Discipline

- **Surgical Autonomy (Plan Optional)**: For minor, low-risk, or single-file changes (e.g., styling tweaks, helper function updates, or bug fixes with a clear and narrow scope), a formal `.md` plan in `docs/plans/active/` is **optional**. In these cases, the agent MUST still provide a concise summary of intent in the conversation before acting.
- **Architectural Planning (Plan Mandatory)**: For multi-step features, changes affecting multiple files or layers, or tasks introducing architectural drift, a formal plan in `docs/plans/active/` is **mandatory**. The agent must wait for explicit user approval of the plan before writing product code.
- **Inquiry vs. Directive**: Treat "we should" or broad feature descriptions as **Inquiries** (requests for research or planning), not **Directives** to begin implementation.
- **Contract-First**: Prioritize identifying and validating the interfaces or contracts (e.g., API schemas, UI structures, or resource configurations) before implementing complex logic or internal integrations. Check for existing implementations of these contracts before proposing new ones. If a required dependency is missing or undocumented, clarify the approach with the user.
- **Verification-Every-Step**: Regardless of whether a formal plan was created, the agent MUST run the project's verification tools (formatting, linting, type-checking, and testing) after **every** implementation step. Validation rigor is non-negotiable and independent of task size.

## Tool discipline

- **Toolchain Integrity**: Before executing any command, identify the project's established toolchain (dependency managers, build tools, environment managers) by inspecting the root directory for configuration and lockfiles. You are strictly prohibited from using tools that conflict with the established environment (e.g., using a different package manager or build system than the one used by the project).
- Prefer dedicated tools over raw shell when the agent exposes
  them (file read/edit/search). Reserve shell for shell-only work.
- Do not run commands to "see what happens." Know what a command
  does before running it.
- Do not silence a failing check by disabling it. Fix the
  underlying cause, or stop and escalate.

## Honesty

- Report what you actually did, not what you intended. If a step
  failed, say so.
- Do not mark work complete while tests fail, types break, or
  lint is red.
- If you skipped or stubbed something, name it explicitly in your
  summary.
