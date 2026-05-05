---
name: ask
description: Ask a question about the project's rules, terminology, architecture, or history and get a cited answer.
---

# Ask

## Inputs

- The question or topic you want to learn about.

## Personas

1. `librarian`

## Rules

Always load `rules.core` and `terminology/global.md`. Proactively load `rules.contextual` if the question relates to a specific domain (e.g., testing, deployment).

## Steps

1. **Discovery (`librarian`)**: 
   - Search `terminology/global.md` for keyword matches.
   - Search `<paths.decisions>/` (ADRs) for relevant architectural decisions.
   - Grep `rules/` for relevant constraints or procedures.
   - Search `<paths.specs>/archive/` if the question is about a specific historical feature.
2. **Synthesis (`librarian`)**: 
   - Provide a concise answer to the question.
   - **Mandatory:** Include citations (file paths and line numbers if possible) for every claim.
3. **Gap Analysis (`librarian`)**: 
   - If the answer is incomplete or missing from the documentation, explicitly label it as a "Knowledge Gap."
   - Suggest which file (e.g., a specific rule or the terminology list) should be updated to capture this information.
