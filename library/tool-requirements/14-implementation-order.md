# Step 14: Implementation Order

## Purpose

Phased build plan with dependencies. Each phase can be a separate unit/PR, deployable and testable on its own.

## Prerequisites

- Step 13 (Settings) must be complete
- All design documents (steps 3-13) available for deriving build order

## Conversation Guide

### Exploration Strategy

- Derive from: data model -> schema phase, API -> backend phases, pages -> frontend phases, integration -> hook phases
- Foundation first: schema, types, shared components
- Backend before frontend: API endpoints before UI
- Core CRUD before advanced features
- Identify what can be parallelized
- Each phase should be deployable/testable on its own
- Mark clear dependencies between phases
- What's the minimum for end-to-end (vertical slice)?

### Research Actions

- Read `plans/archive/contacts-requirements/05-implementation-order.md` for reference
- Review all preceding docs to derive the correct build order

## Output Template

**File**: `plans/{{tool_name}}-requirements/13-implementation-order.md`

```
# {{tool_name}} -- Implementation Order

Phased build order with dependencies. Each phase can be a separate unit/PR.

---

## Phase 1: Foundation
<!-- Database, shared types, reusable components -- no UI changes yet -->

### 1.1 [Step name]
- ...

**Dependencies**: None
**Files**: ...

---

## Phase 2: [Next logical group]

### 2.1 [Step name]
- ...

**Dependencies**: 1.1
**Files**: ...

---

## Dependency Graph

Phase 1 (Foundation)
  +-- 1.1 [step] -> Phase 2
  +-- 1.2 [step] -> Phase 3
                       +-- Phase 4

<!-- Phase planning guidelines:
1. Foundation first -- schema, types, shared components
2. Backend before frontend -- API endpoints before UI
3. Core CRUD before advanced features
4. Independent phases can be parallelized
5. Each phase should be deployable/testable on its own
6. Mark clear dependencies between phases
-->
```

## Completion Criteria

- [ ] All deliverables from preceding docs mapped to implementation phases
- [ ] Foundation phase covers schema, types, and shared components
- [ ] Backend phases precede frontend phases
- [ ] Core CRUD precedes advanced features
- [ ] Dependencies between phases are explicit and correct
- [ ] Parallelizable phases identified
- [ ] Dependency graph shows full build order
- [ ] Each phase is independently deployable/testable
- [ ] `.progress.yaml` updated: implementation-order status set to complete
