# Step 5: Pages & Components

## Purpose

Detail every page, drawer, dialog -- what it shows, how it's accessed, shared components, and state management strategy.

## Prerequisites

- Step 4 (Navigation & Routing) must be complete
- `03-navigation-and-routing.md` available for route list

## Conversation Guide

### Exploration Strategy

- For each route defined in doc 03, what does the page contain?
- What drawers slide out? What triggers them? (All drawers use TabbedPanel from @ydtb/ui)
- What dialogs/modals are needed? What triggers them?
- What shared components from @ydtb/ui can be reused? What new ones are needed?
- How is server state managed? (TanStack Query / oRPC hooks)
  - Hook file organization: one file per domain entity
  - Cache invalidation strategy per mutation (broad vs narrow)
  - Conditional queries (enabled option)
  - Optimistic updates for any mutations?

### Research Actions

- Read `packages/ui/` to inventory available components
- Check existing tool pages for layout patterns
- Reference screenshots in `reference/` folder
- Read `docs/10-state-management.md` for state management patterns
- Read `plans/archive/contacts-requirements/02-pages-and-drawers.md` for reference

## Output Template

**File**: `plans/{{tool_name}}-requirements/04-pages-and-components.md`

```
# {{tool_name}} -- Pages & Components

---

## Pages

### N. [PageName]

**Route**: /{{tool_name}}/...
**File**: tools/{{tool_name}}/src/pages/[PageName].tsx

**What it shows**:
- ...

**Header area** (via HeaderPortal):
- ...

**Sidebar** (via SidebarPortal):
- ...

**Key interactions**:
- ...

---

## Drawers

### N. [DrawerName]

**File**: tools/{{tool_name}}/src/components/[DrawerName].tsx

**How it's accessed**: ...
**What it shows**: ...

---

## Dialogs

### N. [DialogName]

**File**: tools/{{tool_name}}/src/components/[DialogName].tsx

**How it's accessed**: ...
**What it shows**: ...

---

## Shared Components

### [ComponentName]

**Package/File**: ...
**Props**: ...
**Used by**: ...

---

## State Management & Cache Strategy

| Hook File | Queries | Mutations |
|-----------|---------|-----------|
| hooks/use-[entities].ts | list, getById | -- |

Cache invalidation plan:

| Mutation | Invalidation Strategy | What's invalidated |
|----------|----------------------|-------------------|
| create | Broad | All list queries |
| update | Narrow | Single entity + list queries |
| delete | Broad | All queries for this entity |

---

## Reference Screenshots
<!-- Link to screenshots in reference/ folder -->
```

## Completion Criteria

- [ ] Every route from doc 03 has a corresponding page with content description
- [ ] All drawers documented with triggers and content
- [ ] All dialogs documented with triggers and content
- [ ] Shared components identified (existing from @ydtb/ui and new ones needed)
- [ ] State management strategy defined with hook files and cache invalidation plan
- [ ] Reference screenshots linked where available
- [ ] `.progress.yaml` updated: pages-and-components status set to complete
