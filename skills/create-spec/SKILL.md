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
3. `designer` (from `.ai/personas/designer.md`) — invoked in
   parallel with the architect to generate ASCII mockups if the
   task involves UI changes.

## Rules loaded

From `.ai-local/project.yaml`:

- All entries in `rules.core`, in order.
- Relevant entries from `rules.contextual` (specifically `03-documentation.md` and `04-doc-lifecycle.md`).
- `personas.ownership` for doc-type → persona mapping.

Skills never hardcode paths. If `project.yaml` is missing or
malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Load the `rules.core` baseline and required `rules.contextual` files. Load the personas. Resolve `paths.briefs`,
   `paths.specs`, `paths.decisions`.

2. **Draft the brief (product-analyst).** Derive a lowercase-
   kebab `<slug>` from the requirement. Create
   `<paths.briefs>/active/YYYY-MM-DD-<slug>.md` from
   `.ai/templates/brief.md`. Fill Problem, Users, Scope (in and
   out), Acceptance criteria, Success metrics, Open questions.
   Create `docs/open-questions/YYYY-MM-DD-<slug>.md` from
   `.ai/templates/open-questions.md` for transient questions.
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

6. **Open Questions Gate.** Check `docs/open-questions/YYYY-MM-DD-<slug>.md`.
   If it exists and contains unanswered questions, halt and warn
   the user. You must not proceed until all questions are answered.
   Merge any answered questions into the brief or spec as appropriate.

7. **Rule Freshness Audit (architect).** Before drafting the
   spec, the architect must perform a final check of the
   loaded rules against their current internal knowledge of
   the stack's best practices. If the rules mandate a legacy
   or deprecated library, the architect stops and flags the
   discrepancy to the user, proposing a modern alternative.

8. **Draft the spec (architect + designer).** Load the architect
   and designer personas in parallel. Create
   `<paths.specs>/active/YYYY-MM-DD-<slug>.md` from
   `.ai/templates/spec.md`. Copy `id` from the brief. Fill
   Scope, Approach, Data model, Interfaces, Alternatives
   considered, Open questions. If the task involves UI changes,
   the designer appends an "ASCII Mockup" section. Frontmatter:
   `type: spec`, `status: draft`, `owner: architect`,
   `related.brief` set to the brief path.

9. **Author ADRs (architect).** For every load-bearing or
   non-obvious decision made while drafting, create
   `<paths.decisions>/NNNN-<decision-slug>.md` from
   `.ai/templates/adr.md`. NNNN is the next monotonic integer
   after the highest existing ADR (left-padded to 4 digits).
   Set `related.spec` to the spec path. Append each ADR's id to
   the spec's `related.decisions` list.

10. **Refresh the dashboard (post-spec).** Invoke
    `refresh-docs` inline, as in Step 3. Covers the spec
    creation, brief approval transition, and any ADR additions
    in one refresh before hand-off.

11. **Hand off.** Leave the spec at `status: draft`. Surface the
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
