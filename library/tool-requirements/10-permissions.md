# Step 10: Permissions & Access Control

## Purpose

Role-based access control -- who can do what. Define permission actions, member tier behavior, API authorization, and client-side permission checks.

## Prerequisites

- Step 9 (Error & Empty States) must be complete
- `08-error-and-empty-states.md` available for permission-denied states

## Conversation Guide

### Exploration Strategy

- What permission actions does this tool need? (view, create, edit, delete, manage, etc.)
- Should guests be blocked from this tool entirely? (guestBlocked: true/false)
- Is this an agency-scoped tool? (uses `agency:permissions` instead of `workspace:permissions`)
- Map each API endpoint to its `requirePermission()` string
- Which UI elements should be gated by permissions? What happens when denied?

### Member Tier Reference

| Tier | Behavior |
|------|----------|
| owner | Bypasses all permission checks (implicit full access) |
| member | Access determined by assigned roles + individual grants |
| guest | Read-only access to non-blocked features. If guestBlocked: true, no access at all |

### Research Actions

- Read `docs/07-permissions.md` for the full permission system
- Read existing tool `permissions.ts` files for examples (`tools/*/src/permissions.ts`)
- Read `plans/archive/contacts-requirements/` for reference patterns

## Output Template

**File**: `plans/{{tool_name}}-requirements/09-permissions-and-access.md`

```
# {{tool_name}} -- Permissions & Access Control

---

## Permission Registration

// tools/{{tool_name}}/src/permissions.ts
import type { PermissionRegistration } from '@ydtb/plugin-sdk'

export const TOOL_PERMISSIONS: PermissionRegistration = {
  feature: '{{tool_name}}',
  label: '{{tool_name}}',
  guestBlocked: false,
  actions: [
    { key: 'view', label: 'View resources', category: 'read' },
    { key: 'create', label: 'Create resources', category: 'write' },
    { key: 'edit', label: 'Edit resources', category: 'write' },
    { key: 'delete', label: 'Delete resources', category: 'admin' },
  ],
}

| Action Key | Label | Category | Description |
|-----------|-------|----------|-------------|
| view | ... | read | ... |
| create | ... | write | ... |
| edit | ... | write | ... |
| delete | ... | admin | ... |

Categories (read/write/admin) are metadata for grouping in the role editor UI.

---

## Member Tiers

| Tier | Behavior | Notes |
|------|----------|-------|
| owner | Bypasses all permission checks | No database records needed |
| member | Access by assigned roles + individual grants | Effective = role grants + individual - denials |
| guest | Read-only to non-blocked features | guestBlocked: true blocks all access |

**Guest blocking**: guestBlocked = true / false

---

## Workspace Isolation

All data scoped to workspaceId. API uses context.workspaceId in all queries.

---

## API Authorization

Every endpoint chains requirePermission() after authed:
  const list = authed.use(requirePermission('{{tool_name}}.view')).handler(...)

| Endpoint | Permission String | Notes |
|----------|------------------|-------|
| list | {{tool_name}}.view | ... |
| getById | {{tool_name}}.view | ... |
| create | {{tool_name}}.create | ... |
| update | {{tool_name}}.edit | ... |
| remove | {{tool_name}}.delete | ... |

---

## Client-Side Permission Checks

Route-level: <PermissionGuard toolId="{{tool_name}}">
Element-level: useHasPermission('{{tool_name}}.edit')
Conditional queries: { enabled: useHasPermission('{{tool_name}}.manage') }

| UI Element | Permission Check | Behavior When Denied |
|-----------|-----------------|---------------------|
| Tool page | PermissionGuard toolId="{{tool_name}}" | "No access" |
| ... | ... | ... |

---

## Registration

| Site | File | What It Powers |
|------|------|---------------|
| Client | plugin.ts -- hooks.addFilter('workspace:permissions', ...) | Sidebar, PermissionGuard, role editor |
| Server | Auto-generated permissions.gen.ts (via bun run generate) | requirePermission() middleware |

---

## Resource-Level Permissions
<!-- If specific records have own permission model -->

---

## Agency Scope
Is this agency-scoped? Yes / No
<!-- If yes: permission filter = agency:permissions, context = context.agencyId -->
```

## Completion Criteria

- [ ] All permission actions defined with keys, labels, and categories
- [ ] Guest blocking decision made
- [ ] Every API endpoint mapped to a permission string
- [ ] Client-side permission checks defined for all gated UI elements
- [ ] Member tier behavior documented
- [ ] Registration sites documented (client plugin.ts + server permissions.gen.ts)
- [ ] Agency scope decision made
- [ ] `.progress.yaml` updated: permissions-and-access status set to complete
