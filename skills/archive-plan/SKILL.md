---
name: archive-plan
description: Atomically archive a done plan along with whatever related artifacts its frontmatter declares. Guarantees that after running, no trace of the completed feature remains in any active/ folder. Fails loudly rather than partially archiving.
---

## Guarantee

After this skill runs successfully, no file belonging to the
completed feature remains under any `active/` folder. The
feature's plan — and whatever spec / brief its frontmatter
declares via `related.*` — are all in `archive/`, and the
dashboard reflects that.

The common case is plan + spec + brief, optionally plus a test
plan. Plans with inline requirements (null `related.brief`,
`related.spec`, and/or `related.test_plan`) are legitimate and
supported: the skill archives only what the plan actually
declares.

## Inputs

- Path to a plan in `<paths.plans>/active/` with `status: done`.

## Personas

None. The skill is mechanical. Its behaviour is scripted, not a
judgment call.

## Rules loaded

From `.ai/project.yaml`: `paths.*`. Invariants are defined in
`rules/global/04-doc-lifecycle.md` (read for reference, not
interpreted). If `project.yaml` is missing or malformed, stop
and ask.

## Steps

1. **Orient.** Read `.ai/project.yaml`. Resolve `paths.briefs`,
   `paths.specs`, `paths.plans`, `paths.index`,
   `paths.decisions`.

2. **Read the plan.** Open the plan. Require `status: done`;
   otherwise stop and surface. Extract `related.brief`,
   `related.spec`, and `related.test_plan` from its frontmatter.

3. **Build the archive list.** Assemble the list of files the
   skill will move:
   - The plan, always.
   - The spec, iff `related.spec` is non-null.
   - The brief, iff `related.brief` is non-null.
   - The test plan, iff `related.test_plan` is non-null.

   A null `related.*` value is a declaration that no such
   artifact exists, not a missing file. It does not block
   archival.

4. **Verify preconditions (preflight).** All checks run
   before any file is moved. If any fail, the skill stops
   without moving any file. The goal is to catch every
   realistic cause of mid-sequence failure up front so Step 5
   is as close to atomic as the filesystem allows:
   - Every file in the archive list exists at its declared
     `active/` path. A *declared* path (non-null) that is
     missing from disk is a real inconsistency — fail loudly.
   - Every source file in the list is readable.
   - Every target `archive/` directory exists and is
     writable.
   - No file of the same name already exists in the matching
     `archive/` directory for any file in the list.

5. **Move files.** All-or-nothing in intent. The preflight in
   Step 4 is designed to catch the realistic causes of
   mid-sequence failure. Real atomicity across multiple
   filesystem moves is not guaranteed by the OS without
   staging + swap logic, which is more complexity than this
   use case warrants; the skill does not attempt automatic
   rollback. If a move nonetheless fails mid-sequence despite
   preflight, surface the failure along with which files have
   already moved and which haven't, so the tree can be
   reconciled by hand. Do not attempt further moves. Move in
   this order (skipping any not in the list):
   1. Plan:      `<paths.plans>/active/<f>`  → `<paths.plans>/archive/<f>`.
   2. Test plan: `<paths.plans>/active/<f>`  → `<paths.plans>/archive/<f>`.
   3. Spec:      `<paths.specs>/active/<f>`  → `<paths.specs>/archive/<f>`.
   4. Brief:     `<paths.briefs>/active/<f>` → `<paths.briefs>/archive/<f>`.

6. **Update cross-references.** In the moved plan's
   frontmatter, rewrite every non-null `related.*` path that
   still points into `active/` to the new `archive/` location.
   Null values stay null. Bump `updated` to today. Do not
   change any other field (especially `id` and `status`). If
   the spec or brief was moved and itself has `related.*`
   pointers into `active/`, rewrite those too by the same
   rule.

7. **Refresh the dashboard.** Invoke `refresh-docs` —
   by reading `.ai/skills/refresh-docs/SKILL.md` and
   executing its procedure inline. Skill-invoking-skill has no
   standard cross-tool mechanism, so "invoke" means running
   that procedure here. If the procedure cannot be executed,
   surface the failure — do not silently continue.

8. **Leave ADRs alone.** Do not touch `<paths.decisions>/`.

## Outputs

- Every file the plan's frontmatter declared (plan, and
  spec/brief/test-plan when non-null) moved from `active/` to
  `archive/`, frontmatter updated.
- A regenerated `<paths.index>`.
- No changes to ADRs, rules, personas, or any Stage 1 artifact.
