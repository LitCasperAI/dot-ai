# Design system

This rule is a pointer. The design system itself lives in two
documents, both resolved through `project.yaml`:

- `<paths.design_system_global>` — scaffold-shared. Tokens,
  primitives, accessibility floors that hold on every project.
- `<paths.design_system>` — project-specific. Components,
  patterns, and any deviations from the global, each with a
  recorded reason.

Both are owned by the `designer` persona.

## Who reads what, when

- **`product-analyst`** reads both before finalising a brief
  whose scope mentions any UI surface. The brief names the
  components and patterns the feature will reuse, and lists any
  open design questions.
- **`architect`** reads both before finalising a spec whose
  scope mentions any UI surface. The spec cites the design-system
  entries it depends on; deviations are captured in the spec's
  Open questions until `designer` rules.
- **`implementer`** reads both before writing UI code. New
  components compose existing tokens and primitives; raw values
  (hex, magic spacing) are a rule violation per the stack's
  component-conventions file.
- **`reviewer`** rejects UI changes whose diff cites no design-
  system entry, or whose rendered output diverges from the entry
  it cites.
- **`designer`** owns both files. New entries land here only
  after a second use case proves the need.
- **`auditor`** in structure mode flags duplicates of existing
  entries and inline tokens as **Drift**, escalated to
  `designer`.

## Precedence between the two documents

The project document overrides the global document by **named
deviation**, not by silent contradiction. A project-specific
component may extend a global primitive (allowed by default) or
replace it (only with a stated reason, in a `## Deviations`
section in `<paths.design_system>`).

If the project document is silent on a topic, the global
document wins. If the global document is silent and the project
document is silent, the case is escalated to `designer`, not
guessed.

## Accessibility floor

The global document declares the accessibility floor in
user-observable terms (contrast ratios, hit-target sizes, focus
order, motion-reduce behaviour). Project documents may raise
the floor for that project; they may not lower it. A lowered
floor is a rule violation, not a deviation.

## What this rule does not do

- It does not state the tokens, components, or patterns
  themselves. Those are content, owned by `designer`, and live
  in the two pointed-at documents.
- It does not override the stack's `08-component-conventions.md`
  or `04-accessibility.md`. Those rules govern _how_ components
  are built and tested; this rule governs _which_ components
  exist and _what_ they look like.
- It does not apply to non-UI work. A backend-only change does
  not load the design system.

If `<paths.design_system_global>` or `<paths.design_system>`
is not declared in `project.yaml`, the persona that needed it
escalates to the human owner before proceeding with UI work.
