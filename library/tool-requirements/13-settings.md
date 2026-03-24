# Step 13: Settings & Configuration

## Purpose

Tool-level settings, admin toggles, defaults, workspace initialization, and feature flags.

## Prerequisites

- Step 12 (Integration Points) must be complete
- `11-integration-points.md` available for broadcast-driven seeding pattern

## Conversation Guide

### Exploration Strategy

- What ships out of the box when a workspace first uses this tool?
- What can workspace admins configure? Where in the UI?
- Any per-user preferences (not per-workspace)?
- What gets seeded on workspace creation? Is seeding idempotent?
- Any feature flags for gradual rollout?
- Seed function triggered by `workspace:created` broadcast

### Research Actions

- Read `docs/09-cross-tool-communication.md` for broadcast-driven seeding pattern
- Check existing tool seed functions (`tools/*/src/lib/seed.ts`)

## Output Template

**File**: `plans/{{tool_name}}-requirements/12-settings-and-configuration.md`

```
# {{tool_name}} -- Settings & Configuration

---

## Default Settings

| Setting | Default Value | Description |
|---------|--------------|-------------|
| ... | ... | ... |

---

## Admin-Configurable Settings

| Setting | Type | Options | Location | Notes |
|---------|------|---------|----------|-------|
| ... | ... | ... | ... | ... |

---

## User-Level Preferences

| Preference | Type | Default | Stored In |
|-----------|------|---------|-----------|
| ... | ... | ... | ... |

---

## Workspace Initialization

**Triggered by**: workspace:created broadcast

**Seeded data**: ...

**Seed function**: lib/seed.ts
**Idempotent**: Yes / No

<!-- Pattern in plugin.ts:
hooks.onBroadcast('workspace:created', async ({ workspaceId }) => {
  await seedDefaults(db, workspaceId)
})

Seed function in lib/seed.ts:
export async function seedDefaults(db, workspaceId) {
  await db.insert(myTable).values([
    { workspaceId, name: 'Default Item', isBuiltIn: true },
  ]).onConflictDoNothing()
}

Also register in api/router.ts for server-side:
serverHooks.onBroadcast('workspace:created', async ({ workspaceId }) => {
  await seedDefaults(db, workspaceId)
})
-->

---

## Feature Flags / Toggles

| Flag | Description | Default | Notes |
|------|-------------|---------|-------|
| N/A | No feature flags for MVP | | |
```

## Completion Criteria

- [ ] Default settings documented
- [ ] Admin-configurable settings listed with types and UI location
- [ ] User-level preferences documented if applicable
- [ ] Workspace initialization defined (seeded data, trigger, idempotency)
- [ ] Seed function pattern documented
- [ ] Feature flags listed or explicitly marked N/A
- [ ] `.progress.yaml` updated: settings-and-configuration status set to complete
