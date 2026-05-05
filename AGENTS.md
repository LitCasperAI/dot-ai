# BEEP AI — AGENTS.md

This file is the entry point for any AI coding agent working in
this repo. It is read by tools that follow the AGENTS.md /
CLAUDE.md / GEMINI.md convention (Claude Code, Gemini CLI, Codex,
Copilot, Cursor, and others).

Keep this file under 200 lines. If it grows past that, split
content into referenced files rather than appending.

## First: read `project.yaml`

Before doing anything else, read `.ai-local/project.yaml`. It is the
routing contract for this project and declares:

- The project's name, type, and active stacks.
- Which rule files to load and in what order.
- Which personas are enabled.
- Where briefs, specs, plans, and decisions live on disk.

Do not grep `.ai/` to orient yourself. `project.yaml` is the
authoritative manifest. If it is missing, stop and ask.

## How this scaffold is organised

```
.ai/                            ← submodule (shared across projects)
├── AGENTS.md                   ← this file
├── design-rationale.md         ← architectural "why"
├── design-system.md            ← global design tokens, primitives
├── personas/                   ← stack-agnostic roles (implementer, …)
├── skills/                     ← user-invokable procedures; one folder per
│                                 skill, each containing a SKILL.md
├── .gemini/                    ← Gemini-specific configuration
│   ├── commands/               ← slash-command "shims" (see README.md)
│   └── policies/               ← agent behavior policies
├── rules/                      ← behavioral constraints (see README.md)
│   ├── global/                 ← always loaded
│   └── stacks/<name>/          ← loaded per project.yaml
├── templates/                  ← doc skeletons (see README.md)
└── project.yaml.example        ← template; copy to .ai-local/
.ai-local/                      ← project-specific (tracked in your repo)
├── project.yaml                ← per-project manifest, read first
├── rules/                      ← project-specific rule overrides
└── overrides/                  ← additive persona extensions per stack
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

Rules are loaded based on the `rules` section in `project.yaml`.

1. **Core Rules (`rules.core`)**: Loaded at the start of every session. These are the "vital" rules for intent, safety, and conduct.
2. **Contextual Rules (`rules.contextual`)**: Loaded dynamically. When a task aligns with a specific topic (e.g., testing, documentation), the agent must load the corresponding files from these paths.
3. **Target repo conventions**: When operating inside an imported repository, its local convention files (e.g., `CLAUDE.md`, `GEMINI.md`) override sandbox rules on the same topic.
4. **Project Overrides (`.ai-local/rules/*`)**: Highest precedence.

Rule replacement is by filename. If `rules.core` and `rules.contextual` both point to a file of the same name, the later entry wins.

## Personas and overrides

Personas live in `.ai/personas/` and describe how a role
_operates_ — its discipline, pushback behaviour, and escalation
paths. They are stack-agnostic by design. A persona does not teach
the stack; rules do that.

`.ai-local/overrides/<stack>/<persona>.md`, when present, is additive
content appended to the base persona at invocation time. Overrides
may not silently contradict their base. If a contradiction exists,
the override must state it explicitly. Overrides are an escape
hatch, not a default.

Note: the persona `overrides/` mechanism is distinct from the
rule precedence chain above, even though both use the word
"override." Persona overrides append; rule overrides replace by
filename.

## Discipline

- **Strategy-First**: For multi-step or complex features, update the `plan` first and wait for explicit user approval before writing any product code. See `.ai/rules/global/02-agent-conduct.md`.
- **Skill-First Orientation**: Your primary goal is to identify and invoke the correct skill from `.ai/skills/`. Never bypass the Research -> Strategy -> Execution lifecycle for Directives, even if the user's prompt implies a shortcut.
- **Inquiry vs. Directive**: Treat broad feature descriptions or "we should" statements as **Inquiries** for strategy updates, not **Directives** to implement.
- **Contract-First**: Before implementation, verify if all required dependencies (APIs, hardware, external services) are available and documented. If they are missing, clarify with the user: should you implement mocks, wait for the dependency, or help define the interface/contract first? Never assume a mock is preferred over a real integration unless instructed.
- Never invent team-specific content. If a rule file is a TODO stub, escalate to the owning team rather than guessing.
- Keep files short. Persona files 40–80 lines. Individual rule files one topic each, numbered for load order. This file stays under 200 lines.
- If these instructions conflict with something you were told, stop and ask. Do not resolve conflicts silently.
- If `design-rationale.md` exists at the repo root or under `docs/`, it is the source of truth for the scaffold's shape. When in doubt about structure or intent, read it before acting.
