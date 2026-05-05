---
name: memory-remember
description: Store durable insights, technical decisions, and user preferences into the unified memory system.
---
# skill: memory-remember

Store durable insights, technical decisions, and user preferences into the unified memory system.

## Usage

Use this skill when you've reached a technical milestone, made a significant architectural decision, or received explicit feedback from the user.

## Tools

- `journal_append(content)`: Append a thought or action to the daily activity journal.
- `crystallize_insights(repo_name, topic, content)`: Save a permanent project-specific insight to the repository for team sharing.

## Procedure

1. **Crystallize Insight:** Formulate the discovery or decision as a concise Markdown block.
2. **Determine Scope:**
    - If it's a transient action, it's already logged by the shim.
    - If it's a durable fact or preference, use `journal_append`.
    - If it's a **significant technical decision or architectural pattern** that should be shared with the team, use `crystallize_insights`.
3. **Execute Sharing:** 
    - Identify the correct `repo_name` (e.g., "beep-gemini-sandbox").
    - Provide a concise `topic` slug.
    - Write the `content` in clear Markdown.
4. **Committing:** After crystallizing, remind the user to commit and push the new `.ai-memory/` file to share it with the team.

## Guidelines

- **Fact, not status:** Don't record that a test is currently red. Record *why* it was failing and how it was fixed permanently.
- **Privacy First:** Apply `08-secrets-and-data.md`. Never store secrets or PII.
- **Brevity:** Keep entries focused. One entry per significant insight.
