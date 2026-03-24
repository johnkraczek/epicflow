---
description: "EpicFlow — Ship completed milestone: retrospective, PR, merge, archive"
---

# EpicFlow Ship

Ships a completed milestone — creates a single PR for all epic work, merges to main, archives.

This runs after ALL epics in the milestone are complete (not per-epic).

**When `unattended: true`, auto-proceed through all phases where context is sufficient.** Do NOT pause between validation, retrospective, PR creation, and merge. The only pause points are: acceptance criteria failures where tests fail, and CI failures that aren't clearly test/lint issues.

## Settings

Read `.epic/settings.json` (if it exists):
- `workspace.unattended`: `true` (auto-proceed when context sufficient) / `false` (always pause)
- `github.org`, `github.repo` (auto-detect via `gh repo view --json owner,name` if missing)

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Phase 1: Validate Completion

1. Find the milestone epic in bd: `bd list --type epic --labels "milestone" --json`
   - Or find the most recent in_progress/open milestone epic
2. List all child epics: `bd children {milestone_bd_id} --json`
3. Check that all child epics are closed:
   - If any are still open or in_progress: list them and exit: "Cannot ship — {N} epics not done. Run /epic-build."
4. If a GitHub milestone exists, verify no `plan-ready` or `build-ready` issues remain:
   ```bash
   gh issue list --milestone "{milestone}" --label "plan-ready" --json number,title --repo {org}/{repo}
   gh issue list --milestone "{milestone}" --label "build-ready" --json number,title --repo {org}/{repo}
   ```

## Phase 2: Acceptance Validation

### Per-Epic Validation
1. For each epic in the milestone:
   - Read the epic brief from bd: `bd show {epic_bd_id}`
   - Extract Success Criteria from the description
   - For each criterion:
     - **Testable**: search for matching tests, verify they pass
     - **Manual** (guided): ask user to confirm
     - **Manual** (if `unattended: true`): auto-pass with note — context sufficient (tests verified the testable criteria)

### Cross-Epic Integration Verification
2. After per-epic checks, run a **full** integration verification across all epics:
   - Run the complete test suite: `{testCommand}` (all packages, not filtered to specific epics)
   - Run E2E tests if configured (check project scripts for E2E commands)
   - If using playwright: run against a local dev server to catch runtime integration issues
   - Failures here are cross-epic issues that individual epic reviews missed
   - If failures: create fix tasks, do NOT ship until resolved

3. Report validation results
4. If failures and tests fail: **pause and ask the human** — context insufficient (acceptance criteria not met)
5. If failures are manual-only and `unattended: true`: flag, log, and continue — these will be caught in human review of the PR

## Phase 3: Retrospective

Spawn a **retrospective subagent** (Agent tool) to keep the orchestrator lean:

```
Generate a retrospective for this completed milestone.

Query bd for all information:
- bd show {milestone_bd_id} (milestone overview)
- bd children {milestone_bd_id} --json (all epics)
- For each epic: bd children {epic_bd_id} --json (all tasks)
- For each task: bd show {task_bd_id} (task details, compare points vs actual)

Produce a retrospective in this format:

# Retrospective: {milestone_title}

**Date**: {today}
**Epics**: {count} | **Tasks**: {total}

## Complexity Calibration
| Task | Estimated Points | Actual Difficulty | Delta | Reason |

## Decomposition Quality
- Dependencies accurate: {yes/no}
- Tasks added mid-epic: {list or none}
- Tasks rescoped: {list or none}

## Observations
- {key learnings}

## Recommendations
- {improvements for next milestone}

Also produce a structured velocity data object for each task:

```json
{
  "milestone": "{milestone_title}",
  "date": "{today}",
  "tasks": [
    {
      "bdId": "{task_bd_id}",
      "title": "{title}",
      "role": "{role}",
      "estimatedPoints": 3,
      "actualDifficulty": 5,
      "delta": 2,
      "reason": "{why it was harder/easier than estimated}",
      "repairAttempts": 0,
      "decomposed": false
    }
  ]
}
```

Return both the markdown retrospective and the JSON velocity data.
```

After the retrospective agent returns:
1. Write the markdown retrospective to the audit/retrospective directory
2. **Update velocity tracking**: Merge the velocity data into `.epic/velocity.json`:
   - If the file doesn't exist, create it with `{"milestones": []}`
   - Append the new milestone's task data to the `milestones` array
   - This data is used by `/epic-plan` for estimation calibration and `/epic-next` for scope adjustment

## Phase 4: Post to GitHub

If GitHub milestone exists:
1. Post retrospective as comment on the last completed epic's GitHub issue
2. Post acceptance validation results

## Phase 5: Archive and Changelog

Before creating the PR, prepare the final commit on the milestone branch:

1. **Archive all related plan files**:
   - Create `plans/archive/` if it doesn't exist
   - Identify the roadmap folder: glob `plans/*-requirements/` matching the milestone title
   - Move to archive: `plans/{name}-requirements/` → `plans/archive/{name}-requirements/`
   - Also archive any standalone plan files related to this milestone
   - This is critical: leftover roadmap files cause `/epic-plan` to think unstarted work exists
2. **Update Changelog**:
   - If `CHANGELOG.md` doesn't exist at the project root, create it with a header: `# Changelog`
   - Add a new section at the top:
     ```markdown
     ## [{milestone_title}] - {YYYY-MM-DD}
     ### Features
     - {epic titles from this milestone}
     ### Fixes
     - {any bug-fix tasks completed during the milestone}
     ```
   - Source the data from bd: `bd children {milestone_bd_id} --json`
3. Commit:
   ```bash
   git add plans/ CHANGELOG.md
   git commit -m "epic-ship: archive roadmap + update changelog — {milestone_title}"
   ```

## Phase 6: Create PR and Merge

The orchestrator is running in a worktree on the milestone branch. The PR is the path back to main.

1. Push branch: `git push origin milestone/{slug}`
2. Create PR targeting main:
   ```bash
   gh pr create --title "{milestone_title}" --base main --head milestone/{slug} --repo {org}/{repo} --body-file - <<'EOF'
   ## Summary
   {milestone description}

   ### Epics Completed
   {list of epics with bd IDs and titles}

   - **Total Epics**: {count}
   - **Total Tasks**: {count}

   ### Changelog
   {changelog entries from Phase 5}

   Milestone: {milestone_title}
   EOF
   ```
3. Enable auto-merge: `gh pr merge {pr_number} --auto --merge --repo {org}/{repo}`
4. Poll for merge (30s intervals, 10min max):
   ```bash
   gh pr view {pr_number} --repo {org}/{repo} --json state,statusCheckRollup
   ```
5. On CI failure: attempt to fix if the error is clearly a test/lint issue (context sufficient). Push the fix and resume polling. If the failure is unclear or involves infrastructure → pause and ask the human (context insufficient).
6. On merge success → proceed to Phase 7

## Phase 7: Close Milestone and Exit Worktree

The PR is merged. Clean up and exit.

1. Close the milestone epic in bd: `bd close {milestone_bd_id}`
2. If a GitHub milestone exists, close it:
   ```bash
   gh api repos/{org}/{repo}/milestones/{milestone_number} --method PATCH -f state=closed
   ```
3. **Exit the orchestrator worktree**: Use `ExitWorktree` to return to the main working directory. The worktree's ephemeral state files (lock, team manifest, wave state) are cleaned up automatically.
4. Pull the merged changes:
   ```bash
   git checkout main
   git pull origin main
   ```
5. Clean up the remote branch:
   ```bash
   git push origin --delete milestone/{slug}
   ```
6. Report: "Milestone '{milestone_title}' shipped and merged to main."
7. If `unattended: true` → check the **Milestone Queue** (see `/epic-build`) for the next ready milestone.

## Phase 7: Distill (Optional)

If the milestone introduced a novel workflow pattern worth reusing, offer to create a new SOP in the process library:

1. Ask: "This milestone used a pattern that might be reusable. Want to save it as an SOP?"
2. If yes: create `.epic/library/{sop-name}/README.md` with the pattern's steps, conversation guides, and output templates
3. Commit: `git add .epic/library/ && git commit -m "epic-ship: add {sop-name} SOP from {milestone_title}"`

---

_EpicFlow Ship Command — powered by bd_
