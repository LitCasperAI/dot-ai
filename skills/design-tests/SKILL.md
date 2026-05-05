---
name: design-tests
description: Turn an approved spec or an in-progress plan into a test plan the implementer can execute against. Names the tests that must exist by level (unit, component, integration, end-to-end), cites the behaviours each covers, and identifies failure modes. Does not write the test code — that belongs to implement.
---

## Inputs

- One of:
  - Path to a spec in `<paths.specs>/active/` with
    `status: approved`.
  - Path to a plan in `<paths.plans>/active/` whose
    `related.spec` points at an approved spec.
- Optional: a scope filter (`phase=N`, `area=<slug>`) to limit
  the test plan to part of the spec.

## Personas

1. `tester` (from `.ai/personas/tester.md`, plus any
   `.ai/overrides/<stack>/tester.md`). Primary.
2. `architect` — consulted if the spec has gaps that prevent
   test design. `tester` does not fill the gaps; it surfaces
   them to the architect.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core`,
plus relevant entries from `rules.contextual` (specifically 
`06-testing.md` and the stack's testing rule file). The test 
plan enforces those rules — query conventions, mocking posture, 
test-level choices — rather than inventing its own.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Load the spec (directly
   or via the plan's `related.spec`). Require spec
   `status: approved`; if anything else, stop and surface. Load
   the `tester` persona, all `rules.core`, and required 
   `rules.contextual` files. Resolve `paths.plans`.

2. **Enumerate behaviours (tester).** Walk the spec's scope
   section. For each user-observable behaviour, write one line:
   `<behaviour-id> — <short description>`. Behaviours that are
   underspecified are surfaced as an **Open questions** list
   and escalated to `architect` — do not invent acceptance
   criteria.

3. **Assign test levels (tester).** For each behaviour, name
   the lowest honest level that proves it:

   - **Unit** — pure logic, helpers, reducers.
   - **Component** — rendered UI given props, queried by role or
     label per the stack's testing rules.
   - **Integration** — multiple units wired together, real
     services exercised where
     `global/06-testing.md` requires it.
   - **End-to-end** — a user journey that must be proven
     against the running app.
     A behaviour may appear at more than one level if the risk
     warrants it; justify the duplication in one line.

4. **Name failure modes (tester).** For each behaviour, name at
   least one way it could break and the test that would catch
   the break. "Happy path only" is not accepted. Examples: auth
   denies a valid user, validation accepts malformed input,
   pagination loses an item on reorder.

5. **Identify fixtures and harnesses (tester).** List the
   shared test utilities, factories, mocks, and environments
   the plan needs. If a new harness is required (new E2E flow
   runner, new factory, new mock boundary), flag it — it is
   work the implementer plans, not work the tester assumes
   exists.

6. **Cross-check against the rules (tester).** For every test
   named, verify it complies with the loaded testing rules:
   query priorities, mocking boundaries, colocation, no-snapshot
   rules, etc. A test the plan cannot comply with is redesigned,
   not excepted.

7. **Compose the test plan.** Produce a Markdown document
   structured as:

   - **Scope** — one paragraph, which parts of the spec are
     covered and which are deferred.
   - **Behaviours** — numbered list from step 2.
   - **Tests by level** — four subsections (unit, component,
     integration, end-to-end). Each test entry names: the
     behaviour id, the level, the failure mode it catches, and
     the file path the test will live at per the stack's
     colocation rules.
   - **Fixtures and harnesses** — from step 5.
   - **Open questions** — from step 2, if any.

8. **Write the test plan from the template.** Test plans are
   always standalone files, per `global/03-documentation.md`.
   Copy `.ai/templates/test-plan.md` to
   `<paths.plans>/active/YYYY-MM-DD-<id>-tests.md` and
   populate:

   - `id` copied from the spec;
   - `type: test-plan`, `status: draft`, `owner: tester`;
   - `related.brief` copied from the spec;
   - `related.spec` set to the spec path;
   - `related.plan` set to the plan path if one was the input,
     otherwise `null`.

9. **Back-link from the plan (if a plan was the input).** Set
   the plan's `related.test_plan` to the test-plan path and
   bump the plan's `updated`. Do not alter phases, checkboxes,
   or other frontmatter fields.

10. **Refresh the dashboard.** Invoke `refresh-docs` by
    reading `.ai/skills/refresh-docs/SKILL.md` and
    executing its procedure inline, per
    `global/04-doc-lifecycle.md`. Surface the test-plan path.

## Outputs

- A standalone test plan at
  `<paths.plans>/active/YYYY-MM-DD-<id>-tests.md`, authored
  from `.ai/templates/test-plan.md`.
- A back-link on the plan's `related.test_plan` if a plan was
  the input.
- **Open questions** surfaced to `architect` if the spec had
  gaps. The skill does not close gaps by guessing.
- No test code. Writing the tests is `implement`'s job,
  working against this plan.
