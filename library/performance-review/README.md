# Performance Review SOP

Lightweight performance awareness during implementation. Not a full performance audit — just awareness to catch regressions before they ship.

## When to Use

Apply this SOP when a task touches any of the following:

- Data-fetching logic (queries, API calls, cache layers)
- Rendering paths (component trees, layout changes, SSR/CSR boundaries)
- Database queries (new queries, changed queries, schema changes)
- API endpoints (new endpoints, changed response shapes, middleware changes)
- Bundle composition (new dependencies, lazy loading changes, code splitting)

## Steps

### 1. Before Changes: Baseline

Note current behavior before making any changes:

- **Page load**: rough load time for affected pages (dev tools Network tab or Lighthouse)
- **Query count**: number of database queries for the affected flow (check server logs or query logging)
- **Bundle size**: if adding/removing dependencies, note current bundle size (`build` output or bundle analyzer)
- **Response time**: for API changes, note current response times for affected endpoints

You do not need precise benchmarks. A quick observation is sufficient — the goal is to have a comparison point.

### 2. Implement the Task

Build the feature or fix as specified. Do not optimize prematurely — implement correctly first.

### 3. After Changes: Compare

After implementation, check the same metrics from step 1. Flag if any of the following occurred:

- **New N+1 query**: a query inside a loop that runs once per item (e.g., fetching related records one at a time instead of batch)
- **New synchronous blocking call**: a blocking operation on the main thread or request path that was not there before
- **Bundle size increase >10KB**: a new dependency or import that meaningfully increases the client bundle
- **Response time regression**: an endpoint or page load that is noticeably slower than before

### 4. If Regression Found

If you identified a regression:

- **Fix it** if the fix is straightforward and within the scope of the current task
- **Document it** if the fix is complex or out of scope — add a note explaining:
  - What the regression is
  - Why it was introduced (e.g., "necessary for correctness, optimization deferred")
  - Suggested fix approach for a follow-up task

### 5. Report

Add performance notes to the task completion report if any of the following apply:

- A regression was found and fixed
- A regression was found and documented as acceptable
- A significant performance improvement was achieved as a side effect
- No regressions were found but the task touched a performance-sensitive area

If nothing noteworthy occurred, no performance section is needed in the report.

## Expected Output

- No performance regressions introduced, OR
- Documented justification for any accepted regression with a follow-up path

## What This Is NOT

- Not a full performance audit or optimization pass
- Not a load testing requirement
- Not a mandate to add performance tests (though they are welcome)
- Not a reason to delay shipping — awareness only
