# Onboarding SOP

How a new agent session or developer gets up to speed on a project. This is documentation, not automation — read through these steps at the start of a new session.

## When to Use

- Starting a new agent session without prior context
- New team member joining the project
- Returning to a project after a long absence
- An agent spawned to work on a task it has no context for

## Steps

### 1. Read Project Instructions

Look for and read the project's instruction files:

- `CLAUDE.md` — agent-specific instructions, tool usage, conventions, and constraints
- `CONTRIBUTING.md` — contribution guidelines, PR process, code style
- `.github/CONTRIBUTING.md` — alternative location for contribution guidelines

These files define how work is done in this project. Follow them exactly.

### 2. Read Architecture Overview

Find and read the architecture documentation. Common locations:

- `docs/` directory — look for architecture, overview, or system design documents
- `ARCHITECTURE.md` — top-level architecture overview
- `docs/architecture.md` or similar

Understand the major components, how they interact, and the technology stack.

### 3. Read Project Structure

Understand the directory layout:

- `docs/` — look for a project structure or directory layout document
- Or explore the top-level directories to understand the organization (monorepo packages, app structure, shared libraries)

Know where to find: source code, tests, configuration, database schemas, and documentation.

### 4. Check Build and Test Commands

Look for project-specific commands:

- `.epic/settings.json` — EpicFlow settings including build, test, and check commands
- `package.json` — scripts section for available commands
- `Makefile`, `justfile`, or similar — task runner definitions

At minimum, know how to: build, run tests, run type checks, and start the dev server.

### 5. Check Available SOPs

Review the process library for available standard operating procedures:

- `.epic/library/` — EpicFlow process SOPs
- `.epicflow/library/` — alternative location

These SOPs define processes for common tasks (e.g., performance review, accessibility, API changes). Apply them when relevant to your work.

### 6. Check Current Work Status

Understand what is in progress and what needs attention:

- Issue tracker: `bd list --status open --json` or equivalent
- EpicFlow status: `/epic-status` or check `.epic/` for active milestones and tasks
- Git branches: check for active feature branches or PRs
- Recent commits: `git log --oneline -20` to see recent activity

### 7. Find What to Work On

Identify your next task:

- Ready work: `bd ready --json` or `/epic-next`
- Assigned work: check for tasks assigned to you or unblocked tasks
- Priority order: critical bugs > blocked milestones > next planned task

## Expected Output

After completing these steps, the agent or developer should have:

- Understanding of project conventions and constraints
- Knowledge of the architecture and directory structure
- Ability to build, test, and run the project
- Awareness of available process SOPs
- Knowledge of current project state and what to work on next

## Tips

- Do not skip step 1 (project instructions). These often contain critical constraints that override default behavior.
- If documentation is missing or outdated, note it but do not block on it — proceed with what is available.
- For agent sessions: this process should take minutes, not hours. Read efficiently and start working.
- If you are unsure what to work on after step 7, check with the orchestrator or project owner before starting speculative work.
