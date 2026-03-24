---
description: "EpicFlow — Recommend what to work on next based on open issues and current activity"
---

# EpicFlow Next

Analyze open bd issues, GitHub issues, current work in progress, and dependencies to recommend what to work on next.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Step 1: Detect Work In Progress

Check for active work that should be excluded from recommendations:

1. **Worktrees**: Run `git worktree list` — any worktree other than the main working directory represents active agent work. Extract the branch name from each worktree.
2. **Active epic**: Check bd for in-progress epics: `bd list --type epic --status in_progress --json`
3. **In-progress tasks**: `bd list --status in_progress --json`
4. **GitHub in-progress**: `gh issue list --repo {org}/{repo} --label "in-progress" --state open --json number,title,labels`

Present a summary of all in-progress work:

```
## Work In Progress
- Worktree: .claude/worktrees/abc → branch `issue/280-theme-migration`
- Active epic: bd:{id} — {title}
- Task bd:{id} [in_progress]: {title}
```

### Exclusion Set

Build a set of bd IDs and GitHub issue numbers to exclude from recommendations:
1. All in-progress bd issues
2. Children of in-progress epics: `bd children {epic_bd_id} --json`
3. Issues matched to active worktree branches

## Step 2: Gather Available Issues

Query both systems:

1. **bd issues**: `bd list --status open --json`
2. **GitHub issues** (intake/external): `gh issue list --repo {org}/{repo} --state open --limit 200 --json number,title,labels,body,createdAt`

GitHub issues not yet in bd are candidates for import.

## Step 3: Categorize Issues

Sort issues into buckets:

### Bucket 1: Ready to Build (bd)
Tasks in bd with status=open whose dependencies are all satisfied (`bd ready --json`). These are immediately actionable.

### Bucket 2: Bugs & Quick Fixes
- bd issues with type=bug
- GitHub issues with label `bug`
- Small scope fixes. High-value, low-effort.

### Bucket 3: Planned Features (bd)
Epics or features in bd with status=open that have no unresolved dependencies.

### Bucket 4: GitHub Intake
GitHub issues not yet tracked in bd. These need to be triaged and imported.

### Bucket 5: Foundation/Platform Work
Issues labeled `tool:platform` or `infrastructure` that unblock other issues. Identify which issues they unblock.

### Bucket 6: Blocked
Issues whose dependencies (in bd via `bd dep tree`, or in GitHub issue body via "Depends on #X") are still open. Show what they're blocked on.

## Step 4: Dependency Analysis

For each issue in Buckets 1-5, check:
1. Does it have unsatisfied dependencies in bd? (`bd dep tree`)
2. Does this issue unblock other issues? (check if other issues depend on it)
3. How many downstream issues does it unblock?

## Step 5: Recommendation

Score each issue (excluding in-progress and blocked items) using this formula:

```
score = ready_bonus + (unblocks_count × 5) + bug_bonus + standalone_bonus + priority_bonus - triage_penalty - size_penalty
```

| Factor | Points | Condition |
|--------|--------|-----------|
| `ready_bonus` | +20 | Task appears in `bd ready` (all deps satisfied) |
| `unblocks_count × 5` | +5 each | Number of downstream issues this unblocks |
| `bug_bonus` | +8 | Issue type is `bug` |
| `standalone_bonus` | +4 | No dependencies at all (can start with zero context) |
| `priority_bonus` | +6/+4/+2/+0 | bd priority 0 (critical) / 1 / 2 / 3+ |
| `triage_penalty` | -10 | GitHub issue not yet imported to bd (needs triage first) |
| `size_penalty` | -2 per point | Story points if known (larger tasks score lower) |

**Tiebreaker**: If two issues have the same score, prefer the one with more downstream dependents. If still tied, prefer the older issue (earlier creation date).

### Velocity Adjustment (optional)

If `.epic/velocity.json` exists, check for historical calibration data on similar task types. If past tasks of this type consistently underestimated (actual > estimated), note the drift in the recommendation so the user can factor it in.

Rank all scored issues and present the **top 3-5 recommendations**:

```
## Recommended Next

1. **bd:{id} — Platform Token Replacement Engine** [feature] — score: 35
   Ready (+20). Unblocks 2 tasks (+10). Priority 1 (+4). ~5 points (-10).
   Estimated scope: medium.

2. **GitHub #277 — Fix flaky E2E tests** [bug, not in bd] — score: 18
   Bug (+8). Standalone (+4). Priority 2 (+2). Not in bd (-10). Small scope.
   → Import to bd first, then address.

3. **bd:{id} — Forgot Password Flow** [feature] — score: 14
   Ready (+20). Priority 2 (+2). ~3 points (-6). No downstream deps.
   Estimated scope: medium.
```

For each recommendation, show:
- The score breakdown (which factors contributed)
- Dependencies status (none, partial, blocked)
- Estimated scope (story points if known, else small/medium/large)
- What it unblocks downstream

## Step 6: Prompt for Action

```
Pick a number to start, or tell me what you'd like to focus on.
- Enter a bd ID to begin working with `/epic-build`
- Enter a GitHub issue number to import it to bd and start planning
- Or describe what area you want to work on and I'll narrow the list.
```

## Importing GitHub Issues to bd

When the user picks a GitHub issue not yet in bd:
```bash
bd create --title "{issue_title}" --type {bug|feature} --description "{issue_body}\n\nGitHub: #{number}" --priority 2
```
Then suggest the appropriate SOP from the process library: `.epic/library/bug-fix/` for bugs, `.epic/library/feature/` for features.

---

_EpicFlow Next Command — powered by bd_
