# Terminology File Format

Format for files under `.ai-local/terminology/` — consistent with the
shared `.ai/terminology/global.md` this project already ships.

## Structure

```md
# Terminology — {domain name} (project-specific)

{One or two sentence description of what this file covers, and that
it extends `.ai/terminology/global.md` rather than repeating it.}

## Domain terms

- **Order** — {one or two sentence definition of what it IS, not what
  it does}.
  _Avoid_: Purchase, transaction

- **Invoice** — A request for payment sent to a customer after
  delivery.
  _Avoid_: Bill, payment request
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project's domain.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this domain, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.
- Add a term only when an agent has gotten it wrong at least once, or when a spec needs to disambiguate two candidate words — the same bar `.ai/terminology/global.md` uses.

## Multiple domain files

A project can have more than one file under `.ai-local/terminology/`
(e.g. one per bounded context). All of them are always loaded —
order and precedence come from `project.yaml`'s `terminology.load`
list, the same mechanism that orders `rules.contextual`. There is no
separate map file: `project.yaml` is the map.
