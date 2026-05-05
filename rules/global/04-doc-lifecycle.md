# Document lifecycle

State machines, archival rules, and pause discipline for every
generated doc.

## State machines

| Type      | States                           | Owner           |
| --------- | -------------------------------- | --------------- |
| brief     | draft → approved                 | product-analyst |
| spec      | draft → in-review → approved     | architect       |
| plan      | draft → in-progress → done       | implementer     |
| test-plan | draft → approved                 | tester          |
| adr       | proposed → accepted → superseded | architect       |

Transitions move forward only. A doc does not roll back to a
prior state — rework after approval is captured by a new doc or
a superseding ADR, not a status reversion.

## Approval signals

- A brief is approved when its frontmatter `status` is manually
  edited to `approved`, or when a skill is invoked with an
  explicit `approve=<brief-path>` argument. Both signals are
  accepted; no other signal counts.
- A spec is approved via the architect's normal review flow
  (`draft → in-review → approved`). The approver is a human
  reviewer or a reviewer persona when one exists.
- An ADR is accepted when `status` is flipped from `proposed` to
  `accepted`.

## Frontmatter updates

Any skill that modifies a doc's frontmatter bumps the `updated`
field to the current date. All other frontmatter fields are
preserved unless the skill explicitly changes them. This keeps
the dashboard's `Updated` column meaningful and lets downstream
tooling (including `refresh-docs`) rely on `updated` as a
monotonic recency signal.

## Dashboard refresh

Any skill that creates, modifies, or transitions a doc under
`active/` must invoke `refresh-docs` within the same
invocation. This includes status transitions in frontmatter
(e.g. `draft → approved`, `in-progress → done`), not just file
creation or body edits. The dashboard is the single source of
truth for "what's in flight"; a mutation that doesn't refresh
leaves the dashboard lying about state.

`archive-plan` is the reference pattern: its Step 7 reads
`.ai/skills/refresh-docs/SKILL.md` and executes the
procedure inline, because skill-invoking-skill has no standard
cross-tool mechanism. Other doc-touching skills
(`create-spec`, `create-plan`, and any future
skill that writes to `active/`) follow the same pattern.

Read-only skills — ones that inspect but do not mutate any
`active/` doc — are exempt. `integrity-check` is a read-only
skill by design; its Outputs section says so explicitly.

## Independent Plans (Fast Track)

For tasks that are well-defined, low-risk, or do not introduce significant architectural drift (e.g., minor UI tweaks, simple API integrations, or standalone features), an **Independent Plan** is permitted.

- **Criteria**: A plan may proceed without a linked `brief` or `spec` if the requirements and design are simple enough to be captured entirely within the plan's `Summary` and `Architecture` sections.
- **Metadata**: In an independent plan, `related.brief` and `related.spec` should be set to `null`.
- **User Request**: If a user provides a direct instruction to implement a feature via a plan, the agent should not block for a missing spec, but instead ensure the plan itself contains the necessary context.

## Plan Persistence (Project First)

To ensure that implementation plans are portable across different machines and persisted in the repository, Gemini CLI is configured at the project level to create plans directly in `docs/plans/active`.

- **Direct Creation**: All plans drafted via Plan Mode or the `create-plan` skill are natively written to `docs/plans/active/YYYY-MM-DD-<id>.md`.
- **No Temporary Storage**: Developers should not rely on temporary or local-only storage for plans. If a plan is created in a temporary directory, it MUST be moved to the project's permanent `active/` directory before implementation begins.
- **Commit Mandate**: Draft and in-progress plans MUST be committed to version control alongside the implementation they describe.

---

## Archive cascade (on plan done)

When a plan's `status` flips to `done`, the transition happens
in a single invocation of `archive-plan`. The invariant the
cascade upholds:

> After archive cascade, no trace of the completed feature
> remains in any `active/` folder.

The cascade archives whatever the plan's frontmatter declares
via `related.*` — nothing more, nothing less:

- The plan is always archived.
- The spec is archived iff `related.spec` is non-null.
- The brief is archived iff `related.brief` is non-null.
- The test plan is archived iff `related.test_plan` is non-null.
- The transient `open-questions` file for the plan's slug is merged into the archived artifacts and deleted.
- `related.*` paths in moved files are rewritten from
  `active/` to `archive/` (null values stay null).
- `<paths.index>` is regenerated via `refresh-docs`.
- ADRs are left in place. ADRs never archive.

A null `related.*` value is a legitimate declaration that no
such artifact exists (e.g. a plan with inline requirements). It
is not an error and does not block archival.

`archive-plan` stops and surfaces the inconsistency when a
_declared_ (non-null) `related.*` path cannot be found on disk,
or when any target `archive/` already contains a file of the
same name. Partial archives are worse than a failed archive —
they leave `active/` in a state that misleads the dashboard.

## ADRs never archive

Accepted ADRs are immutable history. Supersession is handled by
writing a new ADR that sets `supersedes: <old-id>` in its
frontmatter and flipping the old ADR's `status` to `superseded`.
The old file stays in place.

## Pause discipline on plans

A plan is paused when the implementer stops work with tasks
incomplete. Every pause appends a one-line entry to the plan's
`## Notes` section:

```
_YYYY-MM-DD: <code state>; next: <actionable step>; branch: <name>._
```

No entry = the plan is broken. Resumption depends on this line.
A pause without Notes is a regression against this rule.
