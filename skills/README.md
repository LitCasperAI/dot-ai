# Building Skills & Commands

This directory contains the executable procedures (**Skills**) that define the agent's workflow. Skills are tool-agnostic and designed to be portable across different AI interfaces (Claude Code, Gemini CLI, etc.).

## The Skill-to-Command Mapping

A single logical capability is comprised of two parts:

1.  **The Skill (`skills/<name>/SKILL.md`)**: The source of truth. It defines the personas, rules, and numbered steps of the procedure.
2.  **The Command (`.gemini/commands/<name>.toml`)**: The entry point for the Gemini CLI. It maps a slash-command to the skill.

## 1. Creating the Skill (`SKILL.md`)

Every `SKILL.md` must follow this structure to ensure it can be followed by an agent:

### Frontmatter
```markdown
---
name: skill-name
description: A concise, one-sentence summary of what the skill does.
---
```

### Sections
*   **Inputs**: List any arguments, files, or state required to start.
*   **Personas**: List the personas activated (e.g., `architect`, `implementer`).
*   **Rules loaded**: Explicitly state which rules from `project.yaml` are required. **Never hardcode paths.**
*   **Steps**: A numbered list of instructions. Each step **must** name the acting persona (e.g., "1. **Orient (architect)**: ...").
*   **Outputs**: Define exactly what artifacts are produced and where they land.

## Tool-Specific Commands

While skills are the source of truth, they are exposed to the user via tool-specific configurations (e.g., Gemini `.toml` commands or Claude Code symlinks).

*   **Gemini CLI**: See `.gemini/commands/README.md` for instructions on building the command "shims" that link slash-commands to skills.
*   **Claude Code**: Skills are automatically discovered when symlinked into the `.claude/skills/` directory.

## Best Practices

*   **Agnosticism Hierarchy**:
    *   **Global Skills**: Must not assume a specific language or framework.
    *   **Stack Skills**: Should use the conventions of the stack but stay project-agnostic.
*   **Strategy-First**: If a skill modifies code, its steps should usually involve a research/planning phase before execution.
*   **Read-Only Validation**: Whenever possible, skills should end with a validation step (running tests, linting, or an integrity check).
*   **Atomic Actions**: If a skill moves or deletes files (like `archive-plan`), it should perform a "Preflight" check to ensure all source files exist before making any changes.
