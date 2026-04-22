---
id: <feature-slug>          # copied from the spec
type: test-plan
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: tester
related:
  brief: <path under briefs/ if the spec links one>
  spec:  <path under specs/active or specs/archive>
  plan:  <path under plans/active if a plan exists, else null>
---

# <Feature> — Test Plan

## Scope

Which parts of the spec this plan covers and which are
deliberately deferred. A deferred area must name the reason
(out of scope for this milestone, covered by a separate plan,
not testable at this level) — silence is not an answer.

## Behaviours

Numbered list of user-observable behaviours traced from the
spec. Each line: `B<N> — <short description>`. Behaviours that
the spec does not fully specify are moved to **Open questions**,
not paraphrased.

- B1 — …
- B2 — …

## Tests by level

For each test entry: behaviour id(s), the failure mode it
catches, and the file path the test will live at per the
stack's colocation rules. A test that cannot name a failure
mode is not a test.

### Unit

- `<path>` — covers B<N>. Catches: <failure mode>.

### Component

- `<path>` — covers B<N>. Catches: <failure mode>.

### Integration

- `<path>` — covers B<N>. Catches: <failure mode>.

### End-to-end

- `<path>` — covers B<N>. Catches: <failure mode>.

## Fixtures and harnesses

Shared test utilities, factories, mocks, and environments this
plan depends on. If a new harness is required, mark it **NEW**
so the implementer plans it rather than assuming it exists.

- …

## Open questions

Questions the tester cannot resolve alone. Each line names the
escalation target (architect for spec gaps,
security-reviewer for security-relevant coverage,
implementer for structure that is untestable as written). Must
be resolved before the test plan is treated as `approved`.

- …
