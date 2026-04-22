---
id: NNNN                    # monotonic, left-padded to 4 digits
type: adr
status: proposed            # proposed → accepted → superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: architect
supersedes: null            # ADR id this replaces, or null
related:
  spec: <path to the spec that motivated this ADR, or null>
---

# NNNN — <Decision title>

## Context

What prompted this decision. The problem, the constraints, the
forces in tension. Enough detail for a future reader to
understand why we needed to decide anything here.

## Decision

The decision, stated plainly. One paragraph is often enough.
Implementation detail belongs in the spec — an ADR records the
decision, not the mechanics.

## Status

`proposed` | `accepted` | `superseded by NNNN`

When superseding an earlier ADR, set `supersedes` in this ADR's
frontmatter to the old id, and flip the old ADR's status to
`superseded`.

## Consequences

What becomes easier. What becomes harder. What trade-offs we
are accepting. Include knock-on effects on other parts of the
system.
