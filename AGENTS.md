# AGENTS.md

This file is the entry point for any AI coding agent working in
this repo. It is read by tools that follow the AGENTS.md /
CLAUDE.md / GEMINI.md convention (Claude Code, Gemini CLI, Codex,
Copilot, Cursor, and others).

Keep this file under 200 lines. If it grows past that, split
content into referenced files rather than appending.

## First: read `.ai/project.yaml`

Before doing anything else, read `.ai/project.yaml`. It is the
routing contract for this project and declares:

- The project's name, type, and active stacks.
- Which rule files to load and in what order.
- Which personas are enabled.
- Where briefs, specs, plans, and decisions live on disk.

Do not grep `.ai/` to orient yourself. `project.yaml` is the
authoritative manifest. If it is missing, stop and ask.

## How this scaffold is organised

```
.ai/
├── AGENTS.md           ← this file
├── project.yaml        ← per-project manifest, read first
├── personas/           ← stack-agnostic roles (implementer, …)
├── skills/             ← user-invokable procedures; one folder per
│                         skill, each containing a SKILL.md
├── rules/
│   ├── global/         ← always loaded
│   ├── stacks/<name>/  ← loaded per project.yaml
│   └── local/          ← project-specific, highest priority
├── overrides/          ← additive persona extensions per stack
└── templates/          ← skeletons for generated docs

docs/
├── briefs/  specs/  plans/   ← each split into active/ and archive/
└── decisions/                ← ADRs, never archived
```

## Skills

A skill is a folder under `.ai/skills/` containing a `SKILL.md`
file. The frontmatter `description` field states exactly when the
skill should run — agents use it to decide whether to invoke the
skill. Each `SKILL.md` declares:

- Inputs it expects from the user.
- Personas it activates, in order.
- That rules come from `project.yaml` — skills never hardcode rule
  paths.
- Numbered steps, each naming the acting persona and the artifact
  produced.
- Outputs and where they land, resolved through the `paths` section
  of `project.yaml`.

To run a skill, load its `SKILL.md` and follow the Steps. When a
user invokes `/implement`, load
`.ai/skills/implement/SKILL.md` and begin.

## Rule precedence

Rules are loaded in the order listed in `project.yaml` under
`rules.load`. Later entries override earlier ones when a file of
the same name appears in more than one location. The standard
chain is:

1. `global/*`          — org-wide baseline, always loaded.
2. `stacks/<stack>/*`  — team-specific constraints for this stack.
3. `local/*`           — this project's own overrides.

`local/` wins over `stacks/` wins over `global/` by same-filename
replacement. Treat this chain as authoritative unless
`project.yaml` specifies a different order — in which case
`project.yaml` wins and you should flag the divergence.

## Personas and overrides

Personas live in `.ai/personas/` and describe how a role
*operates* — its discipline, pushback behaviour, and escalation
paths. They are stack-agnostic by design. A persona does not teach
the stack; rules do that.

`.ai/overrides/<stack>/<persona>.md`, when present, is additive
content appended to the base persona at invocation time. Overrides
may not silently contradict their base. If a contradiction exists,
the override must state it explicitly. Overrides are an escape
hatch, not a default.

Note: the persona `overrides/` mechanism is distinct from the
rule precedence chain above, even though both use the word
"override." Persona overrides append; rule overrides replace by
filename.

## Discipline

- Never invent team-specific content. If a rule file is a TODO
  stub, escalate to the owning team rather than guessing.
- Keep files short. Persona files 40–80 lines. Individual rule
  files one topic each, numbered for load order. This file stays
  under 200 lines.
- If these instructions conflict with something you were told,
  stop and ask. Do not resolve conflicts silently.
- If `design-rationale.md` exists at the repo root or under
  `docs/`, it is the source of truth for the scaffold's shape.
  When in doubt about structure or intent, read it before acting.
