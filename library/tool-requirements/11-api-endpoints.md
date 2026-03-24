# Step 11: API Endpoints

## Purpose

Router structure, all endpoints with input/output schemas, permission strings, and handler behavior.

## Prerequisites

- Step 10 (Permissions) must be complete
- Derived from: data model (doc 02), user flows (doc 07), error states (doc 08), permissions (doc 09)

## Conversation Guide

### Exploration Strategy

- Derive from: data model (doc 02), user flows (doc 07), error states (doc 08), permissions (doc 09)
- Every endpoint must specify its `requirePermission()` string
- Every mutation endpoint emits platform hooks after success
- Include bulk and export endpoints if applicable (per doc 01 optional features)
- Define input/output schemas for each endpoint (Zod-compatible)

### Research Actions

- Read `docs/05-api-layer.md` for oRPC patterns
- Read `plans/archive/contacts-requirements/04-api-endpoints.md` for reference
- Check existing tool routers for patterns (`tools/*/src/api/router.ts`)

## Output Template

**File**: `plans/{{tool_name}}-requirements/10-api-endpoints.md`

```
# {{tool_name}} -- API Endpoints

All endpoints use authed oRPC builder + requirePermission() from @ydtb/auth.
Router lives at tools/{{tool_name}}/src/api/router.ts.

---

## Router Structure

{{tool_name}}
+-- list          <- requirePermission('{{tool_name}}.view')
+-- getById       <- requirePermission('{{tool_name}}.view')
+-- create        <- requirePermission('{{tool_name}}.create')
+-- update        <- requirePermission('{{tool_name}}.edit')
+-- remove        <- requirePermission('{{tool_name}}.delete')
+-- [sub-resource]
    +-- list/create/update/remove

---

## [Resource] Endpoints

### [tool].list

**Permission**: requirePermission('{{tool_name}}.view')

Input:
  search?: string
  page: number (default 1)
  pageSize: number (default 25, max 100)

Output:
  data: [Resource][]
  total: number
  page: number
  pageSize: number

**Handler**: ...

---

### [tool].getById

**Permission**: requirePermission('{{tool_name}}.view')

Input: { id: string }
Output: [Resource] | null

---

### [tool].create

**Permission**: requirePermission('{{tool_name}}.create')

Input: { [fields...] }
Output: [Resource]

**Handler**: Insert, broadcast '[tool]:created', return record.

---

### [tool].update

**Permission**: requirePermission('{{tool_name}}.edit')

Input: { id: string, [fields...] }
Output: [Resource]

**Handler**: Update, broadcast '[tool]:updated', return record.

---

### [tool].remove

**Permission**: requirePermission('{{tool_name}}.delete')

Input: { id: string }
Output: [Resource]

**Handler**: Delete, broadcast '[tool]:deleted', return record.

---

## Bulk & Export Endpoints

<!-- If applicable:
### [tool].bulkDelete
Permission: requirePermission('{{tool_name}}.delete')
Input: { ids: string[] }
Output: { deleted: number }
Handler: Delete matching. Log one activity per deleted record. Broadcast per each.

### [tool].bulkUpdate
Permission: requirePermission('{{tool_name}}.edit')
Input: { ids: string[], data: Partial<Resource> }
Output: { updated: number }
Handler: Update matching. Log one activity per updated record with field diffs.

### [tool].export
Permission: requirePermission('{{tool_name}}.view')
Input: { format: 'csv' | 'xlsx', filters?, sort?, fields?: string[] }
Output: file (streamed download with Content-Disposition header)
-->
```

## Completion Criteria

- [ ] Router structure documented with all endpoints
- [ ] Every endpoint has permission string, input schema, and output schema
- [ ] Every mutation endpoint emits appropriate platform hooks
- [ ] Bulk endpoints defined if bulk operations enabled
- [ ] Export endpoint defined if export enabled
- [ ] Input/output schemas are Zod-compatible
- [ ] Every endpoint from user flows (doc 07) is accounted for
- [ ] `.progress.yaml` updated: api-endpoints status set to complete
