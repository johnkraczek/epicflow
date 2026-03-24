# Step 4: Navigation & Routing

## Purpose

Map the tool into the existing shell -- route tier, routes, sidebar, header, and deep linking.

## Prerequisites

- Step 2 (Plan Overview) must be complete
- `01-plan-overview.md` available for scope and page list

## Conversation Guide

### Exploration Strategy

- Which route tier? Most workspace tools use Dashboard (`platform:routes`). See tier table below.
- Does this tool need multiple tiers (e.g., admin pages + public-facing pages)?
- Does it need a custom tier? (Define TierDefinition with id, layout, filter)
- What routes does this tool register? List all paths with components.
- Where does this appear in the sidebar? What icon? Default visible?
- What goes in the sidebar panel? Primary action, navigation items, secondary links?
- What goes in the header? Title, subtitle, search, action buttons?
- How do users navigate between pages within this tool?
- What URLs should be shareable/bookmarkable (deep linking)?

### Route Tier Reference

| Tier | Hook Filter | Auth | Workspace | Chrome | Use Case |
|------|------------|------|-----------|--------|----------|
| Dashboard | platform:routes | Yes | Yes | Full 5-part layout | Standard workspace tool pages |
| Fullscreen | platform:routes:fullscreen | Yes | Yes | None | Builder, immersive experiences |
| Authenticated | platform:routes:authenticated | Yes | No | None | Context selection, post-login |
| Public | platform:routes:public | No | No | None | Landing pages, invite acceptance |
| Agency | platform:routes:agency | Yes | Agency | Agency layout | Agency management pages |
| Custom | (plugin-registered) | Custom | Custom | Custom | Portal experiences with own auth |

### Research Actions

- Read `docs/03-route-tiers.md` for the 6 built-in tiers
- Read `docs/02-plugin-registration.md` for plugin definition contract
- Check existing `plugin.ts` files for route and navigation registration patterns
- Look at TanStack Router usage (`$param` syntax, not `:param`)

## Output Template

**File**: `plans/{{tool_name}}-requirements/03-navigation-and-routing.md`

```
# {{tool_name}} -- Navigation & Routing

How this tool integrates into the YDTB shell.

---

## Route Tier

**Tier**: platform:routes (Dashboard)
<!-- Or specify other tier with rationale -->

---

## Route Registration

| Route | Page Component | Description |
|-------|---------------|-------------|
| /{{tool_name}} | {{tool_name}}Page | Main page |
| /{{tool_name}}/$id | {{tool_name}}DetailPage | Detail page |

<!-- Registration in plugin.ts:
hooks.addFilter('platform:routes', (routes: RouteDefinition[]) => [
  ...routes,
  { path: '/{{tool_name}}', component: Page },
  { path: '/{{tool_name}}/$id', component: DetailPage },
])
Dashboard routes auto-wrap with PermissionGuard. Do NOT manually wrap. -->

---

## Navigation Registration

<!-- hooks.addFilter('workspace:navigation', (items: NavigationItem[]) => [
  ...items,
  { id: '{{tool_name}}', label: '...', icon: 'LucideIconName', route: '/{{tool_name}}', defaultVisible: true },
]) -->

---

## Sidebar Structure

**Title**: "{{tool_name}}"
[Primary action button]
-----
[Navigation items]
-----
[Secondary links]

---

## Header Structure

[Title + subtitle]                    [Search] [Action buttons]

---

## Navigation Between Pages

| From | To | Trigger |
|------|-----|---------|
| ... | ... | ... |

---

## Deep Linking

| URL Pattern | Behavior |
|-------------|----------|
| /{{tool_name}} | Main list view |
| /{{tool_name}}/$id | Specific record detail |
```

## Completion Criteria

- [ ] Route tier selected with rationale
- [ ] All routes listed with page components
- [ ] Navigation registration defined (sidebar icon, label, visibility)
- [ ] Sidebar structure documented (primary action, nav items, secondary links)
- [ ] Header structure documented
- [ ] Page-to-page navigation mapped
- [ ] Deep linking URLs defined
- [ ] `.progress.yaml` updated: navigation-and-routing status set to complete
