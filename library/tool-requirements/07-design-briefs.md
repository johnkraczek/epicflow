# Step 7: Design Briefs

## Purpose

Per-page layout specs with ASCII mockups, component mapping, interaction details. Each brief builds on doc 04 (pages) and doc 05 (design language), referencing existing pages as starting points.

## Prerequisites

- Step 6 (Design Language) must be complete
- `04-pages-and-components.md` and `05-design-language.md` available for reference

## Conversation Guide

### Exploration Strategy

- For each page in doc 04: find the closest existing page in the codebase, read its implementation
- Present: 'This page is similar to [X] -- what should change?'
- Every brief MUST have a 'Based on' field citing the reference page
- ASCII mockups show spatial relationships, not pixel-perfect layouts
- Call out where the design DEVIATES from the default component appearance
- For complex layouts, show both desktop and mobile sketches
- Focus on decisions an implementer would otherwise have to guess at

### Research Actions

- For each page in doc 04, find the closest existing page and read its implementation
- Reference @ydtb/ui component names (Button, Card, Table, Input, etc.)
- Check `reference/` folder for any mockups or screenshots

## Output Template

**File**: `plans/{{tool_name}}-requirements/06-design-briefs.md`

```
# {{tool_name}} -- Design Briefs

Per-page design specifications. Each builds on doc 04 (pages) and doc 05 (design language).
Reference existing pages as starting points.

---

## How to Read These Briefs

Each brief covers one page/surface and includes:
- Existing reference -- similar page already in the codebase
- Layout sketch -- ASCII mockup showing spatial arrangement
- Component mapping -- which components to use where
- Content hierarchy -- what's most prominent
- Interaction details -- hover states, click targets, transitions
- Responsive behavior -- how the layout adapts

---

## Surface N: [Surface Name]

### [PageName]

**Route**: /[route]
**Based on**: [path to existing similar page, or "New"]
**Reference**: reference/[filename].png

#### Layout

+-----------------------------------------------------+
|  [ASCII layout sketch showing spatial arrangement]   |
|  Use box-drawing characters to show:                 |
|  - Column structure                                  |
|  - Component placement                               |
|  - Relative sizing                                   |
+-----------------------------------------------------+

#### Component Mapping

| Area | Component | Props / Variant | Notes |
|------|-----------|----------------|-------|
| ... | ... | ... | ... |

#### Content Hierarchy

1. **Primary**: ...
2. **Secondary**: ...
3. **Tertiary**: ...

#### Interaction Details

| Element | Interaction | Behavior |
|---------|------------|----------|
| ... | hover | ... |
| ... | click | ... |

#### Responsive Behavior

| Breakpoint | Changes |
|-----------|---------|
| Desktop (>1024px) | ... |
| Tablet (768-1024px) | ... |
| Mobile (<768px) | ... |

---

## Shared Patterns

### [Pattern Name]
**Used on**: [list of pages]
**Description**: ...

---

## Animation & Motion

| Trigger | Animation | Duration | Easing | Notes |
|---------|-----------|----------|--------|-------|
| ... | ... | ... | ... | ... |

---

## Design Tokens (Tool-Specific)
<!-- Quick reference for implementers. All must be defined in doc 05 first. -->
<!-- No hardcoded colors/spacing/typography anywhere in the briefs. -->
```

## Completion Criteria

- [ ] Every page from doc 04 has a design brief
- [ ] Every brief has a "Based on" reference to an existing page or "New"
- [ ] ASCII mockups show spatial layout for each surface
- [ ] Component mapping tables specify exact @ydtb/ui components and props
- [ ] Content hierarchy is explicit (primary/secondary/tertiary)
- [ ] Interaction details cover hover, click, and other relevant states
- [ ] Responsive behavior documented for each surface
- [ ] Shared patterns extracted and named
- [ ] All design token references exist in doc 05
- [ ] `.progress.yaml` updated: design-briefs status set to complete
