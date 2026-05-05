---
name: review-doc
description: Review a brief, spec, plan, test plan, or ADR for clarity, completeness, internal consistency, and rule alignment. Produces a structured review with blocking comments, change requests, and suggestions — each tied to a rule or principle. Distinct from review-change, which reads diffs.
---

## Inputs

- Path to the doc to review. One of:
  - A brief in `<paths.briefs>/active/` or
    `<paths.briefs>/archive/`.
  - A spec in `<paths.specs>/active/` or
    `<paths.specs>/archive/`.
  - A plan or test plan in `<paths.plans>/active/` or
    `<paths.plans>/archive/`.
  - An ADR in `<paths.decisions>/`.
- Optional: a target status (`approve`, `request-changes`,
  `block`) the reviewer is biased toward, used only to surface
  the bias to the user; the review itself is formed from the
  document, not the bias.

## Personas

1. `reviewer` (from `.ai/personas/reviewer.md`, plus any
   `.ai/overrides/<stack>/reviewer.md`). Primary.
2. `architect` — consulted on spec or ADR reviews when the
   finding implies a structural change.
3. `product-analyst` — consulted on brief reviews when the
   finding is in scope, users, or acceptance criteria.
4. `tester` — consulted on test-plan reviews when behaviours,
   levels, or fixtures are in question.
5. `designer` — consulted on briefs / specs / plans whose
   scope includes a UI surface and which lack design notes.
6. `security-reviewer` — consulted on briefs / specs / plans
   that touch auth, PII, payments, cryptography, session, or
   secret storage. The doc reviewer surfaces the trigger; the
   security-reviewer runs `security-review` separately.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core`,
particularly `global/03-documentation.md` (frontmatter and
filename contracts), `global/04-doc-lifecycle.md` (states,
approvals, archival), and any relevant rule file from 
`rules.contextual` the doc itself cites.
The review cites specific rule files and sections — it does not
summarise "the rules" generically.

If `project.yaml` is missing or malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Resolve `paths.*`. Load
   the `reviewer` persona, all `rules.core`, and required 
   `rules.contextual` files. Load the doc to review.

2. **Frontmatter and lifecycle pass (reviewer).** Verify the
   doc satisfies `global/03-documentation.md` and
   `global/04-doc-lifecycle.md`:

   - Required frontmatter fields present and valid.
   - Filename matches the documented convention.
   - `status` is a state declared for this type, and the doc
     is in a directory consistent with that state
     (e.g. an `archived` plan does not sit in `active/`).
   - `related.*` pointers resolve on disk; null values are
     allowed where the contract permits absence.
   - For plans: progress counters, the 🔄 marker, and Notes
     entries match `04-doc-lifecycle.md`'s pause discipline.
     Each violation → **Blocking**.

3. **Type-specific content pass (reviewer + owner persona).**
   Open the doc and read end to end before commenting.

   - **Brief** (consult `product-analyst`): scope is in/out,
     users are named concretely, acceptance criteria are
     user-observable, success metrics are one or two and
     measurable, open questions are listed honestly.
   - **Spec** (consult `architect`): scope, approach, data
     model, interfaces, alternatives, and open questions all
     present; load-bearing decisions either captured inline
     with reasoning or linked to an ADR.
   - **Plan** (consult `architect` for design alignment;
     `tester` if `related.test_plan` is non-null): phases are
     ordered so each ends in a runnable state; acceptance
     criteria from the spec map onto checkboxes; no scope
     beyond the spec; one current 🔄 marker if in-progress.
   - **Test plan** (consult `tester`): every behaviour from
     the spec covered, level chosen is the lowest honest one,
     each test names a failure mode, fixtures and harnesses
     identified.
   - **ADR** (consult `architect`): context, decision,
     consequences, alternatives all stated; `supersedes`
     populated correctly if it replaces an earlier ADR;
     `related.spec` set when motivated by a spec.

   Each gap → **Blocking** (a missing required section) or
   **Change-request** (a present-but-weak section).

4. **Internal consistency pass (reviewer).** Walk the doc for
   contradictions:

   - A spec whose Approach implements something not in Scope.
   - A plan whose phases don't cover every acceptance
     criterion in the spec.
   - A test plan whose Behaviours list doesn't match the
     spec's Acceptance criteria.
   - An ADR whose Decision contradicts a still-accepted
     earlier ADR without superseding it.
     Each contradiction → **Blocking**.

5. **Cross-doc alignment pass (reviewer).** Compare the doc
   to the artefacts it links via `related.*`:

   - A spec whose `related.brief` exists and is `approved`
     but whose Scope diverges from the brief's Scope →
     **Blocking**.
   - A plan whose `related.spec` is `draft` (not `approved`)
     → **Blocking** per `04-doc-lifecycle.md`.
   - A test plan whose `related.spec` is `draft` →
     **Blocking**.
   - A doc whose `related.decisions` lists ADRs that are
     `superseded` without acknowledgement → **Change-request**.

6. **Design pass (designer, if activated).** Activated when
   the doc's scope mentions UI, screens, components, or any
   surface a user sees. Verify:

   - Design notes section present, citing entries from
     `<paths.design_system>` and / or
     `<paths.design_system_global>`.
   - Accessibility floors named in user-observable terms.
   - Any new component proposed has a stated reason it cannot
     reuse an existing design-system entry.
     Append findings prefixed `[design]`.

7. **Security pass (security-reviewer trigger, if
   activated).** Activated when the doc's scope touches auth,
   PII, payments, cryptography, session handling, or secret
   storage. The doc reviewer does not run the security
   review here — instead, it records a **Blocking** finding
   that requires `security-review` to be run against this
   doc before approval. This keeps the two skills' outputs
   distinct and traceable.

8. **Compose the review.** Produce a Markdown document:

   ```markdown
   # Doc review — <doc-path> — YYYY-MM-DD

   **Reviewer position:** approve | request-changes | block
   **Reason:** <one paragraph>

   ## Blocking

   _None._
   <or>

   - <section / line> — <rule cited> — <finding> —
     *fix:* <smallest correct fix>
   - ...

   ## Change requests

   _None._
   <or>

   - ... (same shape)

   ## Suggestions

   _None._
   <or>

   - ... (same shape)

   ## Design

   _Not activated._
   <or>

   - [design] ... (same shape)

   ## Security

   _Not activated._
   <or>

   - [security] Run `security-review` against this doc
     before approval — <reason>.
   ```

   `_None._` and `_Not activated._` are literal renderings;
   sections are never omitted.

9. **Deliver.** Output the review to the user. Do not edit
   the reviewed doc. Do not change its `status` — promotion
   is the owning persona's call, informed by this review.
   The review is read-only with respect to the working tree.

## Outputs

- A Markdown review document delivered to the user's
  conversation. No files are created, modified, or deleted.
- Conditional escalation triggers: `security-review` when
  step 7 fired, `designer` enrichment when step 6 fired,
  owner-persona rework when blocking findings exist.
