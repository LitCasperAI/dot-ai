---
id: design-system-global
type: design-system
scope: global
status: approved
owner: designer
created: 2026-04-20
updated: 2026-04-21
---

# Global design system

The scaffold-shared baseline for design across every project that
adopts this scaffold. Owned by the `designer` persona; loaded by
every persona doing UI work, per
`.ai/rules/global/10-design-system.md`.

This file is the **floor**. Project documents at
`<paths.design_system>` may extend or override entries here
**by named deviation**, but may never lower the accessibility
floor declared below.

---

## Tokens

The atomic, semantic units composed by every component. Tokens
are referenced by name, never by raw value, in product code.

## Brand

Replace with your project's brand guidelines. Consider tone, visual
mood, and the core design philosophy that guides component choices.

## Colors

Grouped with hex codes and usage notes:

### Primary

- primary-500: — main brand color, used for primary actions, active selection states, and success indicators.

### Secondary

- secondary-500: — secondary scale, used for secondary accents and supporting UI elements.

### Tertiary

- tertiary-500: — tertiary scale, used for warnings and tertiary actions.

### Neutrals

- neutral-100: #FFFFFF — surface background, card backgrounds, outline button backgrounds.
- neutral-200: — light background.
- neutral-300: — secondary light background.
- neutral-400: — disabled fill backgrounds.
- neutral-500: — disabled outline borders.
- neutral-600: — disabled text color.
- neutral-900: — primary body text, default icons, and default function buttons/borders.

### Semantic

- success: — used for success indicators and OK states.
- warning: — used for warning state buttons and icons.
- error: — used for critical/error state buttons and delete actions.
- info: — used for info state buttons.

## Typography

- Heading font: sans-serif
- Body font: sans-serif

### Type scale

Document your type scale with names and usage context.

## Spacing

- space-1: 4px (or 5px)
- space-2: 8px (or 10px)
- space-4: 16px (or 20px)

## Radii

- radius-sm: 4px
- radius-md: 8px
- radius-lg: 12px

## Elevation

- shadow-sm: subtle shadow for resting cards and inputs
- shadow-md: for dropdown menus and hovering cards
- shadow-lg: for overlays and modals

## Components

Document your reusable components here, including:

- Button variants and states
- Form elements (inputs, selects, checkboxes)
- Cards and containers
- Navigation patterns
- Modals and overlays
- Tooltips and popovers

For each component, define:
- Purpose and use cases
- Variants and states
- Key tokens used
- Notable behavior

## Iconography

- Style: [Define your icon style — outline, solid, etc.]
- Sizes: [List your standard icon sizes]

## Layout

- Grid system: [Describe your grid (e.g., 12-column, spacing)]
- Max content width: [Document if applicable]
- Common spacing rhythm: [Standard padding/margins]

## Voice & Tone

Describe how your product communicates with users.

## Rules

Document key design rules and constraints that maintain consistency
across the product.

## Notes

Use this section for implementation notes, migration guidance, or
known limitations of the design system.
