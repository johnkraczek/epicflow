---
description: "EpicFlow — Show current epic state and recommend next action"
---

# EpicFlow Status

Show the current state of work and recommend the next action.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Step 1: Gather State from bd

Run these commands to understand the current situation:

1. List active epics: `bd list --type epic --status in_progress --json`
2. List all open work: `bd list --status open --json`
3. Find ready tasks (dependencies satisfied): `bd ready --json`
4. Check for blocked tasks: `bd list --status open --type task --json` (cross-reference with `bd dep tree`)

## Step 2: Check Supplementary State

1. Check for roadmaps: glob `plans/*-requirements/*-roadmap.md`
2. Check current git branch: `git branch --show-current`
3. Check for worktrees: `git worktree list`
4. Read `.epic/settings.json` for unattended mode (if it exists)

## Step 3: Present Status

Display a formatted summary:

```
## Current State

**Milestone**: {milestone name or "none"}
**Branch**: {current branch}
**Active Epic**: {epic title} (bd:{id})

### Tasks
- Total: {N}
- Done: {N}
- In Progress: {N}
- Ready: {N} (list task IDs)
- Blocked: {N} (list what they're blocked on)

### Active Agents
{list any worktrees with their branches}
```

## Step 4: Recommend Next Action

| Condition | Recommendation |
|-----------|---------------|
| No roadmap in `plans/` | `/epic-plan` — gather requirements first |
| Roadmap exists, no milestone epic in bd | `/epic-plan` — publish milestone |
| Milestone exists, no active epic | `/epic-plan` — capture next epic |
| Active epic has no child tasks in bd | `/epic-plan` — decompose into tasks |
| Ready tasks exist (`bd ready` returns results) | `/epic-build` — execute next wave |
| All epic tasks done, more epics remain | `/epic-build` — will close epic and start next |
| All milestone epics done | `/epic-ship` — create PR and merge to main |

## Step 5: Quick Actions Menu

Show available actions:
- `/epic-plan` — Plan or decompose
- `/epic-build` — Build next wave
- `/epic-ship` — Ship completed milestone
- `/epic-audit` — Run consistency audit
- `/epic-next` — Find what to work on next
- `/epic-mobile` — Switch notification channel

If production is broken: follow the hotfix SOP at `.epic/library/hotfix/README.md` — bypasses normal milestone flow.

## GitHub Sync

If a GitHub issue is linked to the active epic (check issue description for `GitHub: #N`),
show a link to it for stakeholder visibility.

---

_EpicFlow Status Command — powered by bd_
