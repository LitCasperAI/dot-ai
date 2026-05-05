# Design Rationale — BEEP AI Scaffold

This document explains the "why" behind the scaffold's architecture. It is the source of truth for the design principles that govern how agents and humans collaborate within this system.

## 1. Separation of Concerns: Personas vs. Rules

The scaffold distinguishes between **how a role acts** and **what the technology is**.

*   **Personas (`personas/`)**: Define the discipline, tone, and decision-making framework of a role (e.g., `architect`, `implementer`). They are stack-agnostic. An `architect` in a Node.js project should have the same high-level rigour as an `architect` in a Rust project.
*   **Rules (`rules/`)**: Define the technical constraints and idioms of the environment. Rules are where the specific knowledge of a framework or organizational standard lives.

**Rationale**: This allows us to scale to new technologies without redefining what it means to be a "Senior Engineer" (Persona) every time.

## 2. The Immutable Submodule Pattern

The `.ai/` directory is designed to be a read-only git submodule in consumer repositories.

*   **Global/Stack Logic**: Lives in the submodule.
*   **Local Overrides**: Live in `.ai-local/`.

**Rationale**: To prevent consumer projects from diverging from organizational standards in a way that makes the scaffold unupdatable. By forcing overrides into `.ai-local/`, we ensure that `git submodule update` remains a safe operation.

## 3. Intent-Based Routing (The Review Loop)

The scaffold is built around an iterative, artifact-driven lifecycle: **Brief → Spec → Plan → Implementation**.

*   **Review-First**: Every transition between artifacts (e.g., Spec to Plan) requires a `/review` step.
*   **Strategy-First**: Implementation cannot start without an approved Plan.

**Rationale**: AI agents are prone to "drift" or "hallucination" during long execution phases. By breaking the workflow into small, reviewable increments, we keep the human in the loop at critical decision points and prevent costly rework.

## 4. Contract-First Documentation

Every artifact (Brief, Spec, Plan) has a strict frontmatter schema and section contract defined in `templates/`.

**Rationale**: Agents rely on structure. By enforcing a consistent "shape" for documents, we enable skills to parse and update artifacts (like the `progress` counter in a Plan) with high reliability across different LLM providers.

## 5. Skills as Portable Procedures

Skills (`skills/`) are tool-agnostic Markdown procedures.

**Rationale**: Whether you use Claude Code, Gemini CLI, or a future tool, the core "Step 1, Step 2" logic remains the same. The `.gemini/commands/` or `.claude/commands/` folders are merely thin entry points that point back to the source-of-truth `SKILL.md`.
