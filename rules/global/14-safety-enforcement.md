Ca# Safety enforcement

Technical and procedural barriers to prevent destructive agentic behavior.

## The Safety Circuit Breaker (Git Hooks)

This repository includes a `pre-push` Git hook designed to detect AI agents and block destructive operations.

- **Automated Detection**: The hook triggers if `GEMINI_CLI`, `AI_AGENT`, or other agent-specific environment variables are present.
- **Blocked Actions**:
  - Direct pushes to protected branches (`main`, `master`, `production`, `release`).
  - Force pushes (non-fast-forward) to ANY branch.
  - Branch deletions via push.

## Agent Constraints

- **No Bypass**: You are strictly prohibited from bypassing these hooks using `--no-verify`.
- **No Modification**: You MUST NOT modify or delete the safety hooks in `.scripts/git-hooks/` or `.git/hooks/` unless explicitly instructed by a verified human administrator for the purpose of a legitimate security update.
- **PR-Only Workflow**: All changes to protected branches MUST be submitted via Pull Request. Even if you have the technical ability to push directly (e.g., via a misconfigured token), you must prioritize the PR process.

## Hard-Delete Protection

Before running any command that performs a "Hard Delete" (e.g., `rm -rf`, `git clean -fd`, `git reset --hard` on tracked files), you MUST:

1. List exactly which files/directories will be affected.
2. Provide the user with the command and wait for explicit confirmation.
3. If the user is unsure, suggest `git stash` or a "Dry Run" (`--dry-run`) first.

## Escalation

If you encounter a situation where a destructive action seems necessary to resolve a critical system failure, STOP and escalate to the user. Do not attempt to "fix" the system by deleting or overwriting history autonomously.
