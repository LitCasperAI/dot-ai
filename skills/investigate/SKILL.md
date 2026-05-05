---
description: Run a critical technical investigation into a specific topic, refactor, or library replacement, producing a Spec and/or ADR.
---

# Investigate

## Inputs

- The topic, library, or architectural pattern to investigate.

## Personas

1. `architect`

## Rules

Follow the `rules.core` baseline and proactively load relevant 
rules from `rules.contextual` via `project.yaml`. Be highly critical 
of existing implementations if they contradict modern best 
practices for the active stack.

## Steps

1. **Context Gathering (`architect`)**: Read the user's provided 
   topic. Read `.ai-local/project.yaml`, load `rules.core` and 
   required `rules.contextual` files. Use search tools to locate 
   relevant code, configurations, and existing rules within the 
   workspace to understand the current implementation.
2. **Critical Evaluation (`architect`)**: Evaluate the topic against current industry best practices and the established rules for the active stack. Consider:
   - **Library Comparison**: If investigating a library replacement, compare the current library against the proposed alternative across performance, security, maintenance activity, and bundle size.
   - **Architectural Fit**: Evaluate if the proposed pattern aligns with the existing system boundaries and principles defined in `global/01-principles.md`.
   - **Abstraction Cost**: Push back explicitly if an idea adds unnecessary abstraction overhead or complexity without a clear, measurable benefit.
3. **Draft Findings (`architect`)**: Draft a new Spec in `<paths.specs>/` detailing the investigation's findings, alternative approaches considered, and the recommended technical approach. If the recommendation involves a significant, load-bearing architectural change, draft a corresponding ADR in `<paths.decisions>/`.
