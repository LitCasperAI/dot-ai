---
name: create-plan
description: Turn an approved spec into a phased implementation plan using templates/plan.md. The plan inherits id, related.brief, and related.spec from the spec automatically. Does not start implementation.
---

## Inputs

- Path to a spec in `<paths.specs>/active/` with
  `status: approved`. First invocation: drafts the plan and pauses
  for approval.
- `approve=<plan-path>` — resume signal. Re-invokes against an
  existing `<paths.plans>/active/` plan to verify/flip its
  `status: approved` and continue past the approval gate.

## Personas

1. `architect` — owns the spec and is responsible for the
   plan's phase shape.
2. `designer` (from `.ai/personas/designer.md`) — invoked in
   parallel to check UI aspects and ensure ASCII mockups are
   accounted for in the plan's tasks.
3. `implementer` — owns the plan from this point forward; takes
   over when `implement` is first invoked.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core` and
relevant entries from `rules.contextual` (specifically 
`03-documentation.md`, `04-doc-lifecycle.md`,
`16-vertical-slicing.md`, `17-tracker-integration.md`). Do not
hardcode paths. If `project.yaml` is missing or malformed, stop
and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Load the personas,
   all `rules.core`, and required `rules.contextual` files. Resolve
   `paths.plans`.

   - If invoked with `approve=<plan-path>`, this is a resume: load
     the plan at that path and skip to Step 9 (Verify approval).
   - Otherwise, load the given spec. Require `status: approved`; if
     anything else, stop and surface.

2. **Open Questions Gate.** Extract `id` and the date prefix from
   the spec path. Check `docs/open-questions/<YYYY-MM-DD>-<id>.md`.
   If it exists and contains unanswered questions, halt and warn
   the user. You must not proceed until all questions are answered.
   Merge any answered questions into the plan.

3. **Derive id and target path (architect).** Copy `id` from the
   spec's frontmatter. Target plan path is
   `<paths.plans>/active/YYYY-MM-DD-<id>.md` using today's date.
   If a plan already exists at that path, stop and surface — do
   not overwrite.

4. **Phase the work (architect + designer).** Break the spec's scope into
   phases. Every phase must end in a working, testable state —
   pausing after any phase must leave the app runnable. Write
   concrete, user-observable tasks as checkboxes under each
   phase. The designer ensures UI-related tasks explicitly reference
   ASCII mockups or design constraints from the spec. Per
   `16-vertical-slicing.md`, each phase's first line under its
   heading must be the one-sentence demoable-end-state statement,
   unless the phase is a declared wide-refactor exception.

5. **Architecture Pre-flight (architect).** Before creating the
   plan artifact, the architect must perform a final validation
   pass. Read every rule file loaded via `rules.core` and
   required `rules.contextual` (global and stack-specific).
 Verify that every proposed file path,
   naming convention, and structural decision in the phases
   above matches the project's established standards. Also verify
   each phase against `16-vertical-slicing.md`: a stated
   one-sentence demoable end state, no unrelated-layer spanning,
   and any horizontal phase explicitly declared as a wide-refactor
   exception. If a divergence is found, the architect must correct
   the phases or escalate the rule conflict before proceeding.

6. **Create the plan from the template (architect).** Copy
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

7. **Refresh the dashboard.** Invoke `refresh-docs` —
   by reading `.ai/skills/refresh-docs/SKILL.md` and
   executing its procedure inline. Skill-invoking-skill has
   no standard cross-tool mechanism, so "invoke" means
   running that procedure here. Satisfies the dashboard-
   refresh invariant in `rules/global/04-doc-lifecycle.md`
   for the plan-creation event.

8. **Pause for approval.** Append to the plan's `## Notes` section:
   `_YYYY-MM-DD: Awaiting approval before publishing/implementation._`
   Confirm `status: draft`. Stop here and tell the user the two
   accepted approval signals: editing `status: approved` by hand,
   or re-invoking `create-plan` with `approve=<plan-path>`.

9. **Verify approval (on resume).** Reached either by falling
   through from Step 8 on a later invocation, or directly from
   Step 1's `approve=<plan-path>` branch. Require `status: approved`
   or the `approve=` argument having been passed; if neither holds,
   stop and surface — the plan is not yet approved. When only the
   `approve=` flag was passed (frontmatter still `status: draft`),
   flip `status` to `approved` and bump `updated`. Continue to
   Step 10.

10. **Publish (architect).** Runs once, at the moment this
    invocation transitions the plan to `approved` in Step 9, and
    only when `project.yaml` declares a non-`local` `tracker:`
    block. Consult `17-tracker-integration.md` for the mechanism
    behind each operation named below.

    - If the plan's `tracker.phases` is non-empty already (a
      re-sync: this skill re-invoked against an already-approved,
      already-published plan), skip straight to the re-sync branch
      below instead of the fresh-publish sequence.

    **Fresh publish:**

    1. **Spec parent issue.** If the plan's `related.spec` points
       to a spec whose `tracker.issue` is null, Publish it now
       (title = spec's H1, body = spec's Scope + Approach sections,
       no parent). Write the returned `{id, url}` back into the
       spec's `tracker.issue` and bump the spec's `updated`. If the
       spec already has a `tracker.issue`, reuse it.
    2. **Phase child issues.** For each phase in the plan without a
       recorded `tracker.phases[].issue`, assign it a stable,
       position-independent `slug` if it does not already have one
       (write the slug into both the phase heading's trailing HTML
       comment and the frontmatter entry), then Publish an issue
       (title = phase heading text, body = that phase's task
       checkboxes verbatim, parent = the spec's issue id). Any
       phase whose heading names a prerequisite phase gets a
       `Blocked by: …` line via Link-blocked-by.
    3. **Write-back.** Record each phase's `{id, url}` into the
       plan's `tracker.phases` and the spec's issue into the plan's
       `tracker.parent`.

    **Re-sync** (already-approved plan with a non-empty
    `tracker.phases`): match phases by their stable `slug`. For
    phases that still exist, Update the linked issue's body from
    the current checkbox state. For phases new since the last sync
    (no `tracker.phases` entry), assign a slug and Publish a new
    issue as in step 2 above. Never recreate or duplicate an issue
    for an unchanged phase.

    On a `local`/absent tracker, this entire step is a documented
    no-op — except phase slugs are still assigned (frontmatter and
    heading comments populated) so a project that later configures
    a tracker has stable ids to sync from.

11. **Hand off to the implementer.** The plan is now at
    `status: approved`. `implement` promotes it to `in-progress` on
    its first invocation against the plan. Surface the plan path.

## Outputs

- `<paths.plans>/active/YYYY-MM-DD-<id>.md` — a draft plan
  referencing the spec and brief by path.
- No edits to the spec or the brief.
active/YYYY-MM-DD-<id>.md` — a draft plan
  referencing the spec and brief by path.
- No edits to the spec or the brief.
