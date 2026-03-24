# Accessibility Review SOP

Lightweight a11y checklist for UI work. Run through during self-review — not every item applies to every task, check the ones relevant to your changes.

## When to Use

Apply this checklist when a task involves:

- Creating new UI components
- Modifying existing UI components
- Building or changing pages or layouts
- Creating or modifying forms
- Adding or changing interactive elements (buttons, menus, dialogs, tabs)

## Checklist

### Keyboard Navigation

- [ ] All interactive elements (buttons, links, inputs, selects, custom controls) are reachable via Tab
- [ ] Tab order follows the visual and logical reading order
- [ ] No keyboard traps — user can always Tab out of a component
- [ ] Custom interactive elements support expected keys (Enter/Space for buttons, Arrow keys for menus/tabs)

### Focus Management

- [ ] When a modal or dialog opens, focus moves into it
- [ ] When a modal closes, focus returns to the element that triggered it
- [ ] After a route change, focus moves to the main content area or page heading
- [ ] After form submission, focus moves to the success/error message or next logical element
- [ ] Focus indicators are visible (do not remove `:focus` outlines without providing an alternative)

### Screen Reader Support

- [ ] Images have meaningful `alt` text (decorative images use `alt=""`)
- [ ] Buttons and links have descriptive labels (not just "Click here" or an icon with no text)
- [ ] Icon-only buttons have `aria-label` or visually hidden text
- [ ] Dynamic content changes are announced via `aria-live` regions (e.g., toast notifications, inline validation, loading states)
- [ ] Page has a logical heading hierarchy (`h1` > `h2` > `h3`, no skipped levels)

### Color and Contrast

- [ ] Text meets WCAG AA contrast ratio: 4.5:1 for normal text, 3:1 for large text (18px+ or 14px+ bold)
- [ ] Information is not conveyed by color alone (e.g., error states use icons or text in addition to red)
- [ ] UI is usable in high contrast mode

### Forms

- [ ] Every input has an associated `<label>` element (using `htmlFor`/`for`) or `aria-label`
- [ ] Required fields are indicated (not just by color)
- [ ] Error messages are associated with their input (via `aria-describedby` or `aria-errormessage`)
- [ ] Form validation errors are announced to screen readers

### ARIA Usage

- [ ] Native HTML elements are used where possible (`<button>` instead of `<div role="button">`)
- [ ] ARIA roles, states, and properties are used correctly when native HTML is insufficient
- [ ] ARIA is not overused — no redundant roles on elements that already have implicit roles
- [ ] Custom widgets follow WAI-ARIA Authoring Practices patterns where applicable

### Motion and Animation

- [ ] Animations respect `prefers-reduced-motion` media query
- [ ] No content flashes more than 3 times per second
- [ ] Auto-playing animations can be paused or stopped

### Touch Targets (Mobile)

- [ ] Interactive elements have a minimum touch target of 44x44px
- [ ] Adequate spacing between touch targets to prevent accidental taps

## How to Use

1. During self-review of any UI task, scan this checklist
2. Check only the items relevant to the changes made — not every section applies to every task
3. Fix any violations that are straightforward
4. For violations that require significant work outside the task scope, document them as follow-up items
5. Note any a11y considerations in the task report if applicable

## Quick Validation Tools

These tools can help verify items on the checklist (all are optional):

- **Browser DevTools**: Accessibility panel shows computed roles, labels, and contrast
- **Lighthouse**: Accessibility audit catches common issues
- **axe DevTools**: Browser extension for automated a11y scanning
- **Keyboard only**: navigate the page using only Tab, Enter, Space, Escape, and Arrow keys

## Expected Output

- UI meets WCAG AA for the checklist items that apply to the task
- Any known a11y gaps are documented for follow-up
