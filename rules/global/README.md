# Global rules

The org-wide baseline. Loaded first on every project, on every
stack, in every session. Numbered for load order — read top to
bottom.

## What lives here

Constraints that apply regardless of language, framework, or
product. Principles, conduct, documentation, version control,
testing, dependencies, secrets, observability. If a rule is true
for both a Node service and a React Native app, it belongs here.

## What does not live here

- Anything stack-specific (folder layout, framework idioms,
  build pipelines). Put those under `stacks/<name>/`.
- Anything project-specific (a single repo's deviations). Put
  those under `project/`.
- Team policy that is still being negotiated. Leave a stub and
  escalate; do not invent.

## Precedence

Global is the lowest layer. A file of the same name in
`stacks/<name>/` or `.ai-local/rules/` replaces the global file entirely.
Replacement is by filename, not by merge — if you override
`06-testing.md`, the project copy must restate everything that
still applies.

## Adding a rule

- One topic per file. Keep files short.
- Number the filename so the load order is explicit.
- Write declaratively. State the rule, then the reason in one
  line if it is non-obvious.
- If the rule needs project-specific tuning, leave the knob in
  prose ("projects MAY tighten this") rather than hardcoding a
  value that project/ will have to override.
