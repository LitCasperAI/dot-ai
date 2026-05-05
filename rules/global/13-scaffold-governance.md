# Scaffold governance

The `.ai/` directory is a **git submodule** sourced from the
`beep-dot-ai-root` repository. It is shared across multiple
projects. Treat it as read-only in consuming repos.

## What lives where

| Content | Repository | Path |
|---------|-----------|------|
| Global rules, skills, personas, templates | `beep-dot-ai-root` | `.ai/rules/global/`, `.ai/skills/`, `.ai/personas/`, `.ai/templates/` |
| Stack-specific rules | `beep-dot-ai-root` | `.ai/rules/stacks/<name>/` |
| Project-specific rules & overrides | Consuming repo | `.ai-local/rules/`, `.ai-local/overrides/` |
| Project manifest | Consuming repo | `.ai-local/project.yaml` |

## Rules for creating new scaffold content

### General / cross-project content → `beep-dot-ai-root`

If the new content is **not specific to the current project** — e.g.,
a new global rule, a new skill, a persona update, a template change,
or a stack rule — it **must** be contributed to `beep-dot-ai-root`
via pull request:

1. **Do not edit files under `.ai/` directly in a consuming repo.**
   The submodule checkout is read-only from the consumer's
   perspective. Local edits will be lost on the next
   `git submodule update`.
2. Create a feature branch in `beep-dot-ai-root`.
3. Make the change there.
4. Open a PR against `beep-dot-ai-root` `main`.
5. After merge, update the submodule pointer in the consuming repo:
   ```bash
   cd .ai && git pull origin main && cd ..
   git add .ai
   git commit -m "chore: bump .ai submodule to latest"
   ```

### Project-specific content → `.ai-local/`

If the content applies **only** to the current project (e.g.,
project-specific rules, persona overrides for that repo's stacks,
project YAML changes), create or edit files under `.ai-local/`:

- `.ai-local/rules/<NN>-<topic>.md` for rules
- `.ai-local/overrides/<stack>/<persona>.md` for persona extensions
- `.ai-local/project.yaml` for manifest changes

These are tracked in the consuming repo's git and follow its normal
PR workflow.

## When in doubt

Ask the user: _"This looks like a general scaffold improvement.
Should I contribute it to `beep-dot-ai-root` via PR, or keep it
local to this project in `.ai-local/`?"_

Do not silently create general content in `.ai-local/` when it
belongs in the shared scaffold, and do not silently edit the
submodule when changes need review upstream.

## Keeping the scaffold up to date

At **session start**, check whether the `.ai` submodule is behind
`origin/main`:

```bash
cd .ai && git fetch origin main --quiet && \
  LOCAL=$(git rev-parse HEAD) && \
  REMOTE=$(git rev-parse origin/main) && \
  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "⚠️  .ai submodule is behind origin/main"
  fi
```

If the submodule is behind:

1. Inform the user: _"The AI scaffold submodule is X commit(s)
   behind. Want me to bump it?"_
2. **Only after explicit approval**, update and commit:
   ```bash
   cd .ai && git pull origin main && cd ..
   git add .ai
   git commit -m "chore: bump .ai submodule to latest"
   ```
3. Include the bump in the current working branch. Do not create a
   separate branch just for the bump unless the user asks.

**Never bump the submodule silently.** The user must approve because
a scaffold update can change rules that affect the entire session.

