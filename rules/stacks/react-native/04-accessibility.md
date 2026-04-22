# React Native Accessibility

Accessibility is a correctness requirement, not a polish pass.
Screens that are not usable with VoiceOver and TalkBack are not
done.

---

## Every interactive element has an accessible identity

- **Touchables declare `accessibilityRole`** — `button`, `link`,
  `switch`, `header`, etc. A `Pressable` with no role is invisible
  to assistive tech.
- **Every interactive element has an `accessibilityLabel`** when
  its visible text is not sufficient on its own (icon-only
  buttons, custom controls, toggles).
- **State is announced.** Use `accessibilityState` for
  `selected`, `disabled`, `checked`, `expanded`. Do not convey
  state with colour alone.

## Text and typography

- **Text scales with the user's system font size.** Do not lock
  font sizes in a way that ignores Dynamic Type (iOS) or Font
  size preferences (Android). `allowFontScaling={false}` requires
  a recorded reason.
- **Line height and spacing scale with font size**, not with a
  hardcoded pixel value.
- **Colour contrast meets WCAG AA** (4.5:1 for body text,
  3:1 for large text and UI components). Palette entries are
  checked at the point they are added.

## Focus and navigation

- **Focus order follows visual order.** If you re-order elements
  visually with absolute positioning or flex tricks, set
  `accessibilityElementsHidden` / `importantForAccessibility` or
  restructure the tree.
- **Modals and sheets trap focus** and return it to the trigger
  on dismiss.
- **Announcements for dynamic changes** (form errors, toast
  messages) use `AccessibilityInfo.announceForAccessibility` or
  `accessibilityLiveRegion` — not a visual-only update.

## Gestures

- **Every custom gesture has a tappable alternative.** A
  swipe-only action is not accessible.
- **Long-press is not a primary action.** If the main way to do
  something is long-press, it is not discoverable.

## Images and icons

- **Decorative images are marked `accessibilityElementsHidden`
  (iOS) / `importantForAccessibility="no"` (Android).**
- **Informative images have an `accessibilityLabel`** describing
  what they convey, not what they look like.

## Testing accessibility

- **Every new screen is walked with VoiceOver and TalkBack**
  before the PR is marked ready. This is a step, not a nicety.
- **Component tests query by role and label** (see
  `02-testing.md`). If a component cannot be queried by role, it
  is probably not accessible.
