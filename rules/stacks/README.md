# Stack rules

Stack-specific constraints. One folder per stack. Loaded after
`global/` and before `project/`, only for the stacks listed in
`project.yaml` under `project.stacks`.

## What lives here

Anything that is true for a given stack but not for every stack.
Folder layout, framework idioms, routing, build and release,
component or module conventions, accessibility specifics,
performance budgets that depend on the runtime.

A new stack folder is added when a project type is supported by
the scaffold for the first time. Existing folders are kept in
sync with the framework's own conventions — when the framework
changes its recommended layout, the stack rule changes with it.

## What does not live here

- Universal principles. Those belong in `global/`.
- One project's quirks. Those belong in `project/`.
- Code samples or templates. Those belong in `.ai/templates/`
  or in the stack's own starter, not in a rule file.

## Precedence

Stack rules replace same-named files in `global/`. They are in
turn replaced by same-named files in `project/`. Replacement is by
filename — if a stack rule overrides `06-testing.md`, the stack
file must restate everything from the global testing rule that
still applies on that stack.

## Adding or editing a stack

- Mirror the numbering used in sibling stacks where possible, so
  readers can compare layers across stacks at a glance.
- If a rule applies to most stacks but not all, prefer keeping
  it in `global/` and letting the outlier override it project-wise.
  Do not duplicate the same content across every stack folder.
- When a stack is added, update `rules.core` or `rules.contextual`
  in `project.yaml` for any project that adopts it.
