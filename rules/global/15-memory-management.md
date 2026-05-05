# Memory management

Rules for using the agent's persistent memory tools (e.g., `save_memory`) vs. formal documentation.

## Memory vs. Documentation

1. **Formal Artifacts (docs/):** Use markdown files in `docs/` (ADRs, Specs, Plans) for all architectural decisions, project requirements, and technical designs that must be shared with the team and tracked in version control.
2. **Persistent Memory (save_memory):** Use the `save_memory` tool for personal, local, or session-bridging context that does not belong in the repository.
   - **Project Scope:** Local dev environment quirks, preferred shell commands, specific file paths often visited, and current working context that isn't yet a "plan".
   - **Global Scope:** User communication preferences, general coding style preferences (unless overridden by project rules), and machine-specific configuration.

## Guidelines for Memory

- **No Secrets in Memory:** Never save API keys, passwords, or PII to memory.
- **Fact-Based:** Save specific facts ("The dev server is at port 3001", "User prefers verbose explanations") rather than broad summaries of work.
- **Avoid Redundancy:** Do not save information to memory that is already explicitly stated in `project.yaml` or the rules.
- **Memory Cleanup:** If a fact saved in memory becomes obsolete (e.g., the dev server port changes), update it immediately.
- **Inquiry for Memory:** If you are unsure if a preference should be global or project-specific, use `ask_user`.
