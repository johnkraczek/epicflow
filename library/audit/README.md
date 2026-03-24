# Audit SOP

Codebase audit: parallel scan for pattern violations (consistency) and comprehensive checklist evaluation (domain).

## When to Use

- Periodic codebase health checks
- After major refactors or milestone completions
- Before releases to verify architectural consistency
- When onboarding to assess current state

## Expected Output

- **Audit report** with scores per category/domain and overall health score
- **Findings** with 5-part structure (What, Why, Original Intent, Correct Approach, Acceptance Criteria)
- **Action items** that feed into bug-fix or feature SOPs for remediation

## Steps

| # | Step | Description |
|---|------|-------------|
| 1 | **Initialize** | Create audit directory, get git context, build docs index, determine scope and mode |
| 2 | **Consistency Scan** | 5 parallel agents scan 24 categories for pattern violations (skip if scope is 'domain') |
| 3 | **Domain Audit** | Evaluate ~150 checks across 12 domains (skip if scope is 'consistency') |
| 4 | **Report** | Collect results, calculate scores, generate summary tables and learnings |
| 5 | **Action Items** | Review findings (guided or unattended), create bd issues for approved items |

## How to Run

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `audit_scope` | `full` (all), `consistency` (24-cat scan only), `domain` (12-domain checklist only), or a group name (`conventions`, `security`, `data`, `quality`, `docs`) | `full` |
| `audit_mode` | `guided` (present each finding, ask approve/reject/skip) or `unattended` (auto-approve all) | `guided` |

### Initialization

1. Create audit directory: `audit/{YYYY-MM-DD}/` (append `-02` etc. if date exists)
2. Create subdirectories: `findings/`, `action-items/`, `domain-results/`
3. Get git context: branch + short commit hash
4. Build docs index: read `docs/*.md`, map each to key topics for category-to-doc mapping
5. Determine scope and mode from variables

### Codebase Scopes

The codebase has three scopes that define data isolation and permission models:

| Scope     | Tool Directory    | Platform Module     | Permission Hook       |
|-----------|-------------------|---------------------|-----------------------|
| Workspace | tools/workspace/  | platform/workspace/ | workspace:permissions |
| Agency    | tools/agency/     | platform/agency/    | agency:permissions    |
| System    | tools/system/     | platform/system/    | (system-level)        |

Dual-scope tools live in `tools/platform/` (e.g., dashboard serves both workspace and agency contexts).

### Module Resolution Notes

Most `@ydtb/*` imports resolve through bun workspace symlinks and package exports fields. Only these require explicit aliases:
- Glob-pattern subpath exports (`./components/*`, `./contexts/*`, `./hooks/*`) -- in `vite.config.ts` `resolve.alias` and `tsconfig.json` paths
- `@ydtb/orpc` -- not a real package, maps to `platform/shell/server/orpc/index.ts`
- All Nitro aliases -- Nitro's resolver doesn't follow package exports
- Vitest test mocks -- intentional overrides for `@ydtb/db`, `@ydtb/orpc` in test configs

## Reference Files

- [consistency-categories.md](consistency-categories.md) -- All 24 scan categories with full rules
- [domain-checklist.md](domain-checklist.md) -- All 12 domains with ~150 checks
- [finding-format.md](finding-format.md) -- The 5-part finding structure with examples
- [scoring.md](scoring.md) -- Severity weights, score calculation, interpretation
