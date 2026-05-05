---
name: review
description: Unified entry point for all review types. Analyzes context and delegates to review-doc, review-change, or runs security-review in parallel. Consolidates findings into a single response.
---

## Inputs

- Context to review (e.g., paths to markdown files, code changes, diffs).

## Personas

1. `reviewer` — analyzes context and delegates to the appropriate review type.
2. `security-reviewer` — runs in parallel to check for vulnerabilities.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core` and
any relevant entries from `rules.contextual`.

## Steps

1. **Orient.** `reviewer` analyzes the provided inputs and the active context.
2. **Resolve Intent.** If the context is ambiguous or equally matches multiple review types, stop and explicitly ask the user for clarification before proceeding. Do not guess.
3. **Parallel Execution.**
   - If the inputs are markdown documentation, delegate internally to the `review-doc` process.
   - If the inputs are code changes or diffs, delegate internally to the `review-change` process.
   - **Simultaneously**, invoke the `security-reviewer` to perform a parallel check for vulnerabilities. Utilize sub-agents if available for efficiency.
4. **Consolidation.** Wait for all parallel reviews to finish. Combine the findings from the primary review (doc or change) and the security review into a single, cohesive, and structured markdown response. Ensure no findings are lost.
5. **Deliver.** Output the consolidated review to the user. Do not modify the reviewed files.

## Outputs

- A single markdown review document containing both the primary review and any parallel security findings.
