---
name: memory-recall
description: Search and retrieve relevant memories, decisions, and patterns from the unified memory system.
---
# skill: memory-recall

Search and retrieve relevant memories, decisions, and patterns from the unified memory system.

## Usage

Use this skill when you need to understand the context of a task, find past decisions, or recall user preferences.

## Tools

- `recall(query)`: Search for past insights and actions.

## Procedure

1. **Identify Keywords:** Extract key technical terms, project names, or concepts from the current task.
2. **Execute Recall:** Call `recall` with a concise query.
3. **Analyze Results:** Review the returned snippets.
    - If a clear decision is found, cite it in your plan.
    - If conflicting information is found, ask the user for clarification.
4. **Integration:** Incorporate the recalled context into your current reasoning and implementation strategy.

## Guidelines

- **Always search before starting:** Make it a habit to check the memory at the beginning of a complex task.
- **Hybrid Search:** The system uses both semantic and keyword matching (as of Phase 2).
- **Scope Awareness:** Differentiate between global preferences and project-specific technical decisions.
