# Security Review — <feature, spec, or change reference>

**Reviewer:** security-reviewer
**Input:** <spec path | plan path | PR URL | diff reference>
**Related ADRs:** <NNNN, NNNN — or "none, flagged" if a
load-bearing decision is pending>
**Date:** YYYY-MM-DD
**Verdict:** approve | change-required | block

A security review is a report. If the review produces a
load-bearing decision (new primitive, changed session lifetime,
new secret-storage boundary, changed trust boundary), the
architect authors an ADR that the verdict links to — the review
itself does not persist as a lifecycle artefact.

## Threat model

A stated threat model is mandatory. A review without one is a
style review.

### Assets

What is worth protecting in the scope of this change
(credentials, user data, payment tokens, session state, device
storage, audit logs).

- …

### Actors

Who could attack, and from where.

- **Unauthenticated internet** — …
- **Authenticated user (own account)** — …
- **Authenticated user (other account)** — …
- **Malicious insider** — …
- **Compromised device** — …

### Capabilities

What each actor can do (send crafted input, intercept network
traffic, read device storage, replay requests, access logs).

- …

### Out of scope

Explicit list of threats this review does not cover. Silence
will be read as approval if not stated here.

- …

## Asset lifecycles

For each asset in the threat model, name where it is created,
passed, stored, logged, and destroyed within the change. Gaps
in the lifecycle become findings.

- **<asset>** — created at `<location>`, stored in `<primitive>`,
  logged `<never | redacted | full>`, destroyed at `<location
or trigger>`.

## Findings

Each finding: location, rule or sanctioned primitive at stake,
proposed fix, classification.

### Block

Cannot ship as designed.

- **`<file>:<line>` or `<spec section>`** — <issue>. Rule:
  `<rules path>`. Fix: <change>.

### Change-required

Must be addressed before merge; design does not need to change.

- **`<file>:<line>`** — <issue>. Rule: `<path>`. Fix: <change>.

### Advisory

Observations for the author. Non-blocking.

- …

## Decisions

ADRs produced by this review, with one-line summaries. Full
context lives in the ADRs themselves under `<paths.decisions>/`.

- **ADR NNNN — <title>** — <one-line summary>.

## Out-of-scope reminder

Restate what this review did not cover. Stated here so approval
is not read as blanket.

- …

## Next action

One line naming the next concrete step to resolve the verdict
(e.g. "address the one block finding and re-run the skill," or
"architect to author ADR NNNN before merge").
