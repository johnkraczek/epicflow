# Consistency Audit Categories

24 scan categories organized into 5 agent groups. Each agent scans assigned categories for violations of documented architectural patterns.

---

## Group A -- Convention & Structure

Categories: CAT-01, CAT-04, CAT-06, CAT-14

### CAT-01: Plugin Conventions

Scan rules:
- Every tool in `tools/` must have `src/plugin.ts` with valid `definePlugin()` call
- `definePlugin()` must include `id`, `name`, and `register` function
- `register()` must receive scoped HookAPI
- Plugin IDs must be unique across all tools
- Dependencies (if declared) must reference existing plugin IDs with no cycles
- Hook registrations must match declared platform hooks in `declarePlatformHooks()`

### CAT-04: Cross-Tool Boundaries

Scan rules:
- Tools must NOT import from other tools directly (no `tools/A` importing from `tools/B`)
- Tools must NOT import from platform internals (`platform/src/`)
- Platform must NOT import from tool internals (`tools/*/src/`)
- Packages must NOT import from platform or tools
- Cross-tool communication must go through oRPC API or the hook system
- Cross-scope imports must go through `@ydtb/db/schema` (unified tables) or hooks, never direct tool-to-tool
- Verify tools are in the correct scope directory for their data model

### CAT-06: Naming & Structure

Scan rules:
- React components use PascalCase naming and PascalCase filenames
- Utility files use kebab-case
- Hook files use camelCase (e.g., `useUserQuery.ts`)
- Convention files (`plugin.ts`, `router.ts`, `schema.ts`) exist in expected locations within tool directories
- Import paths use aliases (`@/` for local, `@ydtb/*` for packages), not deep relative paths (`../../../`)
- Generated files (`.gen.ts`) have AUTO-GENERATED header comment

### CAT-14: UI Sourcing

Scan rules:
- UI components should come from the shared `@ydtb/ui` package
- No duplicate component implementations across tools
- Theme system (appearance/accent/pattern) applied consistently
- Portal system (sidebar + header injection) used for tool-specific UI extensions

---

## Group B -- Data & Security

Categories: CAT-02, CAT-05, CAT-11, CAT-13, CAT-15

### CAT-02: Workspace Isolation

Scan rules:
- Every tool table must include `workspace_id` column
- All data queries must filter by `workspace_id` from context
- RLS policies must exist and be enabled for all tool tables
- Workspace middleware must reject requests without valid workspace context
- Permission registrations must use correct scope hook (`workspace:permissions` vs `agency:permissions`)

### CAT-05: Permissions

Scan rules:
- Permission registrations use correct scope hook
- Protected routes enforce authentication middleware
- Workspace-scoped endpoints require workspace context
- No public procedures expose private data

### CAT-11: Route Tiers

Scan rules:
- Routes registered on correct tier: dashboard (workspace-scoped), fullscreen (auth but no sidebar), authenticated (auth only), public (no auth)
- Route registrations use correct tier (`platform:routes` vs `platform:routes:agency`)
- `ProtectedRoute` redirects unauthenticated users to `/login`
- `WorkspaceGate` fires hooks and redirects when no workspace is active

### CAT-13: Environment Variables

Scan rules:
- `.env` files NOT committed to source control
- `.gitignore` properly excludes `.env` patterns
- `.env.example` contains all required vars with placeholder values (no real secrets)
- `VITE_` prefix only on client-safe variables (no DB URLs, API keys, or secrets)
- Database credentials never appear in console output or log statements
- `BETTER_AUTH_SECRET` is at least 32 characters

### CAT-15: Migrations

Scan rules:
- Migrations directory exists with sequentially ordered files
- Drizzle schema matches actual database state (running `db:generate` produces no changes)
- `drizzle.config.ts` schema paths cover all tool schemas
- Schema imports use correct package path (`@ydtb/db`), not directly from `drizzle-orm/pg-core`
- `tools.gen.ts` re-exports all tool schemas

---

## Group C -- Code Quality

Categories: CAT-03, CAT-07, CAT-08, CAT-10, CAT-16

### CAT-03: Singletons

Scan rules:
- React must be installed as a single instance (no duplicates in `node_modules`)
- TanStack Query imported ONLY from `@ydtb/query-client`, never directly from `@tanstack/react-query` in `tools/` or `platform/`
- `QueryClientProvider` wraps entire app tree from `@ydtb/query-client` -- no duplicate providers
- No duplicate library instances in production bundle

### CAT-07: Type Safety

Scan rules:
- TypeScript strict mode enabled in `tsconfig.json` (`"strict": true`)
- `bun run check` passes with zero errors
- No `any` types in production code (exceptions must have documented inline comments)
- No unused imports or variables
- tsconfig project references point to valid packages

### CAT-08: Dependencies

Scan rules:
- All internal packages use `workspace:*` resolution
- No conflicting peer dependency versions (`bun install` shows no peer dep warnings)
- `bun.lock` file committed and up to date (`bun install` produces no changes to `bun.lock`)
- Package versions consistent across monorepo (React, TypeScript, etc. same version everywhere)
- `devDependencies` vs `dependencies` correctly categorized
- `@types/*` packages in `devDependencies` only
- No deprecated packages
- No unnecessary dependencies (listed but never imported)

### CAT-10: Generated Files

Scan rules:
- Codegen outputs up to date (`bun run generate` produces no git diff)
- All `.gen.ts` files have AUTO-GENERATED header comment
- `.gen.ts` files not manually edited (check git blame)
- `registry.gen.ts` imports match `tools/` directory (all tools with `src/plugin.ts`)
- `router.gen.ts` imports match tools with `src/api/router.ts`
- `tools.gen.ts` imports match tools with `src/db/schema.ts`

### CAT-16: Error Handling

Scan rules:
- API errors use `ORPCError` with standard codes (`NOT_FOUND`, `UNAUTHORIZED`, `BAD_REQUEST`, `FORBIDDEN`, `INTERNAL_SERVER_ERROR`)
- Async code uses proper try/catch blocks
- React code uses error boundaries (error boundaries catch component errors, display fallback UI)
- No unhandled promise rejections
- Error responses don't leak internal details (no stack traces, file paths, or implementation details)
- `useEffect` hooks with subscriptions/timers/event listeners return cleanup functions
- No `console.log` in production code (`console.warn`/`error` only for genuine issues)

---

## Group D -- Docs, Tests & Lifecycle

Categories: CAT-09, CAT-12, CAT-17, CAT-18

### CAT-09: Documentation Drift

Scan rules:
- `ARCHITECTURE.md` reflects current architecture (tech stack, structure, commands, constraints)
- `docs/` specs align with implementation (divergences documented)
- Hook names in docs match `declarePlatformHooks()` code declarations
- Route tier count and descriptions accurate in docs
- No references to deprecated patterns (Module Federation, micro-frontend, old tool system)
- "Last verified" dates within 2 weeks of current date
- Environment variable documentation complete
- Tool creation guide produces working tool

### CAT-12: Hook Hygiene

Scan rules:
- All platform hooks declared in `declarePlatformHooks()`
- Every dispatched hook has a corresponding declaration
- Hook names, argument types, and return types match between dispatch and declaration
- `platform:boot` action fires after all plugins register
- Both action hooks (side effects) and filter hooks (data transformation) dispatch correctly

### CAT-17: Testing Coverage

Scan rules -- this goes beyond "do tests exist" to check if the RIGHT tests exist:

**Step 1: Inventory each tool.** For every tool in `tools/{scope}/{name}/`:
- Pages/routes? Check for `src/pages/` or route registrations in `plugin.ts`
- API router? Check for `src/api/router.ts`
- DB tables? Check for `src/db/schema.ts`, list each table
- Permission registrations? Check for `workspace:permissions` or `agency:permissions` in `plugin.ts`
- Sub-concepts? Identify distinct entities (e.g., contacts has: contacts, custom fields, notes, trash)

**Step 2: Check e2e coverage.** For each tool with pages:
- Must have `{tool}/e2e/{feature}.spec.ts` covering CRUD happy paths
- Each sub-concept needs its own spec file: `{tool}/e2e/{feature}-{concept}.spec.ts`
- If tool registers permissions, must have `{tool}/e2e/{feature}-permissions.spec.ts`

**Step 3: Check integration/unit coverage.** For each tool with an API router:
- Each endpoint's happy path must have a test
- Each DB table's CRUD must have integration tests
- Broadcast/action wiring must have unit tests

**Step 4: Severity for missing tests:**
- Tool with pages but zero e2e specs -> major (per tool)
- Tool with DB tables but no CRUD integration tests -> major (per table)
- Tool with permission registrations but no permission e2e spec -> major
- Sub-concept without dedicated test file (lumped into one giant spec) -> minor
- Missing persistence verification in e2e (no navigate-away-and-back) -> minor

**Additional testing checks:**
- Test runner (vitest) configured and functional
- Test isolation: fresh QueryClient per test
- Mock patterns established for oRPC
- No tests depend on external services
- Test commands (`bun run test`) work from root
- Test files co-located or in `__tests__` directories
- No skipped tests without explanation

### CAT-18: Activity Logging

Scan rules:
- Audit trails exist for critical operations (user creation, workspace changes, permission changes)
- Activity logs include actor, action, target, timestamp
- Sensitive data not logged (passwords, tokens, secrets)

---

## Group E -- Security Hardening

Categories: CAT-19 through CAT-24

### CAT-19: Session Authority

Scan rules:
- Session cookies have `httpOnly` flag set
- CSRF protection enabled in better-auth configuration
- Session tokens not exposed to client-side JavaScript
- Session expiry and renewal configured appropriately

### CAT-20: Authentication Hardening

Scan rules:
- Auth middleware rejects unauthenticated requests (returns 401/403)
- Password minimum requirements enforced
- `BETTER_AUTH_SECRET` meets 32-character minimum
- No secrets in source control (`.env` files not committed)
- `trustedOrigins` list restrictive (no wildcards in production)
- Rate limiting considerations documented

### CAT-21: oRPC Security

Scan rules:
- Middleware chain enforced: base -> auth -> workspace
- Authed builder used for all tool procedures (never raw `baseProcedure`)
- Input validation (Zod schemas) on all mutations
- Error responses use `ORPCError` with appropriate codes
- API procedures filter by `workspace_id`

### CAT-22: Database Security

Scan rules:
- No SQL injection vectors (all queries use Drizzle ORM parameterized queries, no raw string concatenation)
- RLS policies defined and enabled for all tool tables
- Database credentials not logged
- No raw SQL outside of migration files
- Foreign keys reference correct tables with ON DELETE behavior

### CAT-23: Frontend Security

Scan rules:
- No XSS vectors (no `dangerouslySetInnerHTML`, user input properly escaped via React JSX)
- `VITE_` prefix only on client-safe env vars
- Error responses don't leak internal details to the browser
- `ProtectedRoute` redirects unauthenticated users

### CAT-24: API Authorization

Scan rules:
- All data-returning procedures filter by `workspace_id` from context
- Workspace middleware rejects missing workspace context
- No public procedures expose private data
- Authed procedure builder used for all tool endpoints
