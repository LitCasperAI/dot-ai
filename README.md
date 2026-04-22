# `.ai/` — How to use this scaffold

This folder is a portable AI collaboration scaffold. It tells any
reasonably capable AI coding tool — Claude Code, Gemini CLI,
GitHub Copilot, Cursor, Codex, or a human following the same
procedure — how to work in this project consistently.

If you are an AI agent, start with `AGENTS.md`, not this file.
This file is for humans.

---

## What's in the box

```text
.ai/
├── AGENTS.md           ← entry point for AI agents; routes to project.yaml
├── project.yaml        ← per-project manifest; names stacks, personas, paths, rules
├── personas/           ← stack-agnostic roles (architect, implementer, reviewer, …)
├── rules/
│   ├── global/         ← org-wide rules; always loaded
│   └── stacks/<name>/  ← stack-specific rules; loaded per project.yaml
├── skills/             ← procedures a user invokes (create-spec, review-change, …)
└── templates/          ← skeletons for generated docs (brief, spec, plan, test-plan, ADR, review)
```

Plus, at the repo root:

```text
docs/
├── briefs/   active/ + archive/    ← product-framed requirements
├── specs/    active/ + archive/    ← architectural specs
├── plans/    active/ + archive/    ← phased implementation plans + test plans
└── decisions/                      ← ADRs (never archived)

.claude/commands/      ← Claude Code slash commands that invoke skills
.gemini/commands/      ← Gemini CLI slash commands that invoke skills
```

---

## Mental model

The scaffold is built around a flow: **idea → brief → spec → plan
→ implementation → archive**. Each arrow is a skill. Each
artefact has an owner (a persona) and a lifecycle (draft →
approved → archived).

```
idea ──create-spec──▶ brief ──create-spec──▶ spec ──create-plan──▶ plan ──implement──▶ working code ──archive-plan──▶ archive/
                                  ▲                                    ▲                        │
                                  │                                    │                        │
                      product-analyst                            architect        │── design-tests ──▶ test plan
                                                                                  │
                                                                                  │── review-change  ──▶ review
                                                                                  │── security-review ─▶ security review + (maybe) ADR
                                                                                  └── prepare-release ─▶ tag + release notes + CI run
```

Three rules hold this together:

1. **`project.yaml` is the routing contract.** It names which
   rules load, which personas are enabled, and where docs live.
   Change it, and every skill changes with it.
2. **Every artefact has an owner.** Briefs belong to
   `product-analyst`, specs to `architect`, plans to
   `implementer`, test plans to `tester`, ADRs to `architect`.
3. **Rules are loaded in order: `global/*` → `stacks/<stack>/*`
   → `local/*`.** Later entries override earlier ones by
   same-filename replacement. `local/` wins.

---

## Quick start

1. **Clone and install the scaffold.** `project.yaml` is already
   filled in for this project. If you are porting to a new
   project, copy `project.yaml.example` to `project.yaml` and fill
   in the fields.
2. **Pick your tool.** See "Tool setup" below. Once set up, you
   can type `/create-spec` or `/implement` (or
   the tool's equivalent) and the AI will execute the matching
   skill.
3. **Run `/integrity-check`.** It reports whether the local
   install is wired up correctly — paths resolve, personas
   referenced by skills exist, templates are present.

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

### "I need to review a pull request"

Invoke **`/review-change`**. The skill:

- Loads the diff and the linked spec/plan/ADR.
- Activates `security-reviewer` automatically if the diff
  touches auth, PII, payments, crypto, or secret storage.
- Activates `tester` automatically if the diff changes
  behaviour without matching test changes.
- Produces a structured review with blocking / change-request /
  suggestion buckets, each tied to a specific rule.

The review is read-only by default — posting to the PR requires
your explicit approval.

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

### "I'm not sure the scaffold is healthy"

Invoke **`/integrity-check`**. Read-only report on four
categories: installation gate, content presence, pointer
resolution, version record.

---

## How files connect

### `project.yaml` is the routing contract

Every skill's first step is "read `project.yaml`." From that
single file, a skill learns:

- **Which rules to load** (`rules.load`).
- **Which personas are enabled** (`personas.enabled`) and what
  they own (`personas.ownership`).
- **Where docs live** (`paths.briefs`, `paths.specs`,
  `paths.plans`, `paths.decisions`, `paths.index`).

No skill hardcodes paths. Move `docs/` to `documentation/`,
update `paths.*` in `project.yaml`, and the scaffold follows.

### Personas are discipline, rules are knowledge

A **persona** (e.g. `architect`, `reviewer`) describes how a
role *operates* — what it refuses to do, what it escalates, what
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
  `project.stacks` and to `rules.load`.
- **Add a new skill**: create `skills/<name>/SKILL.md` with
  frontmatter and numbered Steps. Add matching slash-command
  files under `.claude/commands/` and `.gemini/commands/`.
  Reference the skill from this guide's Task cookbook.
- **Add a new persona**: create `personas/<name>.md`
  (stack-agnostic), add `<name>` to `project.yaml`
  `personas.enabled`. Optionally add stack overrides at
  `overrides/<stack>/<name>.md` — these are *additive*, not
  replacement.
- **Propose a rule change**: a normal PR against the relevant
  file under `rules/`. The rule-file owner (the team named by
  the path) reviews.

---

## Troubleshooting

| Symptom | First place to look |
| --- | --- |
| Skill claims it cannot find a path | `project.yaml` `paths.*` |
| Skill invokes a missing persona | `project.yaml` `personas.enabled` + the `personas/` folder |
| Rule contradicts another rule | Load order in `project.yaml` `rules.load` — later wins by same filename |
| Doc archived but still shows as active | Re-run `/refresh-docs` |
| Slash command missing in Claude Code | Check `.claude/commands/<name>.md` exists |
| Slash command missing in Gemini CLI | Check `.gemini/commands/<name>.toml` exists |
| Unsure if install is healthy | Run `/integrity-check` |

---

## Further reading

- `.ai/AGENTS.md` — agent-facing entry point.
- `.ai/project.yaml` — the routing contract.
- `.ai/rules/global/01-principles.md` — the principles under
  which everything else operates.
- `.ai/rules/global/04-doc-lifecycle.md` — the state machines
  and archive cascade.
- Any `skills/<name>/SKILL.md` — the exact procedure a skill
  runs.
