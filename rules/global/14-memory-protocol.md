# Agnostic Memory Protocol

Rules for how AI agents (Gemini, Claude, etc.) should use the unified memory system in the Beep Hive sandbox.

## 1. Memory Tiers

| Tier | Purpose | Usage |
|---|---|---|
| **Journal** | Raw activity log. | Automatically populated by the sandbox shim. Do not edit manually unless correcting an error. |
| **Global** | User preferences & persona. | Read at session start. Update when the user gives explicit personal feedback. |
| **Project** | Architecture, quirks, decisions. | Read when entering a project. Update when a significant technical decision is made. |

## 2. Reading Memory (Recall)

- **Entry Point:** At the start of every task, call `recall()` with keywords related to the task (e.g., "authentication", "build system", "deployment").
- **Consistency:** Before proposing a solution, check if a similar task has been handled before to ensure architectural consistency.
- **Context Management:** Do not dump the entire memory into your context. Select the top 3-5 most relevant entries.

## 3. Writing Memory (Remember)

- **Automated:** Trust that the `shim` logs your commands. You don't need to manually log `git commit` or `mvn build`.
- **Crystallization:** At the end of a complex task, summarize the key findings or decisions.
- **Fact vs. Opinion:** Store durable facts ("Project uses Java 25") rather than transient states ("The build is currently red").
- **Privacy:** Never store secrets, tokens, or PII in the memory system. Apply the rules from `08-secrets-and-data.md`.

## 4. Shared Project Memory

- **In-Repo Storage:** If a memory is specific to the codebase and should be shared with other team members, suggest writing it to the `<repo-root>/.ai-memory/` directory.
- **Format:** Use Markdown with frontmatter for metadata:
  ```markdown
  ---
  topic: <slug>
  decision: <one-liner>
  date: YYYY-MM-DD
  agent: <name>
  ---
  <detailed explanation>
  ```

## 5. Tool Interaction

- Use `recall(query)` for searching.
- Use `journal_append(content)` for manual notes or observations.
- Always check for the existence of the `memory-server` before attempting to use it.
