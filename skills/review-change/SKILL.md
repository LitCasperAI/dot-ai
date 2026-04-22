---
name: review-change
description: Review a pull request or local change against the loaded rules and the change's linked spec, plan, or ADR. Produces a structured review with blocking comments, change requests, and suggestions — each tied to a rule or principle. Activates security-reviewer and tester conditionally based on what the diff touches.
---

## Inputs

- One of:
  - A pull request reference (URL or number) the agent can read
    via the project's git host tooling.
  - A local diff reference (e.g. `HEAD`, a branch name, or a
    commit range like `main...HEAD`).
- Optional: path to the brief, spec, plan, or ADR that motivated
  the change. If the PR description names one, the skill uses
  that; otherwise the skill attempts to infer from the plan in
  `<paths.plans>/active/` whose `id` matches the branch.

## Personas

1. `reviewer` (from `.ai/personas/reviewer.md`, plus any
   `.ai/overrides/<stack>/reviewer.md`). Primary.
2. `security-reviewer` (conditional) — activated when the diff
   touches auth, authorisation, PII, payments, cryptography,
   session handling, or secret storage. Activation is determined
   by a keyword and path scan in step 3.
3. `tester` (conditional) — activated when the diff changes
   behaviour without corresponding test changes, or when test
   coverage for a changed critical path is missing.

## Rules loaded

From `.ai/project.yaml`: all entries under `rules.load`. The
review cites specific rule files and sections — it does not
summarise "the rules" generically. If `project.yaml` is missing
or malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai/project.yaml`. Resolve `paths.*`. Load
   every rule file listed under `rules.load`. Load the
   `reviewer` persona.

2. **Acquire the change (reviewer).** Fetch the PR description
   and diff, or resolve the local diff reference. If the change
   is more than cosmetic and has no linked brief/spec/plan/ADR,
   record that as the first blocking comment and continue — the
   review proceeds, but the absence is flagged.

3. **Scan for escalations (reviewer).** Inspect the diff for
   triggers:
   - **Security**: changes under auth paths, anything importing
     crypto or secure-storage libraries, changes to token
     handling, session lifetime, or redaction helpers, new
     logging of request bodies or headers.
   - **Test**: any behavioural change (non-comment, non-doc) in
     `src/` without a corresponding test change in the same
     change set.
   Record which escalations are active; they inform steps 5 and
   6.

4. **Review the diff top to bottom (reviewer).** Read the diff
   in full before writing any comment. For each comment:
   - Point at a specific file and line range.
   - Name the rule file or principle at stake
     (`global/06-testing.md`, `stacks/<stack>/01-constraints.md`,
     etc.).
   - Propose the smallest correct fix.
   Separate comments into three buckets: **blocking** (rule
   violation), **change-request** (must address but does not
   block the merge gate), **suggestion** (nit, preference, or
   style).

5. **Security pass (security-reviewer, if activated).** Load
   `.ai/personas/security-reviewer.md`. State the threat model
   the change is reviewed against in one paragraph. Check use of
   sanctioned primitives, input validation at trust boundaries,
   log redaction, and error-path privilege checks per
   `global/08-secrets-and-data.md` and the stack's rules. Append
   findings to the review, prefixed `[security]`.

6. **Test pass (tester, if activated).** Load
   `.ai/personas/tester.md`. For each changed behaviour without
   a corresponding test, record a blocking comment naming the
   behaviour and the test that should exist. Check that failure
   modes are covered, not just the happy path. Append findings
   prefixed `[test]`.

7. **Plan honesty check (reviewer).** If the change links to a
   plan in `<paths.plans>/active/`, verify:
   - The plan's checkboxes match the diff (no completed work
     left unchecked, no checked work missing from the diff).
   - `progress.total`, `progress.done`, and `updated` reflect
     reality.
   - The 🔄 marker is on the correct task, or absent if the plan
     is complete.
   - A Notes entry exists if the plan was paused.
   Record discrepancies as blocking comments.

8. **Compose the review.** Produce a single Markdown document
   structured as:
   - **Summary** — one paragraph, the reviewer's overall
     position (approve / request changes / block) with the
     reason.
   - **Blocking** — bulleted list, each item referencing the
     file, line, and rule.
   - **Change requests** — same structure.
   - **Suggestions** — same structure.
   - **Security** — present only if `security-reviewer` was
     activated.
   - **Tests** — present only if `tester` was activated.
   - **Plan honesty** — present only if a plan was linked.

9. **Deliver.** Output the review document to the user. Do not
   post to the git host without explicit user approval —
   `global/02-agent-conduct.md` treats PR comments as shared-state
   actions. If the user approves posting, use the project's git
   host tooling to submit the review as a single structured
   comment, not a stream of inline posts.

## Outputs

- A Markdown review document, delivered to the user.
- No edits to any file in the repo. The skill is read-only with
  respect to the working tree.
- Optionally, a posted review on the PR if the user explicitly
  approves the post in step 9.
