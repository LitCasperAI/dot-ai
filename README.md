# `.ai/` — How to use this scaffold

> **Interactive overview:** open [`intro.html`](intro.html) in a
> browser for a visual walk-through of the scaffold, its skills,
> and the workflow they form.

This folder is a portable AI collaboration scaffold, distributed as
a **git submodule**. It tells any reasonably capable AI coding
tool — Claude Code, Gemini CLI, GitHub Copilot CLI, Cursor, Codex,
or a human following the same procedure — how to work in this
project consistently.

If you are an AI agent, start with `AGENTS.md`, not this file.
This file is for humans.

---

## What's in the box

```text
.ai/                                ← git submodule (shared, forkable)
├── AGENTS.md                       ← entry point for AI agents
├── project.yaml.example            ← config template; copy to .ai-local/
├── personas/                       ← stack-agnostic roles (7 personas)
├── rules/
│   ├── global/                     ← org-wide rules; always loaded (9 files)
│   └── stacks/                     ← per-stack rules; loaded per project.yaml
│       ├── dotnet/                 ← .NET / C# (8 files)
│       ├── nodejs/                 ← Node.js / TypeScript (8 files)
│       ├── rust/                   ← Rust (8 files)
│       ├── nextjs/                 ← Next.js additions
│       └── react-native/           ← React Native additions
├── skills/                         ← 11 slash commands (source of truth)
├── templates/                      ← skeletons for generated docs
├── terminology/                    ← shared vocabulary (global.md)
├── .gemini/commands/               ← Gemini CLI TOML shims (auto-generated)
├── .scripts/                       ← install & update scripts (ps1 + sh)
└── intro.html                      ← visual presentation of this scaffold
```

The install script creates project-specific config and symlinks at
the **repo root**:

```text
.ai-local/                          ← project-specific (NOT in submodule)
├── project.yaml                    ← your project's routing contract
├── rules/                          ← project-specific rule overrides
└── overrides/                      ← additive persona extensions per stack

CLAUDE.md ──────────────────────→ symlink to .ai/AGENTS.md
GEMINI.md ──────────────────────→ symlink to .ai/AGENTS.md
.github/copilot-instructions.md → symlink to .ai/AGENTS.md

.claude/skills/*/SKILL.md ─────→ per-file symlinks to .ai/skills/
.gemini/commands/*.toml ────────→ per-file symlinks to .ai/.gemini/commands/

docs/
├── briefs/   active/ + archive/    ← product-framed requirements
├── specs/    active/ + archive/    ← architectural specs
├── plans/    active/ + archive/    ← phased implementation plans + test plans
└── decisions/                      ← ADRs (never archived)
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

### First-time setup (new project)

1. **Add the submodule:**
   ```bash
   git submodule add -b main --name dot-ai <url> .ai
   ```
2. **Run the install script:**
   ```bash
   # PowerShell (Windows)
   .ai/.scripts/install-symlinks.ps1

   # Shell (Linux / macOS)
   sh .ai/.scripts/install-symlinks.sh
   ```
   This creates all symlinks, scaffolds `docs/` and `.ai-local/`,
   and stages everything for commit.
3. **Edit `.ai-local/project.yaml`** — fill in your project name,
   stacks, and any path overrides.
4. **Commit everything** and push.

### Cloning a repo that already uses dot-ai

```bash
git clone -c core.symlinks=true <repo-url>
cd <repo>
git submodule update --init
```

`core.symlinks=true` is needed on Windows so git creates real
symlinks instead of text files.

### Updating to the latest scaffold

```bash
# PowerShell (Windows)
.ai/.scripts/update-submodule.ps1

# Shell (Linux / macOS)
sh .ai/.scripts/update-submodule.sh
```

The update script pulls the latest submodule (`--remote`), prunes
dead symlinks for removed skills/commands, creates new symlinks
for added ones, and stages everything.

### Using skills

Once set up, invoke skills by name — `/create-spec`,
`/implement`, etc. — using your tool's slash-command mechanism.
Run **`/integrity-check`** to verify the install is healthy.

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

### `.ai-local/project.yaml` is the routing contract

Every skill's first step is "read `.ai-local/project.yaml`." From
that single file, a skill learns:

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
tool's equivalent). The tool's slash-command binding
(`.claude/skills/create-spec/SKILL.md`,
`.gemini/commands/create-spec.toml`) is a symlink or thin
wrapper that points the AI at the canonical `SKILL.md`.

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
skill. The `.claude/skills/` and `.gemini/commands/`
directories provide native slash-command bindings for Claude
Code / Copilot CLI and Gemini CLI respectively — other tools can
invoke skills by name ("run the `implement` skill") or by
pointing the tool at `SKILL.md` directly.

### Claude Code / GitHub Copilot CLI

1. Both tools auto-discover skills under
   `.claude/skills/*/SKILL.md`. No extra configuration needed.
2. Type `/` to list available commands. Every skill has one:
   `/create-spec`, `/create-plan`, `/implement`, etc.
3. Commands accept arguments after the name, e.g.
   `/implement docs/plans/active/2026-04-16-login.md`.
4. `.claude/settings.local.json` (Claude Code) holds your local
   tool permissions; it is machine-specific and should not be
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

### Other tools (Cursor, Codex, any LLM)

No native slash commands, but the scaffold still works:

- Point the tool at `.ai/AGENTS.md` and ask it to follow the
  procedure.
- Invoke a skill by name: "Run the `implement` skill
  against `docs/plans/active/…`."
- The tool will (or should) load the skill's `SKILL.md`,
  then `.ai-local/project.yaml`, then the relevant rules and
  persona, and follow the numbered Steps.

If a tool cannot do that reliably, it is not a fit for this
scaffold.

---

## Extending the scaffold

- **Add a new stack**: create `rules/stacks/<name>/`, add
  numbered rule files, add `<name>` to `.ai-local/project.yaml`
  `project.stacks` and to `rules.load`.
- **Add a new skill**: create `skills/<name>/SKILL.md` with
  frontmatter and numbered Steps. Add a matching Gemini TOML in
  `.gemini/commands/`. Run the update script to pick up new
  symlinks, or create them manually.
- **Add a new persona**: create `personas/<name>.md`
  (stack-agnostic), add `<name>` to `.ai-local/project.yaml`
  `personas.enabled`. Optionally add stack overrides at
  `.ai-local/overrides/<stack>/<name>.md` — these are *additive*,
  not replacement.
- **Propose a rule change**: a normal PR against the relevant
  file under `rules/`. The rule-file owner (the team named by
  the path) reviews.

---

## Troubleshooting

| Symptom | First place to look |
| --- | --- |
| Skill claims it cannot find a path | `.ai-local/project.yaml` `paths.*` |
| Skill invokes a missing persona | `.ai-local/project.yaml` `personas.enabled` + the `personas/` folder |
| Rule contradicts another rule | Load order in `.ai-local/project.yaml` `rules.load` — later wins by same filename |
| Doc archived but still shows as active | Re-run `/refresh-docs` |
| Slash command missing in Claude Code / Copilot | Check `.claude/skills/<name>/SKILL.md` symlink exists and resolves |
| Slash command missing in Gemini CLI | Check `.gemini/commands/<name>.toml` symlink exists and resolves |
| Symlinks show as text files (Windows) | Clone with `git clone -c core.symlinks=true`; requires Developer Mode |
| Unsure if install is healthy | Run `/integrity-check` |

---

## Further reading

- [`intro.html`](intro.html) — visual walk-through of the
  scaffold, skills, and workflow.
- `AGENTS.md` — agent-facing entry point.
- `.ai-local/project.yaml` — the routing contract.
- `rules/global/01-principles.md` — the principles under
  which everything else operates.
- `rules/global/04-doc-lifecycle.md` — the state machines
  and archive cascade.
- Any `skills/<name>/SKILL.md` — the exact procedure a skill
  runs.
