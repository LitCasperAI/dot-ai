---
name: memory-dream
description: Collaborative cleanup and promotion cycle to distill raw activity into high-signal team insights.
---

# skill: memory-dream

The "Dreaming" process bridges the gap between raw, verbatim activity logs (Level 4) and permanent, shared project insights (Level 5). It allows the agent to reflect on recent work, identify significant patterns, and "crystallize" them for the team.

## Personas

1. `implementer` — retrieves raw logs and identifies technical patterns.
2. `reviewer` — evaluates insights for long-term value and technical accuracy.

## Rules loaded

From `project.yaml`: `rules.core`, plus `14-memory-protocol.md` and `08-secrets-and-data.md`.

## Steps

1. **Retrieve (implementer):** Fetch the last 24 hours of raw activity using the `get_recent_logs` tool.
2. **Reason (implementer + reviewer):** 
    - Analyze the logs to identify technical decisions, architectural shifts, non-obvious bug fixes, or new project conventions.
    - Filter out "noise": transient errors, typos, routine builds, or failed experiments.
    - Group related events into logical topics.
3. **Crystallize (reviewer):** 
    - For each high-signal topic, formulate a concise Markdown insight.
    - Focus on the **rationale** (the "Why") and the **solution** (the "How").
    - Ensure the content follows Rule 14 (objectivity, no personal context).
4. **Persist:**
    - Call the `crystallize_insights` tool for each topic to save it to the repository's `.ai-memory/` directory.
5. **Share:**
    - Remind the user to commit and push the new `.ai-memory/*.md` files so the whole team benefits from the "dreamed" insights.

## Outputs

- Permanent Markdown files in the repository under `.ai-memory/`.
- Updated semantic index in the memory server (automatic).
