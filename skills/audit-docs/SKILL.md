---
name: audit-docs
description: Sweep the docs tree (briefs, specs, plans, test plans, ADRs, design system) for staleness, missing pieces, contradictions, and orphaned artefacts. Produces a Markdown audit report classified Block / Drift / Info, each finding citing a rule. Read-only — proposes fixes, edits nothing.
---

## Inputs

- Optional: `scope=<path>` to narrow the audit to a single
  directory under `<paths.briefs|specs|plans|decisions>` or to
  the design-system docs only. Default scope is every doc path
  declared in `project.yaml`.
- Optional: `stale-after=<N>` to override the default staleness
  threshold for `active/` documents (default: 30 days since
  `updated`).

## Personas

1. `auditor` (from `.ai/personas/auditor.md`, plus any
   `.ai/overrides/<stack>/auditor.md`). Primary, in **Docs
   mode**.
2. `architect` — consulted when the audit finds a spec or ADR
   that requires structural change. The auditor surfaces; the
   architect resolves.
3. `product-analyst` — consulted when the audit finds a brief
   in need of rework.
4. `designer` — consulted when the audit finds drift in the
   design-system documents.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core`,
particularly `global/03-documentation.md` and
`global/04-doc-lifecycle.md` (which are in `rules.core`), 
plus any relevant entries from `rules.contextual`. The audit 
cites those rules — it does not invent its own contract.

If `project.yaml` is missing or malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Resolve `paths.briefs`,
   `paths.specs`, `paths.plans`, `paths.decisions`,
   `paths.index`, `paths.design_system`, and
   `paths.design_system_global` (the last two may be absent on
   older projects — record one **Drift** finding and continue
   if so). Load the `auditor` persona, all `rules.core`, and 
   required `rules.contextual` files. Record the resolved 
   scope in the report.

2. **Enumerate the corpus.** Build the audit manifest:

   - Every `*.md` under `<paths.briefs>/active/` and
     `<paths.briefs>/archive/`.
   - Every `*.md` under `<paths.specs>/active/` and
     `<paths.specs>/archive/`.
   - Every `*.md` under `<paths.plans>/active/` and
     `<paths.plans>/archive/`.
   - Every `*.md` under `<paths.decisions>/`.
   - `<paths.design_system>` and
     `<paths.design_system_global>`, if declared.
   - `<paths.index>`.
     Filter by `scope` if supplied.

3. **Frontmatter contract checks (auditor).** For every doc
   except the design-system files and the index, parse YAML
   frontmatter and verify per `global/03-documentation.md`:

   - Required fields present (`id`, `type`, `status`,
     `created`, `updated`, `owner`).
   - `type` matches the directory the file lives in.
   - `status` is one of the values declared for that type in
     `global/04-doc-lifecycle.md`.
   - Filename matches the documented convention
     (`YYYY-MM-DD-<slug>.md` for briefs/specs/plans;
     `<slug>-tests.md` for test plans; `NNNN-<slug>.md` for
     ADRs).
   - `id` matches across a feature's brief / spec / plan /
     test-plan triple where they exist.
     Each violation → **Block**.

4. **Pointer-resolution checks (auditor).** For every non-null
   value under `related.*`, verify the path resolves on disk
   (string values) or the ADR id resolves to a file (list
   values). Broken pointer → **Block**. Null values are
   declarations of absence, not findings.

5. **Lifecycle and pause-discipline checks (auditor).** For
   every doc under `active/`:

   - **Plans**: verify `progress.total`, `progress.done`, the
     🔄 marker (present iff `status: in-progress`), and a
     `## Notes` entry per pause per
     `global/04-doc-lifecycle.md`. Mismatch → **Block**.
   - **Specs / briefs**: verify `status` is a forward state
     (no rolled-back values). Roll-back → **Block**.
   - **ADRs**: verify `supersedes` resolves when set, and the
     superseded ADR's `status` is `superseded`. Inconsistency
     → **Block**.

6. **Staleness checks (auditor).** For every `active/` doc
   whose `updated` is older than `stale-after` days:

   - **Plans** also missing a recent Notes entry → **Block**
     (the plan is broken per the pause rule).
   - **Briefs / specs** with no recent activity → **Drift**.
     The intent is to surface forgotten work, not to enforce
     activity quotas.

7. **Orphan and contradiction checks (auditor).** Cross-walk
   the corpus:

   - A spec whose `related.brief` is null and which sits in
     `active/` → **Drift** (probably orphaned; confirm with
     `architect`).
   - A plan whose `related.spec` is null → **Drift**.
   - A brief in `active/` with no spec referencing it →
     **Info** (may be pre-architect; flag with date).
   - A test plan whose `related.spec` doesn't match its
     sibling plan's `related.spec` → **Block**.
   - An ADR whose `related.spec` resolves to an archived spec
     while the ADR is `accepted` → **Info** (history is fine,
     just surface).

8. **Dashboard freshness check (auditor).** Read
   `<paths.index>`. If its "Last updated by agent" date is
   older than the most recent `updated` field in any
   `active/` doc → **Block** (the dashboard is lying per
   `global/04-doc-lifecycle.md`'s refresh invariant).

9. **Design-system checks (auditor + designer).** If
   `<paths.design_system>` and `<paths.design_system_global>`
   were declared:

   - Verify both files exist and are non-empty. Missing or
     empty → **Block**.
   - Scan the project doc for entries that contradict the
     global doc without a stated **Deviation** block →
     **Block**, escalated to `designer`.
   - Scan briefs and specs in `active/` for UI work that
     cites no design-system entry → **Drift**, escalated to
     `designer`.

10. **Compose the report.** Produce a Markdown document:

    ```markdown
    # Docs audit — YYYY-MM-DD

    **Scope:** <resolved scope>
    **Stale-after:** <N> days
    **Summary:** <blocks>/<drifts>/<infos> findings.

    ## Blocks

    _None._
    <or>

    - `<doc-path>` — <rule cited> — <one-line finding> —
      _fix:_ <smallest correct fix> — _owner:_ <persona>
    - ...

    ## Drift

    _None._
    <or>

    - ... (same shape)

    ## Info

    _None._
    <or>

    - ... (same shape)

    ## Coverage

    - briefs scanned: <n>
    - specs scanned: <n>
    - plans scanned: <n>
    - test plans scanned: <n>
    - ADRs scanned: <n>
    - design-system docs scanned: <n>
    ```

    `_None._` is the literal rendering when a section has no
    entries; the section is never omitted.

11. **Deliver.** Output the report to the user. Do not write
    it to disk unless the user explicitly asks for a saved
    copy. The audit is read-only by design and does not
    refresh the dashboard (see
    `global/04-doc-lifecycle.md` — the read-only exemption
    that covers `integrity-check` covers this skill too).

## Outputs

- A Markdown audit report delivered to the user's
  conversation. No files are created, modified, or deleted.
  No frontmatter is touched. No dashboard refresh.
- Findings routed to `architect`, `product-analyst`,
  `designer`, or `implementer` by the **owner** column. The
  audit identifies; owners resolve.
