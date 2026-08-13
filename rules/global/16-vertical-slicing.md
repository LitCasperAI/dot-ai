# Vertical slicing

Governs how `create-plan` phases a spec's scope, and how
`review-doc` checks that phasing. Stack-agnostic.

## Definition

A phase is a vertical slice when it can be described in one
sentence as a user-observable, independently demoable end state,
and it does not span layers that belong to an otherwise-unrelated
concern. "Add the field to the schema, wire it through the API,
and render it" is one slice if it's one field end-to-end. "Do the
schema for every field" is a horizontal slice and is disallowed as
a whole phase.

Each phase's first line under its heading must state that
one-sentence demoable end state, unless the phase is a declared
wide-refactor exception (below).

## Sizing heuristic

Aim for a phase whose implementation fits a single fresh context
window — a qualitative anchor of ~100k tokens, chosen to sit inside
the model's reliable "smart zone" rather than its hard context
limit. This is guidance for the architect during phasing, not a
mechanically enforced token count.

## Wide-refactor / expand-contract exception

A phase may be horizontal only when it is a mechanical,
blast-radius-wide change with no meaningful vertical decomposition
(e.g. a rename across 40 files, an expand-contract migration step).
Such phases must say so explicitly in their phase heading or first
task — "Wide-refactor phase: ..." — so `review-doc` and future
readers don't mistake it for an oversight.
