# Step 15: Testing Plan

## Purpose

Unit, integration, and E2E test targets. Define testing strategy, fixture helpers, selector strategy, and test-to-phase mapping.

## Prerequisites

- Step 14 (Implementation Order) must be complete
- All design documents and implementation phases available for test mapping

## Conversation Guide

### Exploration Strategy

- Follow TDD Red-Green-Verify methodology
- What pure functions need unit tests? (No DB, no API, no React)
- What API handlers need integration tests? (Real test database)
- What critical user flows need E2E tests? (Browser + full stack)
- Workspace isolation tests (records in workspace A not visible in B)
- Permission boundary tests (different roles see different things)
- What fixture helpers are needed for E2E? (API-seeded prerequisite data)
- Which elements need data-testid attributes?
- Map tests to implementation phases

### Testing Stack

| Layer | Tool | Environment | Location |
|-------|------|-------------|----------|
| Unit | Vitest | Node (no DOM) | tools/{{tool_name}}/src/__tests__/ |
| Integration | Vitest | Node + test DB | tools/{{tool_name}}/src/__tests__/integration/ |
| E2E | Playwright | Browser + full stack | tools/{{tool_name}}/e2e/ |

### E2E Mocking Boundary

- Real browser, real Vite dev server, real PostgreSQL
- Only mock true external services (email, file storage, payment APIs)
- API seeding: prerequisite data via oRPC calls using `page.request`, NOT via UI clicks
- oRPC: `POST /api/rpc/module/action` with `{ data: { json: input } }`
- better-auth: `POST /api/auth/...` with `{ data: { ... } }`

### Research Actions

- Read `docs/11-testing.md` for canonical patterns
- Read `plans/archive/contacts-requirements/07-testing-plan.md` for reference
- Check `e2e/fixtures/test-fixtures.ts` for shared fixture patterns

## Output Template

**File**: `plans/{{tool_name}}-requirements/14-testing-plan.md`

```
# {{tool_name}} -- Testing Plan

Testing strategy following TDD: Red -> Green -> Verify.

---

## Testing Stack

| Layer | Tool | Environment | Location |
|-------|------|-------------|----------|
| Unit | Vitest | Node (no DOM) | tools/{{tool_name}}/src/__tests__/ |
| Integration | Vitest | Node + test DB | tools/{{tool_name}}/src/__tests__/integration/ |
| E2E | Playwright | Browser + full stack | tools/{{tool_name}}/e2e/ |

---

## TDD Workflow

1. Red -- Write test first, run it, confirm it fails for the right reason
2. Green -- Implement minimum code to make it pass
3. Verify -- Break implementation intentionally, confirm test catches it

---

## Unit Tests

### N. [Function/Module Name]

tools/{{tool_name}}/src/lib/[module].ts
tools/{{tool_name}}/src/__tests__/[module].test.ts

**Tests**: ...

---

## Integration Tests

### N. [Feature] CRUD

tools/{{tool_name}}/src/__tests__/integration/[feature].test.ts

**Tests**: ...

### N. Workspace Isolation

tools/{{tool_name}}/src/__tests__/integration/workspace-isolation.test.ts

**Tests**:
- Records in workspace A not visible in workspace B
- Operations in workspace A don't affect workspace B

---

## E2E Tests

tools/{{tool_name}}/e2e/
+-- fixtures.ts          <- per-tool fixture extending shared authenticatedPage
+-- [feature].spec.ts    <- critical path tests
+-- [feature]-permissions.spec.ts  <- permission boundary tests

### Mocking Boundary
Real full stack. Only mock external services.
API seeding via oRPC: page.request.post('/api/rpc/module/action', { data: { json: input } })

### Per-Tool Fixture

**Fixture helpers needed**:

| Helper | oRPC Endpoint | Creates |
|--------|--------------|---------|
| ... | ... | ... |

### Selector Strategy

Priority: getByRole > getByLabel > getByPlaceholder > getByTestId
Avoid: CSS selectors, DOM position, text content that changes with data.

**Elements needing data-testid**:

| Element | Test ID | Why role/label won't work |
|---------|---------|--------------------------|
| ... | ... | ... |

### Critical Path Flows (as Owner)

| Test | User Flow Ref | Prerequisite (API-seeded) | Asserts |
|------|--------------|---------------------------|---------|
| Shows empty state | -- | None | Empty state message visible |
| Create record | Flow N | None | Toast, record in list |
| Edit record | Flow N | 1 seeded record | Toast, updated values |
| Delete record | Flow N | 1 seeded record | Toast, record removed |
| Search/filter | Flow N | 2+ seeded records | Filtered list |

**Persistence checks**:
- After create: navigate away, return, record still visible
- After edit: refresh page, updated values still shown

**Deep links**:
| URL Pattern | Expected Behavior |
|-------------|-------------------|
| /{{tool_name}} | Main list loads with data |
| /{{tool_name}}/$id | Detail view for specific record |

### Permission Boundary Tests

| Test | Role | Expected Behavior |
|------|------|-------------------|
| Full CRUD works | Member with full perms | Same as critical path |
| Create denied | Member without create | Button hidden, API 403 |
| Navigation hidden | Member without view | Sidebar item not rendered |

### Cross-Tool Flows

| Test | Tools Involved | Flow | Asserts |
|------|---------------|------|---------|
| N/A or specify | ... | ... | ... |

### Empty / First-Run State

| Test | What's shown | Call to action |
|------|-------------|----------------|
| First visit | Empty state + message | Primary create button visible |

---

## Tests per Implementation Phase

| Phase | Tests to Write |
|-------|---------------|
| Phase 1 | Integration: workspace isolation, default seeding |
| Phase 2 | ... |

---

## What We Skip
- Testing Drizzle ORM behavior
- Testing React component rendering (Playwright's job)
- Testing shadcn/ui components
- Snapshot tests
- 100% coverage targets
```

## Completion Criteria

- [ ] Testing stack defined (unit, integration, E2E)
- [ ] TDD workflow documented
- [ ] Unit test targets identified (pure functions)
- [ ] Integration test targets identified (API handlers, workspace isolation)
- [ ] E2E test targets identified (critical flows, permissions)
- [ ] Fixture helpers defined for API seeding
- [ ] Selector strategy documented with data-testid list
- [ ] Critical path flows mapped to user flow references
- [ ] Permission boundary tests defined
- [ ] Tests mapped to implementation phases
- [ ] Explicit "What We Skip" list
- [ ] `.progress.yaml` updated: testing-plan status set to complete
