---
name: audit-structure
description: Sweep the codebase (folder layout, component shape, module boundaries, test colocation) for divergences from the loaded stack rules. Produces a Markdown audit report classified Block / Drift / Info, each finding citing a rule. Read-only — proposes fixes, edits no source.
---

## Inputs

- Optional: `scope=<path>` to narrow the audit to a directory
  (e.g. `src/features/auth`). Default scope is the source root
  declared by the stack's folder-structure rule.
- Optional: `stack=<name>` to force a stack when a project lists
  more than one in `project.stacks`. Default is to audit each
  enabled stack in turn.

## Personas

1. `auditor` (from `.ai/personas/auditor.md`, plus any
   `.ai/overrides/<stack>/auditor.md`). Primary, in **Structure
   mode**.
2. `architect` — consulted when a structural finding implies a
   spec or ADR is needed (e.g. a feature that should graduate
   into `common/` or `core/`).
3. `designer` — consulted when a component-shape finding
   touches a design-system entry.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core`,
plus any rule from `rules.contextual` relevant to the requested
audit scope (e.g. stack layout and component rules). The audit 
cites specific rule files and sections — it does not invent 
its own layout opinions.

If `project.yaml` is missing or malformed, stop and ask.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Resolve `paths.*` and
   `project.stacks`. Load the `auditor` persona, all `rules.core`, 
   and required `rules.contextual` files. Record the resolved 
   scope and the stacks being audited in the report.

2. **Identify the source root and the structural contract.**
   For each stack in scope, read its
   `05-folder-structure.md`. Extract:

   - The top-level layout the stack declares
     (e.g. `src/app`, `src/core`, `src/common`, `src/features`).
   - The boundary rules (what may import what).
   - The barrel and naming conventions.
   - Any "what does not live where" prohibitions.
     These become the structural contract this audit enforces.

3. **Walk the source tree (auditor).** Enumerate every file
   and directory under the source root, filtered by `scope`.
   For each entry, record its path, kind (file or directory),
   and the structural slot it occupies under the contract.

4. **Top-level layout checks (auditor).** Verify every
   directory at the source root maps to a slot the contract
   names. An unrecognised top-level directory → **Block**.
   A missing required top-level directory (one the contract
   names but the repo does not have) → **Drift** if the repo
   simply hasn't needed it yet, **Block** if rules cite it as
   load-bearing.

5. **Boundary checks (auditor).** Walk imports per the
   stack's import-boundary rules:

   - Cross-feature imports (e.g.
     `features/checkout` importing from
     `features/billing`) → **Block**, unless the import
     resolves through the importing feature's barrel.
   - Imports of feature internals that bypass the barrel
     (e.g. `features/auth/components/LoginForm` rather than
     `features/auth`) → **Block**.
   - Imports from `common/` or `core/` that reference a
     specific feature → **Block** (the file in `common/` or
     `core/` does not belong there).
   - Production code importing `test-utils` → **Block**.

6. **Component / module shape checks (auditor).** For each
   stack, read its `08-component-conventions.md` (RN/Next) or
   `08-module-conventions.md` (Node) and verify:

   - File naming (`<Name>Screen.tsx`, etc.) matches.
   - Required wrappers (e.g. `Screen` for RN screens) are
     present.
   - Public surface (barrel `index.ts`) exists where the
     contract requires it.
   - Forbidden patterns (e.g. screens in `common/components/`,
     I/O in `common/utils/`) are absent.
     Each violation → **Block**, citing the specific rule.

7. **Test colocation checks (auditor).** For each behavioural
   source file, verify a colocated test exists per the
   stack's `02-testing.md`. Missing colocated test → **Drift**
   (the audit does not block on coverage; the test plan and
   review do). A parallel `__tests__/` tree where the rule
   forbids one → **Block**.

8. **Asset and binary checks (auditor).** Verify binary
   assets sit only where the stack rule allows
   (e.g. `src/assets/` for RN). Stray binaries elsewhere →
   **Block**.

9. **Design-system alignment (auditor + designer).** If
   `<paths.design_system>` is declared and the stack has UI:

   - Scan `common/components/` and feature components for
     entries that duplicate something already in the design
     system → **Drift**, escalated to `designer`.
   - Scan for inline tokens (raw hex colours, magic spacing
     values) where the stack uses a theme system → **Drift**,
     escalated to `designer`.

10. **Compose the report.** Produce a Markdown document:

    ```markdown
    # Structure audit — YYYY-MM-DD

    **Scope:** <resolved scope>
    **Stacks:** <stacks audited>
    **Summary:** <blocks>/<drifts>/<infos> findings.

    ## Blocks

    _None._
    <or>

    - `<file-or-dir>` — <rule cited> — <one-line finding> —
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

    - directories scanned: <n>
    - files scanned: <n>
    - import statements analysed: <n>
    - components analysed: <n>
    ```

    `_None._` is the literal rendering when a section has no
    entries; the section is never omitted.

11. **Deliver.** Output the report to the user. Do not edit
    any source file. The audit is read-only by design.
    Findings owned by `implementer` are the implementer's to
    resolve in a follow-up plan or PR; findings owned by
    `architect` may require a spec change or ADR.

## Outputs

- A Markdown audit report delivered to the user's
  conversation. No source files are created, modified, or
  deleted.
- Findings routed to `implementer`, `architect`, or
  `designer` by the **owner** column. Recurring patterns that
  look like missing rules are surfaced for the team that
  owns the relevant rules directory.
