# Step 12: Integration Points

## Purpose

Platform hooks emitted/consumed, cross-tool dependencies, action contracts, merge keys, and shared UI components.

## Prerequisites

- Step 11 (API Endpoints) must be complete
- `10-api-endpoints.md` available for endpoint list and mutation hooks

## Conversation Guide

### Exploration Strategy

- What broadcasts does this tool emit? (After create/update/delete mutations)
- What broadcasts does this tool consume from other tools?
- Does this tool provide actions (RPC) for other tools to call?
- Does this tool call actions from other tools?
- Any cross-tool data dependencies? (NEVER import another tool's schema directly)
- Does this tool provide merge keys / template variables?
- Any shared UI components provided to or consumed from other tools?
- Server-side hook registration needed? (Use scoped API with HMR cleanup)

### Hook System Primitives

- **Actions**: request/response RPC (exactly one handler). For cross-tool data operations.
  - Register: `hooks.addAction('[tool]:[action]', handler)`
  - Call: `await hooks.doAction('[tool]:[action]', payload)`
  - Contract: `tools/[tool]/src/actions.ts` with typed input/output
- **Broadcasts**: fire-and-forget pub/sub (zero or many). For mutation events.
  - Emit: `await hooks.broadcast('[tool]:[event]', payload)`
  - Listen: `hooks.onBroadcast('[tool]:[event]', handler)`
- **Filters**: value transformation pipeline. For collecting registrations.
  - Apply: `hooks.applyFilterSync('filter:name', initialValue)`
  - Register: `hooks.addFilter('filter:name', transformer)`

### Research Actions

- Read `docs/01-hook-system.md` for Actions, Broadcasts, and Filters
- Read `docs/02-plugin-registration.md` for plugin hook registration
- Read `docs/09-cross-tool-communication.md` for cross-tool patterns
- Check existing tool `plugin.ts` files for `registerHook()` declarations

## Output Template

**File**: `plans/{{tool_name}}-requirements/11-integration-points.md`

```
# {{tool_name}} -- Integration Points

---

## Hooks This Tool Declares

// In plugin.ts register():
hooks.registerHook('{{tool_name}}:created')
hooks.registerHook('{{tool_name}}:updated')
hooks.registerHook('{{tool_name}}:deleted')

---

## Broadcasts This Tool Emits

| Hook Name | Trigger | Payload |
|-----------|---------|---------|
| {{tool_name}}:created | After create | { id, workspaceId } |
| {{tool_name}}:updated | After update | { id, workspaceId } |
| {{tool_name}}:deleted | After delete | { id, workspaceId } |

---

## Broadcasts This Tool Consumes

| Hook Name | Source Tool | Handler | Purpose |
|-----------|-----------|---------|---------|
| workspace:created | Platform | Seed defaults | Create default data for new workspace |

---

## Actions This Tool Provides

| Action Name | Input | Output | Purpose |
|-------------|-------|--------|---------|
| ... | ... | ... | ... |

<!-- Action contract in tools/{{tool_name}}/src/actions.ts:
export type MyToolActions = {
  '{{tool_name}}:findOrCreate': { input: {...}, output: {...} }
}
Register: hooks.addAction('{{tool_name}}:findOrCreate', async (input) => { ... })
-->

---

## Actions This Tool Calls

| Action Name | Source Tool | Purpose |
|-------------|-----------|---------|
| ... | ... | ... |

---

## Cross-Tool Data Dependencies

<!-- NEVER import another tool's schema directly. Use oRPC or hook actions. -->

| Direction | Other Tool | Data | How |
|-----------|-----------|------|-----|
| Reads from | ... | ... | Hook action or oRPC API |
| Writes to | ... | ... | Broadcast emission |

---

## Server-Side Hook Registration

<!-- If API router needs hooks, use scoped API with HMR cleanup:
const SERVER_PLUGIN_ID = '{{tool_name}}-server'
const serverHooks = hooks.createScopedAPI(SERVER_PLUGIN_ID)
if (import.meta.hot) { import.meta.hot.dispose(() => { hooks.removeScopedAPI(SERVER_PLUGIN_ID) }) }
serverHooks.addAction('{{tool_name}}:findOrCreate', async (input) => { ... })
-->

---

## Merge Keys / Template Variables

| Key Format | Example | Resolves To |
|------------|---------|------------|
| ... | ... | ... |

---

## Shared UI Components

| Component | Package | Direction | Used By |
|-----------|---------|-----------|---------|
| ... | @ydtb/ui | Provides / Consumes | ... |
```

## Completion Criteria

- [ ] All hook declarations listed (registerHook calls)
- [ ] All broadcasts emitted by this tool documented with payloads
- [ ] All broadcasts consumed from other tools documented
- [ ] Action contracts defined if providing cross-tool RPC
- [ ] Actions called from other tools documented
- [ ] Cross-tool data dependencies mapped (no direct schema imports)
- [ ] Server-side hook registration pattern documented if needed
- [ ] Merge keys / template variables listed if applicable
- [ ] Shared UI components documented with direction (provides/consumes)
- [ ] `.progress.yaml` updated: integration-points status set to complete
