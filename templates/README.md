# Document Templates

This directory contains the skeletons (**Templates**) used by skills to generate new documentation artifacts (briefs, specs, plans, etc.). 

Templates ensure that every document follows a consistent contract regarding frontmatter schema, section headings, and lifecycle metadata, regardless of which agent or human created it.

## How Templates are Used

Templates are not intended to be edited in the consuming repository. Instead:

1.  **Discovery**: A skill (e.g., `create-spec`) identifies the need for a new document.
2.  **Instantiation**: The skill reads the corresponding template from this directory.
3.  **Population**: The skill populates the template's frontmatter (ID, timestamps, owners, related paths) and initial body content.
4.  **Persistence**: The resulting file is written to the appropriate path under `docs/`, as resolved via `project.yaml`.

## Standard Structure

Every template follows a specific structure that agents rely on:

### 1. Frontmatter Contract
All templates must include the baseline frontmatter fields defined in `rules/global/03-documentation.md`:
*   `id`: The stable link across a feature's doc triple.
*   `type`: The artifact category (brief, spec, plan, etc.).
*   `status`: The current lifecycle state (draft, approved, etc.).
*   `owner`: The persona responsible for the document.
*   `related`: Pointers to other artifacts in the feature's lifecycle.

### 2. Canonical Headings
Templates define the "floor" for required sections. For example:
*   **Specs** must have an `Approach` and a `Folder Structure & Component Changes` section.
*   **Plans** must have `Phase` blocks with checkboxes and a `Notes` section for pause discipline.

## Creating or Modifying Templates

*   **Atomic Updates**: When updating a template, ensure that any skill that uses it is also checked for compatibility.
*   **Agnosticism**: Templates should remain technology-agnostic. Stack-specific nuances should be handled by the skill populating the template or the rules governing that stack.
*   **Source Truth**: Like skills and rules, templates must be updated in the `beep-dot-ai-root` repository and pulled into consumer projects via the submodule update process.
