# Next.js Accessibility

Accessibility is a correctness requirement, not a polish pass.
Pages that are not usable with a keyboard and a screen reader
are not done.

---

## Semantic HTML first

- **Use the right element.** A `<button>` is a button; a `<div
  onClick>` is not. Links (`<a>`) go to URLs; buttons trigger
  actions. `next/link` wraps `<a>` — keep it that way.
- **One `<h1>` per page.** Headings are hierarchical; do not
  jump levels to get a size.
- **Forms use `<label htmlFor>`**, not placeholder-as-label.
  A placeholder disappears on focus; a label does not.

## Every interactive element has an accessible identity

- **Icon-only buttons have an `aria-label`.** A `<button>` with
  just an SVG inside is invisible to screen readers.
- **State is announced.** `aria-pressed`, `aria-expanded`,
  `aria-selected`, `aria-checked`, `aria-disabled` reflect the
  live state. Do not convey state with colour alone.
- **Live regions for dynamic messages.** Toasts, form errors,
  and async status updates use `role="status"` or
  `role="alert"`, not a silent visual change.

## Focus and keyboard

- **Every interactive element is reachable by Tab.** No
  `tabindex="-1"` on something the user needs to use, and no
  positive `tabindex` values to reorder focus.
- **Visible focus rings stay.** Do not blanket-remove
  `outline` in CSS; if the default ring is ugly, replace it
  with a better one, don't delete it.
- **Modals and dialogs trap focus** and return it to the
  trigger on close. Use `<dialog>` or a vetted headless library
  (Radix, React Aria); do not hand-roll focus management.
- **Route changes move focus.** On navigation in the App Router,
  focus is sent to the main landmark or the page heading; a
  screen reader that stays parked on the old link is a bug.

## Text and colour

- **Text scales with the user's browser font size.** Do not set
  the root font size in `px` in a way that ignores user prefs.
- **Colour contrast meets WCAG AA** (4.5:1 for body text,
  3:1 for large text and UI components). Palette entries are
  checked at the point they are added.
- **Do not rely on colour alone** to convey meaning. Errors get
  an icon or text marker too.

## Images and media

- **Every `<Image>` has `alt`.** Decorative images use
  `alt=""`; informative images describe what they convey, not
  what they look like.
- **Video has captions** and, where applicable, a transcript.
  An autoplaying video with sound is rejected by default.

## Forms and validation

- **Errors are associated with their field** via
  `aria-describedby` pointing at the error message's id.
- **Required fields are marked with `aria-required`**, not
  just a visual asterisk.
- **Validation messages are specific.** "Invalid" is not a
  message; "Must be a valid email address" is.

## Testing accessibility

- **Every new page is walked with the keyboard and a screen
  reader** (VoiceOver on macOS, NVDA on Windows) before the PR
  is marked ready. This is a step, not a nicety.
- **Axe runs in CI.** `jest-axe` or Playwright's axe integration
  runs against changed pages; a new violation fails the build.
- **Component tests query by role and label** (see
  `02-testing.md`). If a component cannot be queried by role,
  it is probably not accessible.
