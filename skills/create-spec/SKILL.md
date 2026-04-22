---
name: create-spec
description: Turn a product requirement from the user into a technical spec via a brief (product-analyst) and a spec plus any ADRs (architect). The skill pauses after the brief for explicit approval before the architect takes over.
---

## Inputs

- A product requirement in the user's own words (free text,
  ticket link, Slack excerpt, etc.).
- Optional, on resume: `approve=<brief-path>` — an explicit
  signal that a drafted brief is approved and the architect
  should proceed.

## Personas

1. `product-analyst` (from `.ai/personas/product-analyst.md`) —
   drafts the brief.
2. `architect` (from `.ai/personas/architect.md`) — drafts the
   spec and authors ADRs. Invoked only after the brief is
   approved.

## Rules loaded

From `.ai/project.yaml`:

- All entries in `rules.load`, in order. Later entries override
  earlier by filename.
- `personas.ownership` for doc-type → persona mapping.

Skills never hardcode paths. If `project.yaml` is missing or
malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai/project.yaml`. Load the rules in
   `rules.load` and the two personas. Resolve `paths.briefs`,
   `paths.specs`, `paths.decisions`.

2. **Draft the brief (product-analyst).** Derive a lowercase-
   kebab `<slug>` from the requirement. Create
   `<paths.briefs>/active/YYYY-MM-DD-<slug>.md` from
   `.ai/templates/brief.md`. Fill Problem, Users, Scope (in and
   out), Acceptance criteria, Success metrics, Open questions.
   Frontmatter: `id: <slug>`, `type: brief`, `status: draft`,
   `owner: product-analyst`, `created` and `updated` set to
   today.

3. **Refresh the dashboard (post-brief).** Invoke
   `refresh-docs` — by reading
   `.ai/skills/refresh-docs/SKILL.md` and executing its
   procedure inline. Skill-invoking-skill has no standard
   cross-tool mechanism, so "invoke" means running that
   procedure here. This satisfies the dashboard-refresh
   invariant in `rules/global/04-doc-lifecycle.md` for the
   brief-creation event, which is otherwise separated from the
   spec-side refresh by the approval pause.

4. **Pause for approval.** Append to the brief's `## Notes`
   section: `_YYYY-MM-DD: Awaiting approval before architect
   drafts spec._` Confirm `status: draft`. Stop. Tell the user:
   the brief is at `<path>`; approval is signalled either by
   editing the frontmatter to `status: approved`, or by
   re-invoking this skill with `approve=<brief-path>`. Both
   paths are accepted; no other signal counts.

5. **Verify approval (on resume).** Load the brief. Require
   `status: approved` in frontmatter, or the caller passing
   `approve=<brief-path>`. If neither, stop and surface. When
   only the approve flag was passed, flip the brief's
   `status` to `approved` and bump `updated` before continuing.

6. **Rule Freshness Audit (architect).** Before drafting the
   spec, the architect must perform a final check of the
   loaded rules against their current internal knowledge of
   the stack's best practices. If the rules mandate a legacy
   or deprecated library, the architect stops and flags the
   discrepancy to the user, proposing a modern alternative.

7. **Draft the spec (architect).** Load the architect persona.
   Create `<paths.specs>/active/YYYY-MM-DD-<slug>.md` from
   `.ai/templates/spec.md`. Copy `id` from the brief. Fill
   Scope, Approach, Data model, Interfaces, Alternatives
   considered, Open questions. Frontmatter: `type: spec`,
   `status: draft`, `owner: architect`, `related.brief` set to
   the brief path.

7. **Author ADRs (architect).** For every load-bearing or
   non-obvious decision made while drafting, create
   `<paths.decisions>/NNNN-<decision-slug>.md` from
   `.ai/templates/adr.md`. NNNN is the next monotonic integer
   after the highest existing ADR (left-padded to 4 digits).
   Set `related.spec` to the spec path. Append each ADR's id to
   the spec's `related.decisions` list.

8. **Refresh the dashboard (post-spec).** Invoke
   `refresh-docs` inline, as in Step 3. Covers the spec
   creation, brief approval transition, and any ADR additions
   in one refresh before hand-off.

9. **Hand off.** Leave the spec at `status: draft`. Surface the
   spec path and any ADR ids. Promotion to `in-review` and
   `approved` happens through the architect's review flow, not
   inside this skill. Plan creation is done by `create-plan`.

## Outputs

- `<paths.briefs>/active/YYYY-MM-DD-<slug>.md` — brief, `draft`
  on first invocation, promoted to `approved` on resume with the
  approve signal.
- `<paths.specs>/active/YYYY-MM-DD-<slug>.md` — spec, `draft`
  after resume.
- Zero or more `<paths.decisions>/NNNN-<slug>.md` — ADRs
  authored alongside the spec.
