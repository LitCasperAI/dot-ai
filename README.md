```text
 ██████╗ ███████╗███████╗██████╗      █████╗ ██╗
 ██╔══██╗██╔════╝██╔════╝██╔══██╗    ██╔══██╗██║
 ██████╔╝█████╗  █████╗  ██████╔╝    ███████║██║
 ██╔══██╗██╔══╝  ██╔══╝  ██╔═══╝     ██╔══██║██║
 ██████╔╝███████╗███████╗██║         ██║  ██║██║
 ╚═════╝ ╚══════╝╚══════╝╚═╝         ╚═╝  ╚═╝╚═╝
```

[![Version](https://img.shields.io/badge/version-0.5.0-green)](./SCAFFOLD_VERSION)

# BEEP AI — How to use this scaffold

This folder is a portable AI collaboration scaffold. It tells any
reasonably capable AI coding tool — Claude Code, Gemini CLI,
GitHub Copilot, Cursor, Codex, or a human following the same
procedure — how to work in this project consistently.

If you are an AI agent, start with `AGENTS.md`, not this file.
This file is for humans.

---

## What's in the box

```text
.ai/                            ← submodule (shared across projects)
├── AGENTS.md                   ← entry point for AI agents; routes to project.yaml
├── design-rationale.md         ← architectural "why" of the scaffold
├── design-system.md            ← global design tokens, primitives
├── personas/                   ← stack-agnostic roles (architect, implementer, …)
├── rules/
│   ├── global/                 ← always loaded
│   └── stacks/<name>/          ← loaded per project.yaml
├── skills/                     ← procedures a user invokes (create-spec, implement, …)
├── terminology/                ← shared vocabulary
├── templates/                  ← skeletons for generated docs
└── project.yaml.example        ← template; copy to .ai-local/

.ai-local/                      ← project-specific (tracked in your repo)
├── project.yaml                ← per-project manifest, read first
├── rules/                      ← project-specific rule overrides
└── overrides/                  ← additive persona extensions per stack
```

Plus, at the repo root:

```text
docs/
├── briefs/   active/ + archive/    ← product-framed requirements
├── specs/    active/ + archive/    ← architectural specs
├── plans/    active/ + archive/    ← phased implementation plans + test plans
├── decisions/                      ← ADRs (never archived)
├── open-questions/                 ← blockers and unresolved design points
└── design-system.md                ← project-specific components and patterns

.claude/commands/      ← Claude Code slash commands that invoke skills
.gemini/commands/      ← Gemini CLI slash commands that invoke skills
```

---

## Mental model

The scaffold is built around an iterative lifecycle: **idea → brief → spec →
plan → implementation → archive**. Each stage is bound by a **Review Loop**
to ensure quality and alignment before moving forward.

```text
       ( IDEA )
          │
          ▼ /create-spec
      [ BRIEF ] ◄──┐
          │        │
          ▼        │ /review
      [ SPEC ]  ◄──┤ (The Review Loop)
          │        │
          ▼        │ /create-plan
      [ PLAN ]  ◄──┘
          │
          ▼ /implement
    [ WORKING CODE ] ◄──┐
          │             │ /review
          ▼ /archive-plan│ (The Review Loop)
      ( ARCHIVE ) ◄─────┘
```

Three rules hold this together:

1. **`.ai-local/project.yaml` is the routing contract.** It names which
   rules to load (core and contextual), which personas are enabled, and where docs live.
   Change it, and every skill changes with it.
2. **Review-First Discipline.** Every artefact (brief, spec, plan)
   and every implementation phase should be followed by a **`/review`**
   call. This creates a loop where we constantly refine the outcome
   before committing to the next step.
3. **Every artefact has an owner.** Briefs belong to
   `product-analyst`, specs to `architect`, plans to
   `implementer`, test plans to `tester`, ADRs to `architect`,
   and design systems to `designer`.
4. **Skills are slash commands.** The labels on the arrows above
   (e.g., `/create-spec`) are the exact commands you type.
   Notice that `/create-spec` handles both the "Idea to Brief"
   and "Brief to Spec" transitions.
5. **Rules are loaded in order: `.ai/rules/global/*` → `.ai/rules/stacks/<stack>/*`
   → `.ai-local/rules/*`.** Later entries override earlier ones by
   same-filename replacement. `.ai-local/rules/` wins. Core rules (`rules.core`)
   are always loaded; contextual rules (`rules.contextual`) are loaded on-demand.


---

## Quick start

### 1. First-time installation

If you are porting this scaffold to a new project for the first time:

1.  **Add the submodule**: 
    ```bash
    git submodule add <this-repo-url> .ai
    ```
2.  **Run the installation script**: 
    - **macOS/Linux**: `.ai/.scripts/install-symlinks.sh`
    - **Windows**: `.ai/.scripts/install-symlinks.ps1`
3.  **Interactive Setup**: The script will guide you through setting up your `.ai-local/project.yaml` by asking for your project name and allowing you to select from the available technology stacks.
4.  **Verify**: Run **`/integrity-check`** to ensure all symlinks and paths are resolved correctly.

### 2. Pick your tool

See "Tool setup" below. Once set up, you can type `/create-spec` or `/implement` (or the tool's equivalent) and the AI will execute the matching skill.

---

## Task cookbook

### "I have a new feature idea"

1. Invoke **`/create-spec`** with the requirement in
   your own words.
2. The skill drafts a **brief** via `product-analyst`, pauses,
   and waits for you to approve it.
3. Approve the brief (flip `status: approved`, or re-invoke with
   `approve=<brief-path>`). The `architect` drafts a **spec**
   plus any ADRs for load-bearing decisions.
4. Review and approve the spec.
5. Invoke **`/create-plan`**. You now have a phased
   implementation plan.
6. Optionally invoke **`/design-tests`** to have `tester`
   produce a test plan that the implementer will execute
   against.
7. Invoke **`/implement`** to start building. The skill
   keeps the plan's checkboxes, `progress` counters, 🔄 marker,
   and Notes entries honest as work proceeds.
8. When the plan is `done`, invoke **`/archive-plan`** to
   cascade brief + spec + test plan + plan into `archive/`.

### "I'm coming back to a paused feature"

Invoke **`/resume-plan`** with the plan path. It reads the 🔄
marker and the latest Notes entry, reloads the spec and brief,
and hands off to `implement` with context preloaded.

### "I need to review a pull request or document"

Invoke **`/review`** with the context (e.g., path to a file, diff). The skill:
- Acts as a unified entry point, intelligently delegating to doc review or code change review based on the input.
- Automatically runs a parallel security check using the `security-reviewer` persona.
- Consolidates all findings into a single, cohesive response.
- Pauses to ask for clarification if your intent is ambiguous.

### "I need to upgrade a dependency or fix a vulnerability"

Invoke **`/manage-dependencies`** (optionally passing a CVE report or specific package). The skill:
- Activates the `dependency-manager` persona to inspect your lockfiles and propose safe version bumps or replacements.
- Strictly validates package names and versions against official registries.
- **Requires your explicit approval** before executing any installation commands to prevent malicious package injections.

### "I need a deeper security review"

Invoke **`/security-review`** for features that warrant more
than `/review-change`'s inline pass. The `security-reviewer`
authors a stated threat model, maps asset lifecycles, and
classifies findings (block / change-required / advisory). If
the review produces a load-bearing decision, `architect`
authors an ADR.

### "I'm cutting a release"

Invoke **`/prepare-release`**. The `release-engineer` preflights
the branch, proposes a version bump, drafts release notes, and
stops before any store submission. Tag push and CI trigger
require your explicit approval. Submission is a separate human
step.

### "I want to know what's in flight"

Open `docs/README.md` — the dashboard. It lists briefs, specs,
and plans under `active/`, plus recent archives and ADRs. It
refreshes automatically when doc-touching skills run; you can
re-run it manually with **`/refresh-docs`**.

### "I need to audit the project's health"

- **`/integrity-check`** — reports on the local health of the `.ai/` installation (paths, personas, templates).
- **`/audit-docs`** — sweeps the documentation tree for staleness, missing pieces, and contradictions.
- **`/audit-structure`** — sweeps the codebase for divergences from stack-specific folder and component conventions.

### "I need to research a major change"

Invoke **`/investigate`** with a topic or library name. The `architect` will evaluate it against the project's rules and industry best practices, drafting a spec or ADR with the findings.

### "I'm unsure of a project-specific term or rule"

Invoke **`/ask`** with your question. The `librarian` will:
- Search `terminology/global.md`, `rules/`, and ADRs for the answer.
- Provide a response with direct citations to the source files.
- Identify "Knowledge Gaps" where documentation is missing or ambiguous.

### "I want to know what's in flight"

Invoke **`/integrity-check`**. Read-only report on four
categories: installation gate, content presence, pointer
resolution, version record.

---

## How files connect

### `.ai-local/project.yaml` is the routing contract

Every skill's first step is "read `.ai-local/project.yaml`." From that
single file, a skill learns:

- **Which rules to load** (`rules.core` and `rules.contextual`).
- **Which personas are enabled** (`personas.enabled`) and what
  they own (`personas.ownership`).
- **Where docs live** (`paths.briefs`, `paths.specs`,
  `paths.plans`, `paths.decisions`, `paths.index`).

No skill hardcodes paths. Move `docs/` to `documentation/`,
update `paths.*` in `project.yaml`, and the scaffold follows.

### Personas are discipline, rules are knowledge

A **persona** (e.g. `architect`, `reviewer`) describes how a
role _operates_ — what it refuses to do, what it escalates, what
discipline it holds. Personas are stack-agnostic.

**Rules** (`rules/global/*`, `rules/stacks/<stack>/*`) teach the
stack: what frameworks to use, what folder layout to follow,
what tests to write. Rules are stack-specific.

A skill loads both: the persona that acts, plus every rule file
`project.yaml` lists. The persona decides how to act; the rules
decide what "correct" looks like on this stack.

### Skills are procedures, not magic

A **skill** is a folder under `skills/` containing a `SKILL.md`
file. `SKILL.md` has a frontmatter `description` — the AI uses
it to decide when the skill should run — plus numbered Steps.
To run a skill, the AI loads `SKILL.md` and follows the Steps.

You invoke a skill by name (`/create-spec` or the
tool's equivalent). The tool's slash-command file
(`.claude/commands/create-spec.md`,
`.gemini/commands/create-spec.toml`) is a thin
wrapper that tells the AI which `SKILL.md` to load.

### Templates are the shape of generated docs

When a skill writes a brief, spec, plan, test plan, ADR,
review, or security review, it copies the matching template
from `templates/` and populates it. Templates carry frontmatter
and the canonical section headings — edit a template, and
every doc the skill generates from that point forward follows
the new shape.

### The lifecycle is enforced, not optional

`rules/global/04-doc-lifecycle.md` defines:

- State machines: `draft → approved` (brief, test plan),
  `draft → in-review → approved` (spec), `draft → in-progress
→ done` (plan), `proposed → accepted → superseded` (ADR).
- Dashboard refresh: every skill that mutates an `active/` doc
  invokes `refresh-docs` in the same call.
- Archive cascade: when a plan flips to `done`, `archive-plan`
  moves the plan, its test plan, its spec, and its brief into
  `archive/` atomically. ADRs never archive.

---

## Tool setup

The scaffold is tool-agnostic. Any AI coding tool that can read
the repo's files and follow a Markdown procedure can run a
skill. The `.claude/commands/` and `.gemini/commands/`
directories provide native slash-command bindings for Claude
Code and Gemini CLI — other tools can invoke skills by name
("run the `implement` skill") or by pointing the tool
at `SKILL.md` directly.

### Claude Code

1. Claude Code auto-discovers slash commands under
   `.claude/commands/*.md`. No extra configuration needed.
2. In the Claude Code CLI, type `/` to list available
   commands. Every skill has one: `/create-spec`,
   `/create-plan`, `/implement`, etc.
3. Commands accept arguments after the name, e.g.
   `/implement docs/plans/active/2026-04-16-login.md`.
4. `.claude/settings.local.json` holds your local tool
   permissions; it is machine-specific and should not be
   committed.

### Gemini CLI

1. Gemini CLI discovers slash commands under
   `.gemini/commands/*.toml`. No extra configuration needed.
2. In the Gemini CLI, type `/` to list available commands.
   Every skill has one.
3. Gemini's TOML commands support a `{{args}}` placeholder for
   free-form arguments and shell injection via `!{…}` if the
   skill needs it; the scaffold's commands keep injection to
   a minimum and rely on the agent to read files via its own
   tooling.

### Other tools (Copilot, Cursor, Codex, any LLM)

No native slash commands, but the scaffold still works:

- Point the tool at `.ai/AGENTS.md` and ask it to follow the
  procedure.
- Invoke a skill by name: "Run the `implement` skill
  against `docs/plans/active/…`."
- The tool will (or should) load the skill's `SKILL.md`,
  then `project.yaml`, then the relevant rules and persona,
  and follow the numbered Steps.

If a tool cannot do that reliably, it is not a fit for this
scaffold.

---

## Extending the scaffold

- **Add a new stack**: create `rules/stacks/<name>/`, add
  numbered rule files, add `<name>` to `project.yaml`
  `project.stacks`. Rules from the stack are typically included in `rules.core` or matched by `rules.contextual`.
- **Add a new skill**: create `skills/<name>/SKILL.md` with
  frontmatter and numbered Steps. Add matching slash-command
  files under `.claude/commands/` and `.gemini/commands/`.
  Reference the skill from this guide's Task cookbook.
- **Add a new persona**: create `personas/<name>.md`
  (stack-agnostic), add `<name>` to `project.yaml`
  `personas.enabled`. Optionally add stack overrides at
  `overrides/<stack>/<name>.md` — these are _additive_, not
  replacement.
- **Propose a rule change**: a normal PR against the relevant
  file under `rules/`. The rule-file owner (the team named by
  the path) reviews.

---

## Troubleshooting

| Symptom                                | First place to look                                                     |
| -------------------------------------- | ----------------------------------------------------------------------- |
| Skill claims it cannot find a path     | `project.yaml` `paths.*`                                                |
| Skill invokes a missing persona        | `project.yaml` `personas.enabled` + the `personas/` folder              |
| Rule contradicts another rule          | Load order in `project.yaml` `rules.core` or `rules.contextual` — later wins by same filename |
| Doc archived but still shows as active | Re-run `/refresh-docs`                                                  |
| Slash command missing in Claude Code   | Check `.claude/commands/<name>.md` exists                               |
| Slash command missing in Gemini CLI    | Check `.gemini/commands/<name>.toml` exists                             |
| Unsure if install is healthy           | Run `/integrity-check`                                                  |

---

## Further reading

- `.ai/AGENTS.md` — agent-facing entry point.
- `.ai-local/project.yaml` — the routing contract.
- `.ai/rules/global/01-principles.md` — the principles under
  which everything else operates.
- `.ai/rules/global/04-doc-lifecycle.md` — the state machines
  and archive cascade.
- Any `.ai/skills/<name>/SKILL.md` — the exact procedure a skill
  runs.

