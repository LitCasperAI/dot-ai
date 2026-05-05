# Terminology — global

Shared vocabulary for any agent working in this repo. When a term
appears here, use it as defined. Do not invent synonyms, and do
not silently widen a term's scope.

Two sections:

1. **Scaffold terms** — words the `.ai/` scaffold itself uses.
   These are authoritative across every project that installs the
   scaffold.
2. **Domain terms — Your Company** — starter vocabulary for the
   company domain. Teams extend this as
   product language stabilises. When a domain term here conflicts
   with product documentation, product documentation wins and
   this file is updated.

---

## Scaffold terms

- **Agent** — any AI coding tool operating in this repo (Claude
  Code, Gemini CLI, Codex, Copilot, Cursor, etc.). Agents read
  `AGENTS.md` first.
- **Persona** — a stack-agnostic role under `.ai/personas/`
  (architect, implementer, reviewer, …). Describes how a role
  _operates_, not what the stack _is_.
- **Rule** — a numbered file under `.ai/rules/` (or `.ai-local/rules/`)
  that constrains how work is done. `rules.core` are always loaded;
  `rules.contextual` are loaded on-demand based on task alignment.
  Precedence: `project` (`.ai-local/rules/`) > `stacks` > `global` by
  same-filename replacement.
- **Skill** — a user-invokable procedure under `.ai/skills/`,
  one folder per skill containing a `SKILL.md`. Skills are
  invoked by slash-command (e.g. `/implement`).
- **Brief** — product framing of a requirement. Owned by
  product-analyst. Lives under `paths.briefs`.
- **Spec** — technical specification derived from a brief. Owned
  by architect. Lives under `paths.specs`.
- **Plan** — phased implementation plan derived from a spec.
  Owned by implementer. Lives under `paths.plans`. Carries
  `progress: { total, done, current_phase }`.
- **Test plan** — list of tests covering a spec or plan, named by
  level and failure mode. Owned by tester. Filename suffix
  `-tests.md`. Archives with its plan.
- **ADR** — Architecture Decision Record. Owned by architect.
  Flat-numbered `NNNN-<slug>.md` under `paths.decisions`. Never
  archived; superseded ADRs link forward via `supersedes`.
- **Active / Archive** — lifecycle states for briefs, specs, and
  plans. Files move between `active/` and `archive/`
  subdirectories; filenames and ids are stable across the move.
- **Id** — the stable `id:` in frontmatter linking a feature's
  brief, spec, plan, and test plan. Unchanged across archival.
- **🔄 marker** — the current-phase indicator inside a plan.
  `resume-plan` and `implement` read this to know where to pick
  up.
- **Integrity check** — the read-only `/integrity-check` skill
  that reports on the local health of the `.ai/` installation.

---

---

## How to extend this file

- Add a term only when an agent has gotten it wrong at least
  once, or when a spec needs to disambiguate two candidate words.
- Keep entries to one short paragraph. If a term needs more,
  write a rule or an ADR and link it from here.
- Contradictions with product documentation are resolved in
  favour of product documentation; update this file in the same
  change.
