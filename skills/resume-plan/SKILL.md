---
name: resume-plan
description: Pick up an in-progress plan and hand off to implement with context preloaded. Finds the 🔄 marker, reads the latest Notes entry, loads the referenced brief and spec. Does not itself implement.
---

## Inputs

- Path to a plan file in `<paths.plans>/active/` with
  `status: in-progress` (or `draft`, which this skill promotes).
- Optional: a specific phase or task to jump to. If omitted,
  the cursor is derived from the 🔄 marker and the latest Notes
  entry.

## Personas

1. `implementer` (from `.ai/personas/implementer.md`). This
   skill's job is to resolve the cursor and hand off — it does
   not itself write code or tick checkboxes.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core` and
relevant entries from `rules.contextual`. Do not
hardcode paths. If `project.yaml` is missing or malformed, stop
and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Load all `rules.core` 
   and required `rules.contextual` files. Load the plan. If
   `status: done`, stop — there is nothing to resume. If
   `status: draft`, promote to `in-progress` and bump `updated`.

2. **Load related context.** Resolve `related.brief` and
   `related.spec` from the plan's frontmatter. Read both in
   full. If either points into `archive/` while the plan is in
   `active/`, stop and surface — the state is inconsistent.

3. **Locate the cursor.** Find the 🔄 marker. If absent, use the
   first unchecked task in the earliest incomplete phase. If the
   plan's `## Notes` section has a more recent entry that names
   a different next step than the marker implies, prefer the
   Notes entry and flag the divergence to the user.

4. **Surface the context.** Announce the plan path, the resolved
   cursor (task + phase), the latest Notes entry, and the branch
   name it references (if any). Ask the user to confirm before
   proceeding — the right branch may not be checked out.

5. **Hand off to `implement`.** On confirmation, invoke
   the `implement` skill with the plan path. From this
   point, `implement` owns the writing, the checkbox
   flips, the 🔄 marker moves, and the Notes entries on pause.

## Outputs

- No doc changes in this skill, except the optional
  `draft → in-progress` promotion from step 1 (plus the bumped
  `updated`).
- All further artifacts come from `implement`.
