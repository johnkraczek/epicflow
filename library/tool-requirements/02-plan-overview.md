# Step 2: Plan Overview

## Purpose

Crystallize everything from prompt + research into design decisions. This is the interpreted, structured plan that all subsequent documents build on.

## Prerequisites

- Step 1 (Competitive Research) must be complete
- `prompt.md` and `00-competitive-research.md` available for reference

## Conversation Guide

### Exploration Strategy

- Summarize the scope: what's in, what's out, what's deferred
- Confirm fundamental scoping: workspace-scoped, agency-scoped, or both?
  - Workspace-scoped: data belongs to a single workspace, uses `platform:routes`, authed middleware
  - Agency-scoped: data belongs to an agency spanning workspaces, uses `platform:routes:agency`, agencyAuthed middleware
  - Both: separate tool variants (e.g., team + agency-team)
- Walk through the Optional Feature Checklist -- decide early which are needed:
  - Saved views (custom filter/sort/column configs)?
  - Custom fields / EAV (user-defined fields)?
  - Import (bulk data import from CSV/Excel)?
  - Export (bulk data export to CSV/Excel)?
  - Public/portal routes (customer-facing pages)?
  - Activity logging (audit trail per entity)?
  - Bulk operations (multi-select actions)?
- What exists today that this tool touches? Be specific about file paths.
- What shared components from @ydtb/ui can we reuse?
- Identify potential conflicts with existing tools

### Research Actions

- Read `docs/08-agency-model.md` for agency scoping decisions
- Read `docs/02-plugin-registration.md` for plugin definition contract
- Read `docs/12-project-structure.md` for standard file structure
- Check existing tools in `tools/` for code paths this tool will touch
- Identify shared components to reuse from `packages/ui/`
- Read `plans/archive/contacts-requirements/00-plan-overview.md` for reference

## Output Template

**File**: `plans/{{tool_name}}-requirements/01-plan-overview.md`

```
# {{tool_name}} -- Plan Overview

## Context
<!-- What is this tool? Why does it exist? What problem does it solve? -->

## Tool Scope
**Scope**: workspace | agency | both
<!-- If "both", list which features live at each level -->

## Convention File Checklist

| File | Needed? | Notes |
|------|---------|-------|
| plugin.ts | Yes (always) | Route, nav, permission, lifecycle hook registration |
| permissions.ts | Yes (always) | PERMISSIONS const and role-to-permission mapping |
| actions.ts | ? | Only if exposing cross-tool RPC actions |
| api/router.ts | Yes (always) | oRPC router with server-side hook registration |
| api/*Router.ts | ? | Sub-routers -- list which ones |
| db/schema.ts | ? | Only if tool has its own database tables |
| lib/seed.ts | ? | Only if tool seeds default data on workspace creation |
| lib/activity-queries.ts | ? | Only if tool needs activity logging |

## Deliverable Files
All written to plans/{{tool_name}}-requirements/:
(list all 16 docs + roadmap)

## Design Decisions (confirmed with user)
<!-- Record every significant design decision with rationale -->
<!-- Format: **[Topic]**: [Decision]. [Why]. -->

## Scope Summary

### Database
<!-- List tables: new and modified -->

### Pages
<!-- List pages with routes -->

### Drawers / Dialogs
<!-- List drawers and dialogs -->

### Shared / Reusable Components
<!-- Components extracted to @ydtb/ui or shared across tools -->

### New Dependencies
<!-- Any new npm packages needed -->

## What Exists Today
**Schema**: ...
**API**: ...
**UI**: ...
**Patterns**: ...

## Optional Feature Checklist

| Feature | Needed? | Notes |
|---------|---------|-------|
| Saved views | ? | Needs views table + views-queries.ts |
| Custom fields / EAV | ? | Needs field definitions + field values tables |
| Import | ? | Define format, validation, error handling in 07-user-flows.md |
| Export | ? | Define fields, filters, format options in 10-api-endpoints.md |
| Public/portal routes | ? | Needs custom route tier |
| Activity logging | ? | See 02-data-model.md activity logging section |
| Bulk operations | ? | See 07-user-flows.md bulk operations section |

## Verification Checklist
- [ ] Every table has workspaceId + proper FKs + cascade deletes
- [ ] Every page has a clear route and access point
- [ ] Every user flow has trigger -> steps -> outcome
- [ ] Every UI mutation has a matching API endpoint
- [ ] Implementation phases have correct dependency ordering
- [ ] Platform hooks cover all mutation events
- [ ] All shared components are identified and extraction is planned
```

## Completion Criteria

- [ ] Tool scope confirmed (workspace/agency/both)
- [ ] Convention file checklist completed
- [ ] Optional feature checklist decided
- [ ] Design decisions recorded with rationale
- [ ] Scope summary covers database, pages, drawers, components, dependencies
- [ ] "What Exists Today" section documents current codebase state
- [ ] Verification checklist items are addressable
- [ ] `.progress.yaml` updated: plan-overview status set to complete
