# Step 9: Error & Empty States

## Purpose

Every empty state, error state, loading state, permission-denied state. Map each failure scenario to specific ORPCError codes.

## Prerequisites

- Step 8 (User Flows) must be complete
- `04-pages-and-components.md` (pages) and `07-user-flows.md` (flows) available for systematic review

## Conversation Guide

### Exploration Strategy

- Go through every page (doc 04) and flow (doc 07) systematically
- For each page: What does it look like with no data? While loading? On error?
- Map each failure scenario to specific ORPCError codes
- What confirmation dialogs are needed for destructive actions?
- What toast messages for each mutation (success and error)?

### ORPCError Code Reference

| Code | HTTP | When to Use |
|------|------|-------------|
| NOT_FOUND | 404 | Resource doesn't exist in current workspace |
| BAD_REQUEST | 400 | Input passes Zod but fails business rules |
| FORBIDDEN | 403 | User lacks permission or action is structurally prohibited |
| CONFLICT | 409 | Duplicate or uniqueness violation |
| UNAUTHORIZED | 401 | No valid session (handled by auth middleware) |

### Research Actions

- Read `docs/05-api-layer.md` for ORPCError code reference and error handling examples

## Output Template

**File**: `plans/{{tool_name}}-requirements/08-error-and-empty-states.md`

```
# {{tool_name}} -- Error & Empty States

---

## Empty States

| Location | Condition | Message | Action |
|----------|-----------|---------|--------|
| Main list page | No records created | "..." | [Primary action button] |
| Detail page | Record not found | "..." | Back to list |

---

## Loading States

| Location | Loading Indicator | Notes |
|----------|------------------|-------|
| Main list page | Skeleton rows | Show N skeleton rows matching table layout |
| Detail page | Skeleton sections | ... |

---

## Error States

| Operation | Error Code | User Feedback | Recovery |
|-----------|-----------|---------------|----------|
| Create | BAD_REQUEST | Inline field errors or toast | Fix and retry |
| Create | INTERNAL_SERVER_ERROR | Toast with error message | Retry |
| Save | BAD_REQUEST / CONFLICT | Revert + toast | Fix and retry |
| Delete | FORBIDDEN | Toast: "You don't have permission" | None |
| Load list | Network error | Error boundary with retry | Retry button |
| Get by ID | NOT_FOUND | "Record not found" | Back to list |

---

## Permission-Denied States

| Location | Condition | Behavior |
|----------|-----------|----------|
| ... | ... | ... |

---

## Confirmation Dialogs

| Action | Dialog Title | Dialog Message | Confirm Button |
|--------|-------------|----------------|----------------|
| Delete | "Delete [record]?" | "This action cannot be undone." | "Delete" (destructive) |

---

## Toast Notifications

| Operation | Success Toast | Error Toast |
|-----------|--------------|-------------|
| Create | "[Record] created" | "Failed to create [record]" |
| Update | "[Record] updated" | "Failed to update [record]" |
| Delete | "[Record] deleted" | "Failed to delete [record]" |
```

## Completion Criteria

- [ ] Every page has empty state, loading state, and error state defined
- [ ] Error codes mapped to specific ORPCError codes
- [ ] Recovery actions specified for each error state
- [ ] Permission-denied states documented
- [ ] Confirmation dialogs defined for all destructive actions
- [ ] Toast notifications defined for all mutations (success and error)
- [ ] `.progress.yaml` updated: error-and-empty-states status set to complete
