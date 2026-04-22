---
name: create-plan
description: Turn an approved spec into a phased implementation plan using templates/plan.md. The plan inherits id, related.brief, and related.spec from the spec automatically. Does not start implementation.
---

## Inputs

- Path to a spec in `<paths.specs>/active/` with
  `status: approved`.

## Personas

1. `architect` — owns the spec and is responsible for the
   plan's phase shape.
2. `implementer` — owns the plan from this point forward; takes
   over when `implement` is first invoked.

## Rules loaded

From `.ai/project.yaml`: all entries under `rules.load`. Do not
hardcode paths. If `project.yaml` is missing or malformed, stop
and ask.

## Steps

1. **Orient.** Read `.ai/project.yaml`. Load the spec. Require
   `status: approved`; if anything else, stop and surface. Load
   the architect and implementer personas and the loaded rules.
   Resolve `paths.plans`.

2. **Derive id and target path (architect).** Copy `id` from the
   spec's frontmatter. Target plan path is
   `<paths.plans>/active/YYYY-MM-DD-<id>.md` using today's date.
   If a plan already exists at that path, stop and surface — do
   not overwrite.

3. **Phase the work (architect).** Break the spec's scope into
   phases. Every phase must end in a working, testable state —
   pausing after any phase must leave the app runnable. Write
   concrete, user-observable tasks as checkboxes under each
   phase.

4. **Architecture Pre-flight (architect).** Before creating the
   plan artifact, the architect must perform a final validation
   pass. Read every rule file loaded via `rules.load` (global
   and stack-specific). Verify that every proposed file path,
   naming convention, and structural decision in the phases
   above matches the project's established standards. If a
   divergence is found, the architect must correct the phases
   or escalate the rule conflict before proceeding.

5. **Create the plan from the template (architect).** Copy
   `.ai/templates/plan.md` into place. Populate frontmatter:
   - `id` copied from the spec;
   - `type: plan`, `status: draft`, `owner: implementer`;
   - `related.brief` copied from the spec's `related.brief`;
   - `related.spec` set to the spec path;
   - `progress: { total: <checkbox count>, done: 0,
     current_phase: 1 }`.
   Put the 🔄 marker on the first task of Phase 1. Populate the
   Rule compliance checklist with the rule files that actually
   matter for this plan, plus any gates the spec calls out.

5. **Refresh the dashboard.** Invoke `refresh-docs` —
   by reading `.ai/skills/refresh-docs/SKILL.md` and
   executing its procedure inline. Skill-invoking-skill has
   no standard cross-tool mechanism, so "invoke" means
   running that procedure here. Satisfies the dashboard-
   refresh invariant in `rules/global/04-doc-lifecycle.md`
   for the plan-creation event.

6. **Hand off to the implementer.** Leave the plan at
   `status: draft`. `implement` promotes it to
   `in-progress` on its first invocation against the plan.
   Surface the plan path.

## Outputs

- `<paths.plans>/active/YYYY-MM-DD-<id>.md` — a draft plan
  referencing the spec and brief by path.
- No edits to the spec or the brief.
