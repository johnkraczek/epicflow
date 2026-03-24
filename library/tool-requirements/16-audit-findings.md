# Step 16: Audit Findings

## Purpose

Cross-document consistency audit. Systematically check all 16 completed documents against each other for consistency, gaps, and conflicts.

## Prerequisites

- Step 15 (Testing Plan) must be complete
- All 16 preceding documents available for cross-referencing

## Conversation Guide

### Audit Checklist

Check each pair of documents for consistency:

1. **Data model <-> API**: Every table mutation has a matching endpoint
2. **API <-> UI**: Every endpoint is triggered by a UI element
3. **UI <-> User flows**: Every page/component has documented access points and flows
4. **Permissions <-> API**: Every endpoint enforces the permission matrix
5. **Integration <-> Data model**: Every hook payload matches available data
6. **Error states <-> User flows**: Every flow has error/empty handling
7. **Implementation order**: Dependencies are correct and complete
8. **Naming consistency**: Same terms used across all docs
9. **Activity logging <-> Data model**: Activity log table matches mutations, parent entity is correct
10. **Workspace seeding <-> Settings**: Seed function matches what 12-settings describes
11. **State management <-> Pages**: Cache invalidation plan covers every UI mutation
12. **Bulk operations <-> API <-> User flows**: Bulk endpoints match bulk flows, logging is per-entity
13. **Convention files <-> Plan overview**: Every file in the convention checklist is accounted for

Present findings by severity, resolve each with user.

### Research Actions

- Read all 16 completed documents systematically
- Cross-reference every table, endpoint, page, flow, permission, and hook
- Read `plans/archive/contacts-requirements/06-audit-findings.md` for reference

## Output Template

**File**: `plans/{{tool_name}}-requirements/15-audit-findings.md`

```
# {{tool_name}} -- Audit Findings

Cross-document consistency audit. Organized by severity.

---

## How to Run This Audit

Check each document against every other document for the 13 consistency checks listed above.

---

## Critical (fix before starting implementation)

### N. [Finding title]

**Files**: [which docs conflict]
**Problem**: ...
**Options**: ...
**Decision**: ...

---

## High (architectural decisions hard to change later)

---

## Medium (inconsistencies and gaps)

---

## Low (minor gaps, worth documenting)
```

## Completion Criteria

- [ ] All 13 consistency checks performed
- [ ] Every finding categorized by severity (Critical/High/Medium/Low)
- [ ] Critical findings resolved with explicit decisions
- [ ] High findings resolved or acknowledged with plan
- [ ] Medium findings documented
- [ ] Affected documents updated to reflect audit decisions
- [ ] `.progress.yaml` updated: audit-findings status set to complete
