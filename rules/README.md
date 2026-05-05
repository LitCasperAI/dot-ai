# Rules System

This directory contains the hierarchical constraints and procedures that govern AI agent behavior. The rules are designed to provide a balance between organization-wide standards and project-specific flexibility.

## The Rule Hierarchy

Rules are layered and loaded in the following order of precedence:

1.  **Global Rules (`rules/global/`)**: The baseline standards that apply to every project, regardless of tech stack.
2.  **Stack Rules (`rules/stacks/`)**: Technology-specific rules (e.g., Node.js, Rust, Terraform). These are loaded dynamically based on the `project.stacks` declared in `project.yaml`.
3.  **Project Rules (`.ai-local/rules/`)**: The highest priority. These are project-specific overrides that live in the consuming repository's `.ai-local/` directory.

## Replacement Logic

Rules are replaced by **filename**, not by merging. If a file exists in multiple layers (e.g., `06-testing.md`), the version in the highest-priority layer wins entirely. 

This mechanism ensures that a project can completely redefine a standard (like testing or version control) without needing to "undo" global logic.

## Naming Convention

Files follow the `NN-<topic>.md` pattern:
*   **`NN`**: A two-digit number for explicit load order (read top to bottom).
*   **`<topic>`**: A kebab-case description of the constraint or procedure.

## Loading Categories

Rules are loaded based on the context of the task:

*   **Core Rules (`rules.core`)**: Vital rules for intent routing, safety, and conduct. These are loaded at the start of every session.
*   **Contextual Rules (`rules.contextual`)**: Loaded on-demand when a task aligns with a specific domain (e.g., loading `03-documentation.md` when creating a new feature).

## Contributing

For instructions on how to add or modify rules, see the `README.md` within the `global/`, `stacks/`, or `project/` subdirectories.
