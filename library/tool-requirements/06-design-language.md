# Step 6: Design Language

## Purpose

Visual direction, color/typography strategy, component patterns. Start from what already exists in the platform. Default to "keep existing" -- only document deviations.

## Prerequisites

- Step 5 (Pages & Components) must be complete
- `04-pages-and-components.md` available for component and page list

## Conversation Guide

### Exploration Strategy

- Start from what already exists in the platform. Present the baseline to the user.
- Default to 'keep existing' -- only document deviations.
- What should this tool FEEL like? (Dense data tool? Marketing-facing? Admin utility?)
- 3-5 key design principles for this tool
- Does this tool need any NEW design tokens? (colors, spacing, etc.)
- How does it handle light/dark mode? Brand theming?
- MANDATORY: All visual values must reference design tokens -- never hardcode colors/spacing/typography
- Every new token must be defined before it can be used in design briefs

### Research Actions

- Audit @ydtb/ui components and their visual characteristics
- Read existing tool pages for established patterns
- Check CSS variables, color tokens, spacing scales already defined
- Use the frontend-design skill for design expertise if available

## Output Template

**File**: `plans/{{tool_name}}-requirements/05-design-language.md`

```
# {{tool_name}} -- Design Language

Visual direction, component patterns, and aesthetic guidelines.
Start from what exists. Audit @ydtb/ui, existing tool pages, established patterns first.

---

## Platform Baseline

### @ydtb/ui Component Inventory

| Component | Current Style | Relevant to This Tool? |
|-----------|--------------|----------------------|
| ... | ... | ... |

### Existing Patterns in Use

| Pattern | Where It Exists | Reuse / Adapt / Skip |
|---------|----------------|---------------------|
| ... | ... | ... |

### Established Tokens & Variables

| Category | Token / Variable | Current Value | Used In |
|----------|-----------------|---------------|---------|
| Color | ... | ... | ... |
| Spacing | ... | ... | ... |
| Typography | ... | ... | ... |

---

## Visual Direction

### Mood / Aesthetic
- ...

### Key Design Principles
1. **[Principle]** -- ...
2. **[Principle]** -- ...
3. **[Principle]** -- ...

---

## Theming & Token Strategy

### Token Rules
1. Colors -- Always reference color tokens. Never use raw hex/rgb.
2. Spacing -- Use established spacing scale. No arbitrary pixel values.
3. Typography -- Reference font size/weight/line-height tokens.
4. Borders & Shadows -- Use existing radius and shadow tokens.
5. Tool-specific tokens -- Define new tokens here if needed.

### New Tokens Required

| Token | Purpose | Default Value | Notes |
|-------|---------|---------------|-------|
| (None -- uses platform defaults, or list new tokens) |

### Theme Compatibility
- Light/dark mode: ...
- Brand theming: ...
- Public surfaces: ...

---

## Color Usage

| Element | Token Reference | Existing or New? | Notes |
|---------|---------------|-----------------|-------|
| ... | ... | ... | ... |

---

## Typography & Density

| Context | Approach | Notes |
|---------|----------|-------|
| Data tables | Dense / standard / spacious | ... |
| Forms | Field spacing, label placement | ... |
| Cards | Padding, content hierarchy | ... |

---

## Layout Patterns

### Desktop Layout
### Mobile Layout
### Responsive Strategy

| Surface | Primary Device | Strategy |
|---------|---------------|----------|
| ... | ... | ... |

---

## Component Patterns

### Primary Components

| Component | Existing Behavior | This Tool's Usage | Changes Needed |
|-----------|------------------|-------------------|---------------|
| ... | ... | ... | None / props only / wrap / new |

### Interaction Patterns

| Interaction | Pattern | Notes |
|-------------|---------|-------|
| Page transitions | Instant / fade / slide | ... |
| Form submission | Button loading state / optimistic | ... |
| Success feedback | Toast / inline / animation | ... |
| Error feedback | Toast / inline / shake | ... |

---

## Iconography
- Icon set: ...
- Size convention: ...
- Color convention: ...

---

## Imagery & Media

| Element | Treatment | Notes |
|---------|-----------|-------|
| Hero images | Aspect ratio, fallback, loading | ... |
| Thumbnails | Size, crop strategy | ... |
| Empty state illustrations | Style, source | ... |

---

## Accessibility Notes
- ...
```

## Completion Criteria

- [ ] Platform baseline documented (existing components, patterns, tokens)
- [ ] Visual direction and design principles defined
- [ ] Token strategy established (no hardcoded values)
- [ ] New tokens defined if needed
- [ ] Theme compatibility addressed (light/dark, brand theming)
- [ ] Color usage, typography, and density documented
- [ ] Layout patterns defined for desktop, mobile, and responsive
- [ ] Component patterns mapped to existing vs new
- [ ] Interaction patterns specified
- [ ] Accessibility notes included
- [ ] `.progress.yaml` updated: design-language status set to complete
