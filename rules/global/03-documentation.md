# Documentation contracts

Every generated doc (brief, spec, plan, test-plan, ADR) follows
these contracts regardless of stack.

## Where docs live

- **Briefs** — `<paths.briefs>/active/` → `<paths.briefs>/archive/`.
- **Specs** — `<paths.specs>/active/` → `<paths.specs>/archive/`.
- **Plans** — `<paths.plans>/active/` → `<paths.plans>/archive/`.
- **Test plans** — `<paths.plans>/active/` → `<paths.plans>/archive/`.
  Test plans live alongside plans: they share the `id` of the
  plan or spec they cover, are filename-suffixed `-tests.md`,
  and archive with the plan via the cascade in
  `04-doc-lifecycle.md`.
- **ADRs** — `<paths.decisions>/` (flat, never archived).

Paths resolve from `.ai/project.yaml` under `paths:`. Never
hardcode `docs/…` in skills, rules, or tools.

## Filenames

- Briefs, specs, plans: `YYYY-MM-DD-<slug>.md`. The date records
  when the doc was created; it does not change on archival.
- Test plans: `YYYY-MM-DD-<slug>-tests.md`. The `<slug>` matches
  the spec or plan the test plan covers.
- ADRs: `NNNN-<slug>.md`, monotonically numbered from `0001`.
- Rule files: `NN-<topic>.md`, numbered for load order.

Slugs are lowercase-kebab and stable across a feature's brief,
spec, and plan.

## Shared id across a feature's docs

The frontmatter `id:` field is the stable link for a feature's
brief, spec, and plan. It does not change when files move
between `active/` and `archive/`. Filenames move; id stays.

- `create-spec` sets `id` on the brief and copies it
  to the spec.
- `create-plan` copies the id from the spec to the plan and
  fills `related.brief` and `related.spec`.

## Frontmatter — fields common to every doc type

```yaml
---
id: <slug-or-NNNN>          # slug for brief/spec/plan/test-plan; NNNN for ADR
type: brief | spec | plan | test-plan | adr
status: <see 04-doc-lifecycle.md>
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: <persona name>
related:                    # populated as links form; null otherwise
  brief:     <path>
  spec:      <path>
  plan:      <path>
  test_plan: <path>
  decisions: [NNNN, NNNN]
---
```

## Type-specific additions

- **Plans** carry `progress: { total, done, current_phase }`.
- **Test plans** carry `related.spec` (required) and
  `related.plan` (null if the test plan was authored ahead of a
  plan).
- **ADRs** carry `supersedes: NNNN | null`. `supersedes` is
  ADR-only. Briefs, specs, plans, and test plans do not use it.

## Owners by doc type

| Type      | Owner           | Authoring skill                      |
| --------- | --------------- | ------------------------------------ |
| brief     | product-analyst | create-spec                          |
| spec      | architect       | create-spec                          |
| plan      | implementer     | create-plan                          |
| test-plan | tester          | design-tests                         |
| adr       | architect       | create-spec (or ad-hoc by architect) |

When `project.yaml` declares `personas.ownership`, that
declaration is authoritative and overrides this table where they
differ.
