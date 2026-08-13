---
id: <feature-slug> # copied from the brief
type: spec
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: architect
related:
  brief: <path under briefs/active or briefs/archive>
  plan: null
  decisions: []
tracker:
  issue: null # { id, url } once published by create-plan; see 17-tracker-integration.md
---

# <Feature> — Technical Spec

## Scope

What this spec covers and what it deliberately does not. Cross-
reference the brief's scope if it answers the same question.

## Approach

The chosen approach in enough detail that another engineer could
implement it without a second conversation. Walk through the
flow end to end.

## Folder Structure & Component Changes

A file tree illustrating every file to be created, modified, or
deleted, followed by a brief summary of the changes.

```text
src/
└── ...
```

## Data model

Entities, fields, relationships, persistence boundaries. Note
migration implications if any.

## Interfaces

Public APIs, navigation entry points, component contracts,
service boundaries — whatever "interface" means on this stack.

## Alternatives considered

Other approaches evaluated and why they were not chosen. An
empty section here usually means the design space was not
explored.

## Architectural decisions

- ADR ids recorded alongside this spec, with one-line summaries.
  Full context lives in the ADRs themselves under
  `<paths.decisions>/`.

## Open questions

*(Open questions are tracked in `docs/open-questions/<YYYY-MM-DD>-<feature-slug>.md` until resolved. This section will be populated with the resolved questions upon phase completion.)*
