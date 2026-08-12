---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* the project's terminology for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## Where terms live

Terminology is declared in `project.yaml`'s `terminology.load` list and is **always loaded** — never grep `.ai/` or the repo root to find it. Two tiers, same-filename precedence (`.ai-local/` wins):

1. `.ai/terminology/*.md` — shared, submodule-wide vocabulary. Edit sparingly: a change here affects every project on this scaffold.
2. `.ai-local/terminology/*.md` — project-specific vocabulary. **This is where domain-modeling writes.**

Resolve the write target before editing:

- **One file** under `.ai-local/terminology/` → write there.
- **No files** → create one lazily, on the first term you have to write. Name it for the project's domain (check `project.yaml`'s `project.domain`), then add it to `terminology.load` in `project.yaml` in the same change.
- **Multiple files** → ask the user which one the term belongs to.

Use the format in [TERMINOLOGY-FORMAT.md](./TERMINOLOGY-FORMAT.md).

## ADR file structure

Check `project.yaml`'s `paths.decisions` first — that's where this project routes ADRs, and it takes precedence over everything below.

Only if `paths.decisions` is unset does the fallback apply: most repos keep ADRs in `docs/adr/`:

```
docs/adr/
├── 0001-event-sourced-orders.md
└── 0002-postgres-for-write-model.md
```

In a multi-context repo, context-specific decisions can live alongside the relevant subsystem instead: `src/ordering/docs/adr/`. Create `docs/adr/` lazily — only when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in the project's terminology, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update the terminology inline

When a term is resolved, write it to the resolved `.ai-local/terminology/*.md` file right there. Don't batch these up — capture them as they happen. Use the format in [TERMINOLOGY-FORMAT.md](./TERMINOLOGY-FORMAT.md).

The terminology file should be totally devoid of implementation details. Do not treat it as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).
