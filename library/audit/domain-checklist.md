# Domain Audit Checklist

12 domains, ~150 checks. Each check has a defined severity, verification method, and evidence requirements.

---

## Domain 01: Architecture (13 checks)

Monorepo structure, package organization, dependency graph.

### [ARCH-001] Monorepo workspace declarations match actual directories
- **Severity**: critical
- **What**: Verify workspaces array in root package.json matches all actual directories on disk.
- **Why**: Workspace declarations tell Turborepo and package managers which packages to manage. Mismatches cause build failures and inconsistent dependency resolution.
- **How**: Compare `package.json` workspaces with actual `platform/`, `tools/*/`, `packages/*/` directories.

### [ARCH-002] All tools discoverable by codegen
- **Severity**: critical
- **What**: Every directory in tools/ must be discoverable and processed by the codegen script.
- **Why**: The codegen script builds cross-tool indexes and type definitions. Tools missing from codegen cannot be properly integrated.
- **How**: Run `bun run generate`, verify all tools/ subdirectories appear in generated files with no warnings.

### [ARCH-003] Package exports match actual file paths
- **Severity**: major
- **What**: Each "exports" field in package.json files must point to files that actually exist on disk.
- **Why**: Export path mismatches break module resolution and cause import errors.
- **How**: For each package, check that exported paths exist on disk.

### [ARCH-004] No orphaned packages
- **Severity**: minor
- **What**: Every package in packages/ is imported and used by at least one workspace.
- **Why**: Orphaned packages waste build time and indicate incomplete cleanup.
- **How**: For each package, grep for its `@ydtb/*` import in `platform/` and `tools/`.

### [ARCH-005] tsconfig project references correct
- **Severity**: major
- **What**: TypeScript project references must point to valid packages with valid tsconfig.json files.
- **Why**: Incorrect references cause type checking failures and prevent incremental builds.
- **How**: Verify each referenced path exists and has a valid tsconfig.json. Run `bun run check`.

### [ARCH-006] Turborepo pipeline covers all tasks
- **Severity**: major
- **What**: turbo.json must define pipeline tasks for: build, dev, check, test, generate.
- **Why**: Missing tasks cause inefficient builds and incorrect parallelization.
- **How**: Check turbo.json for all required task definitions.

### [ARCH-007] Root scripts functional
- **Severity**: critical
- **What**: Root package.json scripts (dev, build, check, test, generate) execute without immediate errors.
- **Why**: Root scripts are primary entry points for developers and CI/CD. Broken scripts block everything.
- **How**: Run each root script with --help or briefly to verify no immediate failures.

### [ARCH-008] Platform/tools/packages separation respected
- **Severity**: major
- **What**: Three-layer architecture: platform is shell, tools are features, packages are shared utilities. Each layer imports only from layers below.
- **Why**: Clear separation prevents tight coupling and supports multi-tenant plugin architecture.
- **How**: Grep for cross-layer imports (`platform` importing from `tools/`, `tools` importing from `platform/src/`, `packages` importing from either).

### [ARCH-009] No cross-layer violations
- **Severity**: major
- **What**: Tools must not import from platform internals; platform must not import from tool internals. Cross-tool communication goes through oRPC API.
- **Why**: Cross-layer violations create hidden dependencies that break tool isolation.
- **How**: grep for `from.*platform/src` in `tools/`, `from.*tools/[^/]*/src` in `platform/src/`.

### [ARCH-010] Codegen outputs up to date with source
- **Severity**: critical
- **What**: Generated files (.gen.ts) must reflect current source definitions. Running codegen should produce no changes.
- **Why**: Stale generated files cause type mismatches, outdated schemas, and API contract violations.
- **How**: Run `bun run generate` then `git diff --exit-code`. Should exit 0.

### [ARCH-011] Generated files have AUTO-GENERATED header
- **Severity**: minor
- **What**: All .gen.ts files should contain an "AUTO-GENERATED" or "auto-generated" comment header.
- **Why**: The header signals files are generated and should not be edited manually.
- **How**: `grep -L "AUTO-GENERATED|auto-generated"` in all `*.gen.ts` files.

### [ARCH-012] No circular package dependencies
- **Severity**: major
- **What**: Packages must not have circular dependency chains (A -> B -> A).
- **Why**: Circular dependencies prevent proper TypeScript compilation and cause runtime module resolution errors.
- **How**: Review package.json dependencies and trace imports for cycles.

### [ARCH-013] Convention files follow expected patterns
- **Severity**: minor
- **What**: Convention files (plugin.ts, router.ts, schema.ts) exist in expected locations within tool directories.
- **Why**: Convention files are discovered by codegen and define tool metadata, routes, and data schemas.
- **How**: Check each tool for expected convention files in standard locations.

---

## Domain 02: Code Quality (14 checks)

Linting, formatting, type safety, dead code, patterns.

### [QUAL-001] ESLint passes with zero warnings
- **Severity**: major
- **What**: Linter runs across entire codebase with no errors or warnings.
- **How**: Run `bun run lint`. Exit code should be 0.

### [QUAL-002] Prettier formatting consistent across all files
- **Severity**: minor
- **What**: All source files formatted consistently per Prettier configuration.
- **How**: Run `bun run format:check`. All files should pass.

### [QUAL-003] TypeScript strict mode enabled and passing
- **Severity**: critical
- **What**: tsconfig.json has "strict": true and type checker passes with zero errors.
- **How**: Confirm tsconfig.json strict mode. Run `bun run check` with zero errors.

### [QUAL-004] No `any` types in production code
- **Severity**: major
- **What**: No uses of `any` type in production source without documented exceptions.
- **How**: grep for `: any` and `as any` in `platform/src/`, `tools/*/src/`, `packages/*/src/`.

### [QUAL-005] No unused imports or variables
- **Severity**: minor
- **What**: TypeScript compiler and ESLint report no unused imports or variables.
- **How**: Review output from `bun run check` and `bun run lint`.

### [QUAL-006] useEffect cleanup functions present where needed
- **Severity**: major
- **What**: All useEffect hooks with subscriptions, timers, event listeners must return cleanup functions.
- **Why**: Missing cleanup causes memory leaks, duplicate listeners, stale state updates.
- **How**: Search for useEffect declarations and review each for cleanup returns.

### [QUAL-007] No hardcoded URLs or magic strings
- **Severity**: minor
- **What**: All URLs, API endpoints, config values come from env vars or constants.
- **How**: Review code for inline URLs and configuration strings.

### [QUAL-008] Error handling follows project patterns
- **Severity**: major
- **What**: API errors use ORPCError, async code has try/catch, React uses error boundaries.
- **How**: Review error handling across API clients, async functions, and component trees.

### [QUAL-009] Console.log/warn/error usage appropriate
- **Severity**: minor
- **What**: No console.log in production code. console.warn/error only for genuine issues.
- **How**: grep for `console.(log|warn|error)` in `platform/src/` and `tools/*/src/`.

### [QUAL-010] No commented-out code blocks
- **Severity**: minor
- **What**: No blocks of commented-out code left in the codebase.
- **How**: Search for patterns like `// const`, `// function`, `// if (` indicating commented code.

### [QUAL-011] Component naming conventions followed
- **Severity**: minor
- **What**: React components use PascalCase naming and PascalCase filenames.
- **How**: Review component files for naming convention compliance.

### [QUAL-012] File naming conventions followed
- **Severity**: minor
- **What**: kebab-case for utilities, PascalCase for components, camelCase for hooks.
- **How**: Review file organization against naming conventions.

### [QUAL-013] Import path aliases used consistently
- **Severity**: minor
- **What**: Imports use path aliases (`@/` for local, `@ydtb/*` for packages). No deep relative paths (`../../../`).
- **How**: Search for deep relative import patterns.

### [QUAL-014] No dead exports
- **Severity**: info
- **What**: No exports that are never imported anywhere in the monorepo.
- **How**: Check package exports against actual import usage.

---

## Domain 03: Security (15 checks)

Auth, sessions, CORS, env secrets, RLS, input validation.

### [SEC-001] BETTER_AUTH_SECRET meets minimum length
- **Severity**: critical
- **What**: BETTER_AUTH_SECRET environment variable is at least 32 characters.
- **Why**: Shorter secrets are vulnerable to brute-force attacks.

### [SEC-002] No secrets in source control
- **Severity**: critical
- **What**: .env files not committed to version control. .gitignore excludes them.
- **How**: Check .gitignore, run `git log --all -p -- '*.env'`.

### [SEC-003] .env.example contains all required vars without real values
- **Severity**: major
- **What**: .env.example lists all required env vars with placeholder values, not real secrets.

### [SEC-004] trustedOrigins list restrictive
- **Severity**: critical
- **What**: CORS trustedOrigins has no wildcards (*), only specific known origins.
- **How**: Check better-auth config for trustedOrigins.

### [SEC-005] Session cookie httpOnly flag set
- **Severity**: critical
- **What**: Session cookies have httpOnly flag to prevent JavaScript access.

### [SEC-006] CSRF protection enabled
- **Severity**: critical
- **What**: better-auth CSRF protection is enabled and CSRF tokens validated on state-changing requests.

### [SEC-007] Auth middleware rejects unauthenticated requests
- **Severity**: critical
- **What**: Protected API routes return 401/403 without valid authentication.

### [SEC-008] Workspace middleware rejects missing workspace context
- **Severity**: critical
- **What**: Workspace-scoped endpoints reject requests without valid workspace context.

### [SEC-009] No SQL injection vectors
- **Severity**: critical
- **What**: All queries use Drizzle ORM parameterized queries, no raw string concatenation in SQL.
- **How**: grep for raw SQL usage and template literals in query contexts.

### [SEC-010] No XSS vectors
- **Severity**: critical
- **What**: No dangerouslySetInnerHTML. All user input escaped via React JSX.
- **How**: grep for `dangerouslySetInnerHTML` in `platform/src/` and `tools/*/src/`.

### [SEC-011] VITE_ prefix only on client-safe env vars
- **Severity**: major
- **What**: Database URLs, API keys, secrets must NOT have VITE_ prefix (which exposes them in client bundle).

### [SEC-012] Database credentials not logged
- **Severity**: critical
- **What**: Connection strings and credentials never appear in console output or log files.
- **How**: grep for `DATABASE_URL` in logging contexts.

### [SEC-013] Error responses don't leak internal details
- **Severity**: major
- **What**: API error responses contain no stack traces, file paths, or implementation details.

### [SEC-014] Password minimum requirements enforced
- **Severity**: major
- **What**: better-auth enforces minimum password length and complexity.

### [SEC-015] Rate limiting considerations documented
- **Severity**: info
- **What**: Rate limiting strategy documented for auth endpoints and APIs.

---

## Domain 04: Database (13 checks)

Schema integrity, RLS, migrations, connections, isolation.

### [DB-001] All tool tables include workspace_id column
- **Severity**: critical
- **What**: Every tool table has workspace_id column for multi-tenant isolation.
- **How**: Examine `tools/*/src/db/schema.ts` for workspace_id in each table definition.

### [DB-002] Foreign keys reference correct tables with ON DELETE behavior
- **Severity**: major
- **What**: All FK constraints reference correct tables with appropriate ON DELETE (CASCADE, SET NULL, or RESTRICT).

### [DB-003] RLS policies defined for all tool tables
- **Severity**: critical
- **What**: Row Level Security policies exist and are enabled, enforcing workspace_id filtering for SELECT/INSERT/UPDATE/DELETE.

### [DB-004] Connection pool settings appropriate
- **Severity**: major
- **What**: Database connection pool config (max connections, idle timeout, connection timeout) matches expected load.

### [DB-005] Drizzle schema matches actual database state
- **Severity**: critical
- **What**: Drizzle schema definitions synchronized with actual database schema. No drift.

### [DB-006] Migrations directory exists and is ordered
- **Severity**: major
- **What**: Migrations directory contains sequentially ordered migration files.

### [DB-007] Schema imports use correct package path
- **Severity**: major
- **What**: Tool schemas import from `@ydtb/db`, not directly from `drizzle-orm/pg-core`.
- **How**: grep for `"from.*drizzle-orm/pg-core"` in `tools/*/src/`.

### [DB-008] tools.gen.ts re-exports all tool schemas
- **Severity**: critical
- **What**: Generated tools.gen.ts includes re-exports for every tool with `db/schema.ts`.

### [DB-009] No raw SQL outside of migration files
- **Severity**: major
- **What**: All queries use Drizzle ORM query builder. Raw SQL (`sql\`\`` or `db.execute`) only in migrations.

### [DB-010] Indexes exist for frequently queried columns
- **Severity**: minor
- **What**: workspace_id and other frequently filtered columns have database indexes.

### [DB-011] Timestamps present on data tables
- **Severity**: minor
- **What**: All data tables include createdAt and updatedAt timestamp columns with appropriate defaults.

### [DB-012] Database startup script functional
- **Severity**: major
- **What**: Docker database initialization creates DB, applies migrations, app connects without errors.

### [DB-013] drizzle.config.ts schema paths cover all tool schemas
- **Severity**: major
- **What**: drizzle.config.ts references schema files from all tools (via tools.gen.ts or directly).

---

## Domain 05: API (12 checks)

oRPC routes, middleware, error handling, validation.

### [API-001] /api/rpc/* endpoint responds
- **Severity**: critical
- **What**: oRPC endpoint at /api/rpc/* reachable and returns valid responses.

### [API-002] /api/health endpoint responds
- **Severity**: major
- **What**: Health check at /api/health returns 200 OK without auth.

### [API-003] /api/auth/* endpoint responds
- **Severity**: critical
- **What**: better-auth endpoints reachable for login, signup, session, logout.

### [API-004] All tool routers included in router.gen.ts
- **Severity**: critical
- **What**: Every tool with `src/api/router.ts` imported and merged into generated router file.

### [API-005] Middleware chain enforced (base -> auth -> workspace)
- **Severity**: critical
- **What**: All tool procedures go through full middleware chain: base context, then auth, then workspace.

### [API-006] Authed builder used for all tool procedures
- **Severity**: critical
- **What**: Tool API procedures use `authedProcedure` or `workspaceProcedure`, never raw `baseProcedure`.

### [API-007] Input validation (Zod schemas) on all mutations
- **Severity**: major
- **What**: All mutation procedures have Zod input schemas for request validation.

### [API-008] Error responses use ORPCError with appropriate codes
- **Severity**: major
- **What**: API errors use ORPCError with codes: NOT_FOUND, UNAUTHORIZED, BAD_REQUEST, FORBIDDEN, INTERNAL_SERVER_ERROR.

### [API-009] No N+1 query patterns in list endpoints
- **Severity**: minor
- **What**: List endpoints use joins or batch queries, not separate queries per item.

### [API-010] API procedures filter by workspace_id
- **Severity**: critical
- **What**: All data-returning procedures filter by workspace_id from context.

### [API-011] RPCLink base URL configurable via env
- **Severity**: major
- **What**: oRPC client base URL comes from environment variable, not hardcoded.

### [API-012] oRPC client TanStack Query utils functional
- **Severity**: major
- **What**: oRPC + TanStack Query integration works: queries, mutations, invalidation.

---

## Domain 06: Plugin System (14 checks)

Hook declarations, convention compliance, codegen, boot sequence.

### [PLUG-001] All platform hooks declared in declarePlatformHooks()
- **Severity**: critical
- **What**: Every hook the platform dispatches must be declared in `declarePlatformHooks()` with expected args and return types.

### [PLUG-002] All tools have src/plugin.ts with valid definePlugin()
- **Severity**: critical
- **What**: Each tool has `src/plugin.ts` exporting `definePlugin()` with id, name, and register function.

### [PLUG-003] Plugin register() receives scoped HookAPI
- **Severity**: major
- **What**: register function receives HookAPI instance scoped to that plugin with methods: `on()`, `onFilter()`, etc.

### [PLUG-004] Routes registered on correct tier
- **Severity**: major
- **What**: Routes on correct tier: dashboard (workspace-scoped), fullscreen (auth no sidebar), authenticated (auth only), public (no auth).

### [PLUG-005] Navigation items include required fields
- **Severity**: major
- **What**: Nav items have id, label, icon, and route fields. All ids unique. Icons valid.

### [PLUG-006] No duplicate plugin IDs
- **Severity**: critical
- **What**: Each plugin has globally unique ID. Duplicates cause silent registration overwrites.

### [PLUG-007] Dependencies declared and resolvable
- **Severity**: major
- **What**: Plugin dependencies reference existing plugin IDs with no circular chains.

### [PLUG-008] Codegen script discovers all tools
- **Severity**: critical
- **What**: Codegen scans tools/ and includes every tool in generated output.

### [PLUG-009] registry.gen.ts imports match tools/ directory
- **Severity**: critical
- **What**: Generated registry imports from every tool with `src/plugin.ts`. No stale imports.

### [PLUG-010] router.gen.ts imports match tools with src/api/router.ts
- **Severity**: critical
- **What**: Generated router imports from every tool with an API router. No stale imports.

### [PLUG-011] tools.gen.ts imports match tools with src/db/schema.ts
- **Severity**: critical
- **What**: Generated tools file imports from every tool with a database schema. No stale imports.

### [PLUG-012] Boot sequence completes without errors
- **Severity**: critical
- **What**: Platform boot (register plugins -> resolve deps -> dispatch boot action) completes without throwing.

### [PLUG-013] platform:boot action fires after registration
- **Severity**: major
- **What**: `platform:boot` hook fires after all plugins registered, allowing post-registration setup.

### [PLUG-014] Hook dispatch (action + filter) works correctly
- **Severity**: major
- **What**: Both action hooks (side effects) and filter hooks (data transformation) dispatch correctly.

---

## Domain 07: Frontend (14 checks)

Routing, state, components, accessibility, error boundaries.

### [FE-001] All 4 route tiers render correctly
- **Severity**: critical
- **What**: Public, authenticated, fullscreen, and dashboard tiers render their respective layouts.

### [FE-002] ProtectedRoute redirects unauthenticated users to /login
- **Severity**: critical
- **What**: Accessing protected routes without session redirects to /login before any protected content renders.

### [FE-003] WorkspaceGate fires hooks and redirects appropriately
- **Severity**: critical
- **What**: WorkspaceGate checks for active workspace, fires lifecycle hooks, redirects to workspace selection if none active.

### [FE-004] Login/signup flows complete successfully
- **Severity**: critical
- **What**: Users can sign up, log in, establish sessions that persist across reloads.

### [FE-005] Workspace creation flow works end-to-end
- **Severity**: critical
- **What**: Users can create workspace via UI, get redirected into it with valid context.

### [FE-006] Portal system (sidebar + header injection) functional
- **Severity**: major
- **What**: Plugins inject nav items into sidebar and content into header via portal/hook system.

### [FE-007] Navigation context persists across sessions
- **Severity**: minor
- **What**: Last active nav state persists via localStorage and restores on return.

### [FE-008] Theme system applies appearance/accent/pattern
- **Severity**: minor
- **What**: Theme settings (light/dark, accent color, background pattern) apply and persist.

### [FE-009] Command palette (Cmd+K) opens and searches
- **Severity**: minor
- **What**: Cmd+K opens command palette, accepts search, displays matching items and actions.

### [FE-010] Responsive layout works on mobile breakpoints
- **Severity**: minor
- **What**: Layout adapts to mobile widths (320px, 768px). Sidebar collapses, no horizontal scroll.

### [FE-011] No React key warnings in lists
- **Severity**: minor
- **What**: Browser console has no "Each child in a list should have a unique key" warnings.

### [FE-012] Error boundaries catch component errors
- **Severity**: major
- **What**: Error boundaries present, catch render errors, display fallback UI without crashing entire app.

### [FE-013] QueryClientProvider wraps all data-fetching components
- **Severity**: critical
- **What**: Shared QueryClientProvider from `@ydtb/query-client` wraps entire app tree. No duplicate providers.

### [FE-014] Route transitions don't cause layout flicker
- **Severity**: minor
- **What**: No visible layout shifts, FOUC, or loading state flicker during route transitions.

---

## Domain 08: Dependencies (11 checks)

Singletons, versions, peer deps, duplication, lock file.

### [DEP-001] React 19.0.0 is singleton
- **Severity**: critical
- **What**: React installed as single instance across monorepo. No duplicates in node_modules.

### [DEP-002] TanStack Query imported only from @ydtb/query-client
- **Severity**: critical
- **What**: No direct imports from `@tanstack/react-query` in `tools/` or `platform/`. All through `@ydtb/query-client`.

### [DEP-003] All internal packages use workspace:* resolution
- **Severity**: major
- **What**: Internal `@ydtb/*` references use `"workspace:*"` version in package.json.

### [DEP-004] No conflicting peer dependency versions
- **Severity**: major
- **What**: bun install shows no peer dependency warnings or errors.

### [DEP-005] bun.lock file committed and up to date
- **Severity**: major
- **What**: bun install produces no changes to bun.lock.

### [DEP-006] devDependencies vs dependencies correctly categorized
- **Severity**: minor
- **What**: Build tools, test frameworks, `@types/*` in devDependencies. Runtime libs in dependencies.

### [DEP-007] No deprecated packages in use
- **Severity**: minor
- **What**: No deprecation warnings during bun install.

### [DEP-008] Package versions consistent across monorepo
- **Severity**: major
- **What**: Same external package uses same version across all workspaces.

### [DEP-009] No unnecessary dependencies
- **Severity**: minor
- **What**: All listed dependencies are actually imported somewhere in the package source.

### [DEP-010] Types packages in devDependencies only
- **Severity**: minor
- **What**: `@types/*` packages only in devDependencies, never in dependencies.

### [DEP-011] Shared packages export only what's needed
- **Severity**: info
- **What**: Minimal, intentional exports. No internal implementation details exposed.

---

## Domain 09: Documentation (12 checks)

Accuracy, coverage, staleness, proposed vs built alignment.

### [DOC-001] ARCHITECTURE.md reflects current architecture
- **Severity**: major
- **What**: ARCHITECTURE.md accurately describes current tech stack, structure, commands, constraints.

### [DOC-002] docs/ specs align with implementation
- **Severity**: major
- **What**: Documentation in docs/ reflects what was built. Divergences documented.

### [DOC-004] docs/ records match current code
- **Severity**: major
- **What**: Documentation accurately reflects current state of implemented features.

### [DOC-005] "Last verified" dates are recent
- **Severity**: minor
- **What**: Verification dates within 2 weeks of current date.

### [DOC-006] No references to deprecated patterns
- **Severity**: major
- **What**: No references to Module Federation, micro-frontend, old tool system in docs.

### [DOC-007] Hook names in docs match code declarations
- **Severity**: major
- **What**: Hook names in documentation match `declarePlatformHooks()` declarations.

### [DOC-008] Route tier count and descriptions accurate
- **Severity**: minor
- **What**: Documented route tiers match actual implementation (count, purpose, behavior).

### [DOC-009] Tool creation guide produces working tool
- **Severity**: major
- **What**: Following docs step by step produces a functional registered tool.

### [DOC-010] Package documentation current
- **Severity**: minor
- **What**: README/docs for shared packages reflect current exports and usage patterns.

### [DOC-011] API documentation matches actual endpoints
- **Severity**: minor
- **What**: API docs match actual oRPC routes, inputs, and outputs.

### [DOC-012] Environment variable documentation complete
- **Severity**: major
- **What**: All required env vars documented with purpose, format, required/optional status.

---

## Domain 10: Testing (10 checks)

Coverage, patterns, test infrastructure.

### [TEST-001] Test runner (vitest) configured and functional
- **Severity**: critical
- **What**: Vitest configuration exists and test runner starts without errors.

### [TEST-002] At least one test exists and passes
- **Severity**: major
- **What**: Test suite contains at least one passing test.

### [TEST-003] Test isolation (fresh QueryClient per test)
- **Severity**: major
- **What**: Each test creates fresh TanStack QueryClient to prevent state leaking.

### [TEST-004] Mock patterns established for oRPC
- **Severity**: major
- **What**: Established patterns for mocking oRPC procedures (MSW handlers or direct mocks).

### [TEST-005] No tests depend on external services
- **Severity**: major
- **What**: All tests pass without running database, API server, or external services.

### [TEST-006] Test commands work
- **Severity**: critical
- **What**: `bun run test` executes from root and runs all suites successfully.

### [TEST-007] Critical paths have test coverage
- **Severity**: major
- **What**: Auth flow, workspace gate, plugin registration have at least basic test coverage.

### [TEST-008] Test files co-located or in __tests__ directories
- **Severity**: minor
- **What**: Test files follow consistent location convention.

### [TEST-009] No skipped tests without explanation
- **Severity**: minor
- **What**: Every test.skip/it.skip has comment explaining why and when to re-enable.

### [TEST-010] CI test integration documented or configured
- **Severity**: info
- **What**: CI configuration or documentation exists for running tests automatically.

---

## Domain 11: Performance (10 checks)

Bundle size, lazy loading, caching, connection pools, queries.

### [PERF-001] Production bundle under 1MB (gzipped under 300KB)
- **Severity**: major
- **What**: Production JS bundle under 1MB uncompressed, under 300KB gzipped.

### [PERF-002] No duplicate library instances in bundle
- **Severity**: major
- **What**: React, TanStack Query not duplicated in production bundle.

### [PERF-003] Database connection pool sized appropriately
- **Severity**: major
- **What**: Pool max matches expected peak concurrency.

### [PERF-004] TanStack Query staleTime/gcTime configured
- **Severity**: minor
- **What**: Default staleTime and gcTime set to avoid excessive refetching or memory leaks.

### [PERF-005] Images and assets optimized
- **Severity**: minor
- **What**: Images appropriately sized/compressed. SVGs optimized.

### [PERF-006] No synchronous blocking operations in render path
- **Severity**: major
- **What**: No heavy synchronous computation in React render functions. Data fetching via TanStack Query.

### [PERF-007] Route-level code splitting possible
- **Severity**: minor
- **What**: Routes support lazy loading via React.lazy() or TanStack Router lazy routes.

### [PERF-008] Unnecessary re-renders avoided
- **Severity**: minor
- **What**: React.memo, useMemo, useCallback used where appropriate for stable references.

### [PERF-009] API responses paginated for list endpoints
- **Severity**: minor
- **What**: List endpoints support pagination (limit/offset or cursor-based).

### [PERF-010] Vite build completes under 30 seconds
- **Severity**: info
- **What**: Vite build completes in reasonable timeframe on modern hardware.

---

## Domain 12: DevOps (12 checks)

Docker, env config, health checks, build pipeline, CI.

### [OPS-001] Docker database startup script works
- **Severity**: critical
- **What**: Docker Compose DB service starts, creates database, accepts connections.

### [OPS-002] bun install completes without errors
- **Severity**: critical
- **What**: `bun install` from repo root succeeds with no errors or unresolved dependencies.

### [OPS-003] bun run build completes without errors
- **Severity**: critical
- **What**: Full monorepo build completes, producing valid output artifacts.

### [OPS-004] bun run check passes
- **Severity**: major
- **What**: Check script (tsc + eslint + prettier) passes with no errors.

### [OPS-005] Generated files (.gen.ts) not manually edited
- **Severity**: major
- **What**: Generated files only modified by codegen script. Check git blame for manual edits.

### [OPS-006] .gitignore covers all build artifacts
- **Severity**: major
- **What**: dist/, .output/, node_modules/, .turbo/ in .gitignore. No build artifacts committed.

### [OPS-007] Environment variables documented in .env.example
- **Severity**: major
- **What**: All env vars used by app listed in .env.example with descriptions.

### [OPS-008] Health check endpoint returns 200
- **Severity**: major
- **What**: /api/health returns HTTP 200 when service is running.

### [OPS-009] Build output structure correct
- **Severity**: major
- **What**: Build output in .output/ follows expected Nitro/Vinxi structure with server/ and public/ directories.

### [OPS-010] Git hooks (if any) functional
- **Severity**: minor
- **What**: If git hooks configured (husky, lefthook), they execute without errors.

### [OPS-011] Branch strategy documented
- **Severity**: info
- **What**: Branching strategy (main, feature branches, release process) documented.

### [OPS-012] No large binary files in repository
- **Severity**: minor
- **What**: No files > 1MB in git history. Large assets should be external.
