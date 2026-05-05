# Intent Routing & Ambiguity Resolution

This rule governs how the AI agent should interpret and route generic or conversational user prompts (e.g., "Let's update feature X", "I want to add a new button").

## Routing Guidelines

1. **Evaluate Intent:** Before taking action, evaluate the user's prompt against the available skills in `.ai/skills/` and the current state of the workspace.
2. **Suggest Appropriate Skill:** If the prompt clearly aligns with a specific phase of the workflow (e.g., a feature request should start with `create-brief` or `create-spec`), suggest or implicitly invoke that skill.
3. **Do Not Guess:** If the prompt is ambiguous, vague, or equally matches multiple skills (e.g., "review this" could mean `review-doc` or `review-change`), you MUST stop and ask the user for clarification. Do not guess their intent.
4. **Explicit Escalation:** If a request falls entirely outside the capabilities of the current scaffolding, explicitly state this limitation to the user and ask how they would like to proceed.

## Dynamic Rule Loading

To optimize context and maintain high signal-to-noise ratio, follow these loading rules:

1. **Core Only by Default:** Only files in `rules.core` (defined in `project.yaml`) are guaranteed to be in your active context at session start.
2. **Load on Alignment:** When a task involves a specific domain, you MUST proactively load relevant contextual rules from `rules.contextual`. Examples:
   - **Testing/Refactoring:** Load `06-testing.md`.
   - **New Feature/Doc:** Load `03-documentation.md` and `04-doc-lifecycle.md`.
   - **API/Library Change:** Load `07-dependencies.md`.
   - **UI Work:** Load `10-design-system.md`.
3. **Check for Project Overrides:** Always check if a contextual rule has a matching filename in `.ai-local/rules/` before acting on the global version.
