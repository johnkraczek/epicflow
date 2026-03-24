# Step 3: Data Model

## Purpose

Design database tables, columns, types, and relations. Define shared TypeScript types, platform hooks, and entity relationships.

## Prerequisites

- Step 2 (Plan Overview) must be complete
- `01-plan-overview.md` available for reference (especially scope, optional features, and "What Exists Today")

## Conversation Guide

### Exploration Strategy

- What are the core entities? What are their relationships?
- What fields does each entity need? Which are required vs optional?
- Does this need soft-delete (deletedAt column)?
- Does this need activity logging? What's the parent entity for the activity feed?
- What are the unique constraints? (workspace-scoped uniqueness uses composite indexes)
- What enums or status fields are needed? Define as TypeScript union types.
- What broadcast events should fire on mutations?
- Does this need action contracts for cross-tool RPC?

### Research Actions

- Read `docs/06-database.md` for canonical schema patterns
- Read existing schema files in `tools/*/src/db/schema.ts` for patterns
- Verify workspace isolation pattern (workspaceId FK with cascade delete)
- Read `docs/14-activity-logging.md` if activity logging is needed
- Read `plans/archive/contacts-requirements/01-data-model.md` for reference

## Output Template

**File**: `plans/{{tool_name}}-requirements/02-data-model.md`

```
# {{tool_name}} -- Data Model

All tables live in tools/{{tool_name}}/src/db/schema.ts. They import from @ydtb/db/pg-core.
Every table has workspaceId with FK to organization.id (cascade delete).
Primary keys use text('id') with generateId() from @ydtb/db/id (nanoid-based 12-char alphanumeric).

---

## Table N: [tableName]

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | text | NO | generateId() | PK |
| workspaceId | text | NO | -- | FK -> organization.id, CASCADE |
| ... | ... | ... | ... | ... |
| createdAt | timestamp | NO | now() | |
| updatedAt | timestamp | NO | now() | |

**Indexes**: ...
**Unique constraints**: ...

<!-- Drizzle schema pattern:
import { pgTable, text, timestamp } from '@ydtb/db/pg-core'
import { generateId } from '@ydtb/db/id'
import { organization } from '@ydtb/db/schema'

export const myTable = pgTable('myTable', {
  id: text('id').primaryKey().$defaultFn(() => generateId()),
  workspaceId: text('workspaceId')
    .notNull()
    .references(() => organization.id, { onDelete: 'cascade' }),
  createdAt: timestamp('createdAt').defaultNow().notNull(),
  updatedAt: timestamp('updatedAt').defaultNow().notNull(),
})

Column naming: camelCase (workspaceId, createdAt, deletedAt).
Workspace-scoped unique constraints use composite indexes:
(table) => [uniqueIndex('myTable_workspaceId_slug_idx').on(table.workspaceId, table.slug)]
-->

<!-- If soft-delete needed, add deletedAt:
| deletedAt | timestamp | YES | null | Soft-delete marker |
List queries filter: isNull(table.deletedAt)
Trash queries filter: isNotNull(table.deletedAt)
-->

---

## Activity Logging

**Needs activity log**: Yes / No

<!-- If Yes:
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | text | NO | generateId() | PK |
| workspaceId | text | NO | -- | FK -> organization.id, CASCADE |
| [parentEntity]Id | text | NO | -- | FK -> [parentTable].id, CASCADE |
| userId | text | NO | -- | FK -> user.id |
| action | text | NO | -- | 'created', 'updated', 'deleted', 'restored', 'field_changed' |
| metadata | jsonb | YES | null | Field diffs for updates |
| createdAt | timestamp | NO | now() | |

Query helpers in lib/activity-queries.ts:
- insertActivity(db, { workspaceId, [parentEntity]Id, userId, action, metadata })
- getActivities(db, { workspaceId, [parentEntity]Id, limit, offset })
-->

---

## Shared TypeScript Types

<!-- Define shared types. Prefer Drizzle $inferSelect/$inferInsert for row types.
     Only define manual types for enums, statuses, or shapes not derived from schema. -->

---

## Platform Hooks

<!-- Hook system primitives:
  - Actions -- request/response RPC (exactly one handler). Cross-tool RPC.
    hooks.doAction('[tool]:[event]', payload) -> returns value
    hooks.addAction('[tool]:[event]', handler) -> registers handler
  - Broadcasts -- fire-and-forget pub/sub (zero or many listeners). Mutation events.
    hooks.broadcast('[tool]:[event]', payload) -> notifies all
    hooks.onBroadcast('[tool]:[event]', handler) -> subscribes
  - Filters -- value transformation pipeline. Collecting registrations.
    hooks.applyFilterSync('filter:name', initialValue)
    hooks.addFilter('filter:name', transformer)
-->

**Hook declarations** (in plugin.ts during register()):
<!-- hooks.registerHook('[tool]:[event]') -->

**Hook emissions** (in API handlers after mutations):
<!-- await hooks.broadcast('[tool]:[event]', { id, workspaceId, userId }) -->

**Action contracts** (for cross-tool RPC, in actions.ts):
<!-- export type MyToolActions = { '[tool]:findOrCreate': { input: {...}, output: {...} } } -->

---

## Relationship Diagram

organization (better-auth)
  +-- [tables and relationships]
  +-- user (better-auth)
```

## Completion Criteria

- [ ] All tables defined with columns, types, nullability, defaults, and notes
- [ ] Every table has workspaceId FK with cascade delete
- [ ] Indexes and unique constraints specified
- [ ] Activity logging decision made (yes/no) with table if yes
- [ ] Shared TypeScript types defined (enums, statuses)
- [ ] Platform hooks declared (broadcasts for all mutations)
- [ ] Action contracts defined if cross-tool RPC needed
- [ ] Relationship diagram shows all entity connections
- [ ] `.progress.yaml` updated: data-model status set to complete
