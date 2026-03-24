# Step 8: User Flows

## Purpose

Step-by-step flows for every major interaction. Each flow defines: trigger -> steps -> outcome, including success, error, and activity logging behavior.

## Prerequisites

- Step 7 (Design Briefs) must be complete
- `04-pages-and-components.md` (pages), `06-design-briefs.md` (UI details), and `01-plan-overview.md` (optional features) available

## Conversation Guide

### Exploration Strategy

- Every page from doc 04 should have at least one flow
- Every flow references specific UI elements from doc 04
- Every mutation has a corresponding API endpoint (forward ref to doc 10)
- Walk through each flow: trigger -> steps -> outcome
- Consider these flow categories:
  - CRUD operations (create, view list, view detail, edit, delete)
  - Bulk operations (select multiple, bulk edit, bulk delete)
  - Configuration (changing settings, managing sub-resources)
  - Search & filter (searching, filtering, sorting)
  - Import / Export (if applicable per doc 01 optional features)
- For bulk operations: selection model, BulkActionBar, activity logging per entity
- For export: formats, field selection, filter application, file naming

### Research Actions

- Read `plans/archive/contacts-requirements/03-user-flows.md` for reference
- Read `docs/13-ui-patterns.md` for BulkActionBar pattern
- Check contacts tool for export pattern (`tools/contacts/src/lib/export-queries.ts`)

## Output Template

**File**: `plans/{{tool_name}}-requirements/07-user-flows.md`

```
# {{tool_name}} -- User Flows

Step-by-step flows for every major interaction. Each flow: trigger -> steps -> outcome.

---

## N. [Flow Name]

1. User [triggers the flow by...].
2. [What happens next].
3. ...
4. On success:
   - [UI feedback]
   - [Data changes]
   - [Activity/audit logging]
5. On error: [error handling behavior].

---

## Bulk Operations

<!-- If applicable:
### Bulk Delete
1. User selects multiple records via row checkboxes.
2. BulkActionBar appears showing "N selected" and available actions.
3. User clicks "Delete" in BulkActionBar.
4. Confirmation dialog: "Delete N records? This cannot be undone."
5. On confirm: API call to bulk delete endpoint.
6. On success: toast "N records deleted", selection cleared, list refreshed.
7. On partial failure: toast showing how many succeeded/failed.

### Bulk Update
1. User selects multiple records via row checkboxes.
2. User clicks "[Field]" action in BulkActionBar.
3. Popover/dialog to choose new value.
4. On confirm: API call to bulk update endpoint.
5. On success: toast "N records updated", selection cleared, list refreshed.
-->

---

## Export Flow

<!-- If applicable:
### Export Records
1. User clicks "Export" button in header area.
2. Export options dialog: format (CSV/Excel), field selection, apply current filters.
3. On confirm: API call to export endpoint.
4. Browser downloads the generated file.
5. Toast: "N records exported."
-->
```

## Completion Criteria

- [ ] Every page from doc 04 has at least one associated flow
- [ ] Every flow has trigger -> steps -> outcome structure
- [ ] Success behavior includes UI feedback, data changes, and activity logging
- [ ] Error behavior specified for each flow
- [ ] Bulk operations documented if enabled in optional features
- [ ] Export flow documented if enabled in optional features
- [ ] Every mutation references a corresponding API endpoint
- [ ] `.progress.yaml` updated: user-flows status set to complete
