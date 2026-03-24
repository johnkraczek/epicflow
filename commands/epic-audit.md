---
description: "EpicFlow — Scan codebase for pattern violations across documented conventions"
---

# EpicFlow Audit

Scan the codebase for consistency violations against documented patterns. Uses parallel subagents for speed.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Initialization

1. Read `.epic/settings.json` for unattended mode (if it exists)
2. Create audit directory: `audit/consistency/{YYYY-MM-DD}/` (append `-02` etc. if exists)
3. Create subdirectories: `findings/`, `action-items/`
4. Get git context: branch + short commit hash
5. Build docs index: glob `docs/*.md`, map each to key topics
6. Read the audit SOP: `.epic/library/audit/README.md` — contains the full scan process, categories, and finding format

## Categories

24 scan categories grouped into 5 agent groups:

**Group A — Convention & Structure**: Plugin conventions (CAT-01), Cross-tool boundaries (CAT-04), Naming/structure (CAT-06), UI sourcing (CAT-14)

**Group B — Data & Security**: Workspace isolation (CAT-02), Permissions (CAT-05), Route tiers (CAT-11), Env vars (CAT-13), Migrations (CAT-15)

**Group C — Code Quality**: Singletons (CAT-03), Type safety (CAT-07), Dependencies (CAT-08), Generated files (CAT-10), Error handling (CAT-16)

**Group D — Docs, Tests & Lifecycle**: Doc drift (CAT-09), Hook hygiene (CAT-12), Testing coverage (CAT-17), Activity logging (CAT-18)

**Group E — Security Hardening**: Session authority (CAT-19), Authentication hardening (CAT-20), oRPC security (CAT-21), Database security (CAT-22), Frontend security (CAT-23), API authorization (CAT-24)

Each agent reads `docs/*.md` for the canonical patterns to audit against. Agents scan for violations by comparing actual code to documented conventions.

### Scope-Aware Scanning

Read the project's documentation to understand scope boundaries, module resolution patterns, and package naming conventions. Look for documentation describing:

- Tool/module directory structure and scope boundaries (e.g., workspace vs agency vs system scopes)
- Permission registration patterns and which hooks they use
- Route registration tiers and conventions
- Cross-scope import rules and allowed boundaries
- Package naming conventions and workspace resolution

Agents should verify:
- Tools are in the correct scope directory for their data model
- Permission registrations use the correct scope hook
- Route registrations use the correct tier
- Cross-scope imports follow documented patterns (e.g., through shared schemas or hook systems, never direct tool-to-tool imports)

### Module Resolution

Read the project's documentation to understand module resolution patterns. Look for documentation describing:

- Package exports and workspace symlink resolution
- Alias configurations in build tools (Vite, webpack, etc.)
- Special module mappings (e.g., packages that map to non-standard paths)
- Test mock configurations and intentional overrides

### CAT-17: Testing Coverage Checks

CAT-17 goes beyond "do tests exist" — it checks whether the **right tests exist** for what each tool does. Read the project's testing documentation (if it exists) for the full conventions, then scan each tool against this checklist:

**Step 1: Inventory each tool.** For every tool in the project's tool directories, determine what it has:
- Pages/routes? → check for page components or route registrations
- API router? → check for API route definitions
- DB tables? → check for schema definitions, list each table
- Permission registrations? → check for permission hooks in plugin files
- Sub-concepts? → identify distinct entities

**Step 2: Check e2e coverage.** For each tool with pages:
- Must have E2E specs covering CRUD happy paths
- Each sub-concept needs its own spec file
- If tool registers permissions, must have permission boundary specs

**Step 3: Check integration/unit coverage.** For each tool with an API router:
- Each endpoint's happy path must have a test
- Each DB table's CRUD must have integration tests
- Broadcast/action wiring must have unit tests

**Step 4: Severity for missing tests:**
- Tool with pages but zero e2e specs → **major** (per tool)
- Tool with DB tables but no CRUD integration tests → **major** (per table)
- Tool with permission registrations but no permission e2e spec → **major**
- Sub-concept without dedicated test file (lumped into one giant spec) → **minor**
- Missing persistence verification in e2e (no navigate-away-and-back) → **minor**

### CAT-19 through CAT-24: Security Categories

_(Refer to the detailed scan rules in the project's security documentation. These categories cover: session authority, authentication hardening, oRPC security, database security, frontend security, and API authorization.)_

## Execution

Spawn 5 parallel subagents (one per group) using the Agent tool with `subagent_type: "consistency-auditor"`.

Each agent prompt:
```
You are scanning Group {X} ({name}) for consistency violations.

1. Read the docs index (docs/*.md) to understand the canonical patterns for your categories.
2. Scan the codebase for violations against those patterns.
3. For each category in your group, look for code that contradicts documented conventions.
4. For security categories (Group E): also read auth config, middleware chains, route handlers, and DB queries.

Categories: {list category names and what each checks}
Audit directory: {path}

For each violation found, write a finding file to:
  {audit_dir}/findings/CAT-{NN}-{slug}/finding-{NNN}.md

Each finding has 5 parts: What, Why It Matters, Original Intent, Correct Approach, Acceptance Criteria.

Return a summary table of findings per category.
```

## Reporting

1. Collect results from all 5 agents
2. Calculate scores: `100 - sum(severity_weights)` per category
   - Severity weights: critical=10, major=5, minor=2, info=0
3. Write `{audit_dir}/README.md` summary report
4. Analyze findings for process learnings (doc gaps, drift, themes)
5. Write `{audit_dir}/learnings.md`

## Action Items

- If `unattended: false`: present each finding, ask approve/reject/skip
- If `unattended: true`: auto-approve all findings (context sufficient — findings are mechanical pattern violations with clear acceptance criteria). Create issues with `agent-suggested` + `needs-review` labels for human triage.

For each approved item, create a bd issue:
```bash
bd create --title "Audit: {finding summary}" --type bug --description "{finding details}" --priority {2 for major, 3 for minor}
```

Write approved items to `{audit_dir}/action-items/`. These feed into `/epic-plan` or can be addressed individually using the bug-fix SOP (`.epic/library/bug-fix/README.md`).

## Finalize

Commit audit artifacts:
```
audit: consistency audit {YYYY-MM-DD} — {score}% ({finding_count} findings)
```

If action items exist, suggest `/epic-plan` to create an epic from them.

---

_EpicFlow Audit Command — powered by bd_
