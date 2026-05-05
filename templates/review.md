# Code Review — <PR title or change reference>

**Reviewer:** reviewer (+ security-reviewer / tester if activated)
**Change:** <PR URL, branch, or commit range>
**Linked spec / plan / ADR:** <path or "none — flagged">
**Date:** YYYY-MM-DD
**Verdict:** approve | request changes | block

A review is a report, not a lifecycle artefact. It may be posted
to the PR as a single structured comment or kept alongside the
change for the record — the skill does not require it to be
committed to the repo.

## Summary

One paragraph. The reviewer's overall position and the reason
in one or two sentences. If the verdict is "block," name the
one thing that, if resolved, would change the verdict.

## Blocking

Comments that prevent merge. Each entry:

- **`<file>:<line>`** — <one-line issue>. Rule: `<rules path or
principle>`. Fix: <smallest correct change>.

If there are no blocking comments, write "None." explicitly —
silence is not the same as approval.

## Change requests

Comments that must be addressed before merge but do not block
the merge gate (they will be resolved in the same PR cycle).

- **`<file>:<line>`** — <issue>. Rule: `<path>`. Fix: <change>.

## Suggestions

Nits, preferences, or style observations. Non-blocking.

- **`<file>:<line>`** — <observation>.

## Security

> Include only if `security-reviewer` was activated.

One paragraph stating the threat model this review was run
against, followed by findings prefixed `[security]`. A finding
that is also classified as blocking appears in both sections —
the security section gives the rationale, Blocking lists the
gate.

## Tests

> Include only if `tester` was activated.

Findings prefixed `[test]`. For each changed behaviour that
lacks a test, name the behaviour and the test that should
exist. Coverage-gap findings that block merge also appear
under Blocking.

## Plan honesty

> Include only if the change links to a plan under
> `<paths.plans>/active/`.

Discrepancies between the plan and the diff:

- Checkbox mismatch: <task that is checked without code, or
  coded without a check>.
- Progress counters stale: total=<n>, done=<n>, expected=<n>.
- 🔄 marker: <absent | on wrong task | correct>.
- Notes entry: <missing | stale | current>.

## Next action

One line naming the next concrete step the author must take to
resolve the verdict (e.g. "address the two blocking comments
and push an update; no re-review needed for the suggestions").
