# Definition of Done

Project-wide checklist every task must pass before reporting SUCCESS. This applies to all tasks regardless of type or SOP.

## Checklist

- [ ] **Success criteria met** -- Every criterion listed in the task spec's "Success Criteria" section is satisfied. No partial credit.
- [ ] **Check command passes** -- Run the project's check command (`{checkCommand}` from `.epic/settings.json`). All linting, type-checking, and build steps must succeed.
- [ ] **Tests pass** -- Run the project's test command (`{testCommand}` from `.epic/settings.json`). All existing tests pass and any new behavior has test coverage.
- [ ] **No debugging statements left** -- Remove all temporary debugging output: `console.log`, `console.debug`, `print()`, `debugger`, `binding.pry`, `dd()`, `var_dump()`, etc. Intentional logging (e.g., structured logger calls) is fine.
- [ ] **No untyped escape hatches introduced** -- Do not add `any` casts in TypeScript, `type: ignore` in Python, `@SuppressWarnings` without justification, or equivalent shortcuts. If one is truly necessary, add a comment explaining why.
- [ ] **Documentation updated if behavior changed** -- If the task changes behavior described in project docs (README, API docs, architecture docs), update the relevant doc in the same commit.
- [ ] **New API endpoints documented** -- If a new API endpoint was added, it is documented in the project's API documentation with method, path, request/response shape, and auth requirements.
- [ ] **New environment variables added to example** -- If a new environment variable is required, add it to the project's env example file (e.g., `.env.example`) with a descriptive comment.
- [ ] **Commit message includes task BD ID** -- The commit message references the task's BD issue ID so work is traceable.
- [ ] **No out-of-scope file modifications** -- Files modified outside the task's Key References have a clear justification (e.g., shared type that needed updating). If you touched something unexpected, note why in your completion report.

## How to Use

Read this file during your Self-Review step (Step 6). Check each item. If any item fails, fix it before reporting SUCCESS.

Walk through the list top to bottom. The first few items (success criteria, check, tests) catch functional problems. The middle items (debug statements, escape hatches) catch code quality issues. The final items (docs, commit message, scope) catch process issues.

If an item is genuinely not applicable to your task (e.g., "New API endpoints documented" when no endpoint was added), skip it. Do not skip items that are inconvenient -- only items that are structurally impossible for the task at hand.
