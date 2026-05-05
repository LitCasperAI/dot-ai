# Gemini Commands

This directory contains `.toml` command definitions for the Gemini CLI. These files act as "shims" that map user-facing slash commands to the underlying procedures defined in `skills/`.

## Command Structure

Every command file should follow this standard format to ensure consistency and proper agent behavior:

```toml
# AUTO-GENERATED from .ai/skills/<name>/SKILL.md — do not edit by hand.
description = "Concise description of the command's purpose."

prompt = """
Load `.ai/skills/<name>/SKILL.md` and execute its
procedure. Read `.ai-local/project.yaml` first to resolve paths,
personas, and rules. Follow the numbered Steps in `SKILL.md`
exactly — do not improvise.

Arguments: {{args}}
"""
```

### Key Requirements
*   **Agnostic Logic**: Do not put procedural logic in the `prompt` field. Always refer the agent to the corresponding `SKILL.md`.
*   **Standard Header**: Include the `# AUTO-GENERATED` comment to distinguish these from manual configuration.
*   **Mandatory Context**: Always instruct the agent to read `project.yaml` and follow the numbered steps in the skill file.
*   **Input Handling**: Use the `{{args}}` placeholder to pass user input into the skill.

## Consistency Check
When adding a new command, ensure:
1. The `description` matches the one in the skill's frontmatter.
2. The `prompt` explicitly names the persona(s) and skill file.
3. The filename matches the skill folder name (e.g., `skills/ask/` -> `ask.toml`).
