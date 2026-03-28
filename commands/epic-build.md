---
description: "EpicFlow — Execute epic tasks in waves with a persistent agent team"
---

# EpicFlow Build

Orchestrate wave-based execution of epic tasks using a persistent team of worker agents.

## Orchestrator Discipline

**You are the orchestrator. You do NOT write code or fix issues directly.** Your job is to read state, manage the team, sync tasks, update bd, and manage GitHub. All implementation work — including gate fixes, test failures, and verification issues — MUST be delegated to a teammate or subagent. This keeps the orchestrator context clean and focused on coordination.

### Zero Exceptions Gate

**The codebase must be fully clean at every wave boundary and before every commit. No exceptions.**

- ALL tests must pass — zero failures. There are no "pre-existing" failures. If a test was passing before this wave and is now failing, the wave broke it and the wave must fix it.
- The check command (`{checkCommand}`) must exit 0 — zero type errors, zero lint warnings, zero format issues, zero build failures.
- If ANY check fails: the responsible worker fixes it. If the worker can't fix it, the orchestrator delegates to another worker or a repair subagent. Do NOT commit with failures. Do NOT skip. Do NOT defer.
- Pre-existing issues are not a valid excuse. If the check command fails, it fails. Fix it before committing.
- This gate applies to: post-wave commits, epic review, and milestone shipping. CI must pass on the PR or it is a build failure.

This is a hard gate. The orchestrator MUST NOT allow code to be committed or PRs to be created that fail the check command or test suite.

**When `unattended: true`, NEVER pause to ask the user what to do next.** If the context-sufficiency check passes and context usage is below 70%, invoke the next phase using the **Skill tool**. This means:
- After epic complete with more epics remaining → `Skill(skill: "epic-plan")`
- After all epics done → `Skill(skill: "epic-ship")`

**CRITICAL: Always use the Skill tool to invoke the next phase.** Do NOT attempt to run the next phase from memory. The Skill tool reloads the full command spec, ensuring consistent behavior. Do NOT say "Run /epic-build" or "Want me to continue?" — invoke the Skill tool directly.

The only reasons to pause instead of invoking the next skill are: context insufficient (needs human creative input), context usage ≥70% (write handoff), or ESCALATE.

### Autonomous Execution Rule (unattended: true)

When `unattended: true`, the ONLY thing that determines whether you continue or stop is the **context usage percentage**. Nothing else.

- **Below 70%** → CONTINUE. No exceptions. No "but this is complex." No "let me pause here." No "do you want me to." CONTINUE.
- **70% or above** → Write handoff and stop.

**There is no middle ground.** You do not get to invent reasons to pause. Complexity is not a reason. "Substantial context consumption ahead" is not a reason. "Different type of work" is not a reason. The ONLY number that matters is the context percentage.

**Banned behaviors** — if you catch yourself doing any of these, stop and take the action instead:

- Asking ANY question → Don't ask. Do it.
- Suggesting the user decide → The user already decided: `unattended: true`.
- Offering options ("do you want X or Y?") → Pick the one that progresses the milestone.
- Warning about complexity before proceeding → Skip the warning. Proceed.
- Saying "I'll pause here" → You will NOT pause. Check context. If below 70%, continue.
- Saying "let you decide" → The decision is already made. Continue.
- Qualifying with "but" ("24% is fine but...") → Delete everything after "but." Continue.
- Suggesting "start fresh" or "new session" → Not your call. Context percentage decides this.
- Saying "Run /epic-build" instead of invoking it → Use `Skill(skill: "epic-build")`

**The test is simple**: After checking context usage, your very next action should be invoking the next phase. If there are ANY words between the context check and the Skill invocation that aren't a brief status log, you are violating the unattended contract.

## Context Health

Between waves, check actual context usage to decide whether to continue or hand off:

```bash
~/.claude/bin/claude-session-info $CLAUDE_SESSION_ID
```

This returns context usage as a percentage (e.g., `42% (420K/1000K)`).

- **Below 70%**: Continue working. Start the next wave.
- **70% or above**: Finish the current wave, write a handoff (see "Handoff" section), and stop. Do NOT start new waves.
- **Script fails or returns nothing**: **CONTINUE.** A failed context check means the session data isn't available (headless agent, no statusline, etc.) — it does NOT mean context is full. With a 1M token context window, the default assumption is that there is room. Never stop work because you couldn't read the context percentage.

## Settings

Read `.epic/settings.json` (if it exists):
- `workspace.unattended`: `true` (auto-proceed when context is sufficient) / `false` (pause at every decision point)

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` (auto-proceed when context sufficient) / `false` (always pause)
- `workspace.maxParallelAgents` — max concurrent teammates (default: 4)

## Initialization

0. **The orchestrator works from the main repo root.** No orchestrator worktree — the orchestrator does NOT call `EnterWorktree`. This is critical: workers need to call `EnterWorktree` to isolate their work, and `EnterWorktree` fails if already inside a worktree. The orchestrator stays in the main repo so workers can create their own worktrees.

   Runtime state files (`.epic/build-session.lock`, `.epic/team-active.json`, `.epic/wave-active.json`, `.epic/continue-here.md`) live in `.epic/` in the main repo and are gitignored. Only one build runs at a time — the lock file prevents concurrent builds.

1. **Resume check**: If `.epic/continue-here.md` exists:
   - Read it for: wave number, completed task IDs, remaining task IDs, branch, epic ID
   - Verify the epic is still in_progress in bd: `bd show {epic_bd_id}`
   - Delete the handoff file after reading
   - Skip to Team Setup with the remaining tasks
   - Log: "Resuming from wave {N} handoff"

2. **Write lock file**:
   ```bash
   bash ~/.epicflow/bin/epic-build-setup.sh lock "$CLAUDE_SESSION_ID" "{milestone_bd_id}" "{milestone_branch}"
   ```

3. Find the active epic: `bd list --type epic --status in_progress --json`
4. If no active epic: exit with "No active epic. Run /epic-plan first."
5. Find ready tasks: `bd ready --json`
   - If the active epic has child tasks, filter ready tasks to those under this epic

## Team Setup

Create a persistent team for this build session. The team persists across waves — teammates are reused, not respawned.

1. **Create the team**:
   Use `TeamCreate` with `team_name: "epic-{epic_bd_id}"` and `description: "Building {epic_title}"`.

2. **Sync bd tasks into the team task list**:
   For each task under the active epic (`bd children {epic_bd_id} --json`):
   - Create a corresponding task in the team task list via `TaskCreate`
   - Include the bd ID in the task metadata: `metadata: {"bdId": "{task_bd_id}", "points": N}`
   - Include the full task spec in the description (from `bd show {task_bd_id}`)
   - Set up `addBlockedBy` relationships matching the bd dependency graph
   - Already-closed bd tasks should be created as `completed`

   **Cross-epic dependencies**: Some tasks may depend on tasks from other epics (via `bd dep tree`).
   For each cross-epic dependency:
   - Check if the upstream task is already closed in bd: `bd show {upstream_bd_id}`
   - If **closed**: no blocker needed — the work is already merged
   - If **open/in-progress**: create a placeholder task in the team task list marked as `pending` with metadata `{"bdId": "{upstream_bd_id}", "external": true}` and wire it as a blocker. The orchestrator must poll `bd show {upstream_bd_id}` between waves and mark the placeholder as `completed` when the upstream task closes.
   - Log: "Cross-epic dep: {task} blocked by {upstream_task} from epic {other_epic}"

3. **Spawn teammates**:
   Spawn `maxParallelAgents` workers using the Agent tool with `team_name` and `name` parameters.

   **CRITICAL — NEVER spawn bare Agents.** Workers MUST be spawned with `team_name` and `name` parameters. Without these, workers don't have `SendMessage` or `TaskUpdate`, and all enforcement is silently bypassed. A bare `Agent()` call without team params will produce a worker that CAN'T follow the required protocol.

   **CRITICAL**: Each worker's prompt MUST include this instruction verbatim at the very top:
   ```
   BEFORE DOING ANY WORK: You MUST call EnterWorktree with name: "{worker_name}-{task_bd_id}" to create your own isolated worktree. Do NOT work directly in the main repo. Multiple workers run in parallel — without your own worktree, your file edits will collide with other workers. This is not optional.
   ```

   Then include the full worker prompt (see Worker Prompt section below).

   ```
   Agent(
     team_name: "epic-{epic_bd_id}",
     name: "worker-{N}",
     prompt: "BEFORE DOING ANY WORK: You MUST call EnterWorktree with name: '{worker_name}-{task_bd_id}' to create your own isolated worktree. ... {rest of worker prompt}",
     subagent_type: "general-purpose"
   )
   ```

   Spawn all teammates in a single message (parallel Agent tool calls). Even when spawning a SINGLE worker (e.g., for a serial task), always include `team_name` and `name`.

4. **Monitor workers**: After spawning, watch for ACK messages and worktree creation. If a worker doesn't ACK within ~2 minutes or doesn't create a worktree within ~3 minutes, shut it down and spawn a replacement.

   Workers start in the main repo root. `EnterWorktree` works on first call (no nesting). The `protect-worktrees.sh` hook prevents workers from editing files in each other's worktrees.

5. **Tag the pre-wave state** so rollback is possible:
   ```bash
   git tag "wave-1-pre"
   ```

6. **Write team manifest** via the build setup script:
   ```bash
   bash ~/.epicflow/bin/epic-build-setup.sh team-manifest "epic-{epic_bd_id}" "{epic_bd_id}" "{milestone_branch}" 4 '[{"name":"worker-1","status":"spawned"},{"name":"worker-2","status":"spawned"}]'
   ```

## Worker Prompt

Each teammate receives this prompt on spawn. Unlike one-shot subagents, teammates persist — they pull tasks from the shared list and self-assign.

```
You are a worker on the EpicFlow team "epic-{epic_bd_id}", building {epic_title}.

## Your Identity
- Name: {worker_name} (e.g., "worker-1")
- Team: epic-{epic_bd_id}

## ⚠️ MANDATORY: ACK Every Task You Claim

Every time you claim a task, your VERY NEXT action must be sending an ACK message to the orchestrator. Not after reading the spec. Not after entering a worktree. IMMEDIATELY after the TaskUpdate claim call:

```
SendMessage(to: "orchestrator"): "ACK task {task_bd_id}: {task_title}. Starting now."
```

Do this for EVERY task. No exceptions. The orchestrator cannot see that you claimed the task — this message is the only signal. Without it, the orchestrator may assign your task to another worker, causing duplicate work.

**Worktree isolation is enforced.** A PreToolUse hook (`protect-worktrees.sh`) blocks Edit and Write operations on files inside other workers' worktrees. You can only modify files in your own worktree. If you see "BLOCKED: Attempted to modify files in worktree...", you are trying to edit another worker's files — work only in your own worktree.

## Project Context
- Working directory: {cwd} (main repo root — you MUST enter your own worktree before editing files)
- Branch: {current_branch}
- Read `.epic/settings.json` for project commands (testCommand, checkCommand, setupCommands)
- Read the project's testing documentation if it exists for test conventions

## Task Loop

Repeat this loop until you receive a shutdown message:

### 1. Find Work
Check the team task list (TaskList). Look for tasks that are:
- Status: `pending` (not started)
- Not blocked (`blockedBy` is empty or all blockers are completed)
- Not owned by another worker

Prefer tasks in ID order (lowest first) — earlier tasks often set up context for later ones.

If no unblocked tasks are available, send a message to the orchestrator: "No unblocked tasks available, waiting for dependencies." Then idle — you'll be notified when new work is ready.

### 2. Claim and ACK (MANDATORY — both steps, in order)

**Step A — Claim:** `TaskUpdate(taskId, owner: "{worker_name}", status: "in_progress")`

**Step B — ACK (IMMEDIATELY, before anything else):** Send this message to the orchestrator:
"ACK task {task_bd_id}: {task_title}. Starting now."

You MUST send the ACK before reading the spec, before entering a worktree, before doing anything else. This is the single most important message you send — it is the orchestrator's only signal that the task was picked up.

### 3. Read Task Spec
The task description contains the full bd spec. Also read parent context:
```bash
bd show {task_bd_id}
bd show {task_bd_id} --refs
```
Read any documents listed in Relevant Documentation and Key References.

### 4. Enter Worktree — MANDATORY

**You MUST create your own worktree before making ANY changes. This is not optional.**

Multiple workers run in parallel. Without your own worktree, your file edits will collide with other workers. Do NOT skip this step. Do NOT work directly in the main repo.

IMMEDIATELY call:
```
EnterWorktree(name: "{worker_name}-{task_bd_id}")
```

This creates your isolated worktree branched from the current branch. ALL your work happens inside this worktree. If you find yourself editing files without having called `EnterWorktree` first, STOP and call it now.
After entering:
1. Write your heartbeat file:
   ```bash
   echo "task:{task_bd_id} worker:{worker_name} started:$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .agent-active
   ```
2. Run setupCommands from .epic/settings.json (install deps, codegen)

Do NOT touch .claude/worktrees/ directories that belong to other workers.

### 5. Implement

Implement the task **exactly as specified**. The task spec is your contract — follow it precisely.

**Status Updates During Implementation:**
Send PROGRESS messages to the orchestrator at these checkpoints:
- After entering worktree and completing setup: "PROGRESS task {task_bd_id}: worktree ready, starting implementation."
- After completing each major file or component change (for tasks touching 3+ files)
- After completing implementation, before running verification: "PROGRESS task {task_bd_id}: implementation complete, running verification."
- This applies to ALL tasks, not just 3+ point tasks. The orchestrator needs visibility into every worker's status.

**CRITICAL RULES:**
- Do NOT simplify, shortcut, or find "alternative approaches" to what the spec describes
- Do NOT implement a subset and call it done — if the spec says 12 files, change 12 files
- Do NOT add compatibility shims, wrappers, or partial migrations instead of doing the real work
- A task that touches many files is NOT necessarily complex — applying the same pattern across 15 files is routine work, not a reason to deviate

If you believe a task is genuinely impossible as written (not just large — actually impossible), see the NEEDS_DECOMPOSE path in step 10 below. You must NOT silently simplify.

Only modify files listed in Key References (plus any new files the spec requires).
If you discover out-of-scope issues, note them but do not fix them.

### 6. Verify (Zero Exceptions Gate)
Run the full test suite AND the check command from .epic/settings.json:
```bash
{testCommand}     # ALL tests must pass — zero failures
{checkCommand}    # Must exit 0 — zero type errors, zero lint warnings, zero format issues
```
If ANY check fails: fix it. Re-run. Repeat until everything passes.
- Do NOT proceed with failures.
- Do NOT blame "pre-existing" issues — if it fails now, you fix it now.
- Do NOT skip checks or defer fixes to a follow-up task.

### 7. Self-Review
Before committing, verify your work against the task spec AND the Definition of Done:

**Task spec check:**
1. Re-read the **Success Criteria** from your task description
2. For each criterion, confirm you actually satisfied it — not approximately, not with a workaround, but exactly
3. Re-read the **Key References** file list
4. For each file listed, confirm you made the changes the spec describes

**Definition of Done check:**
5. Read `.epic/library/definition-of-done.md` (if it exists) and verify each item on the checklist
6. Key items: check command passes, no debugging statements, docs updated if behavior changed, commit message has BD ID

7. If any criterion is NOT met or any file is NOT changed as specified:
   - Go back to step 4 and finish the work
   - Do NOT proceed to commit with incomplete work

If after honest self-review you cannot complete a criterion, report it as a partial failure in step 8 rather than claiming success.

### 8. Commit Checkpoint
Ensure all work is committed with a traceable message:
```bash
git add -A
git commit -m "task({task_bd_id}): {short summary of what was done}"
```
The commit message MUST include the bd task ID. This is your safety net — if ExitWorktree fails, the orchestrator can recover your work by finding this commit.

### 9. Exit Worktree
Use `ExitWorktree` to merge changes back to the main branch.

If ExitWorktree fails (e.g., merge conflict):
1. Read the conflict output carefully
2. Resolve the conflicts in the worktree
3. Commit the resolution
4. Try ExitWorktree again
5. If it fails a second time, mark the task as failed and message the orchestrator

### 10. Report
After ExitWorktree, update the task and report ONE of these outcomes:

**SUCCESS** — you completed all success criteria and changed all required files:
`TaskUpdate(taskId, status: "completed")` and message the orchestrator:
"Completed task {task_bd_id}: {summary}. Files changed: {list}."

**NEEDS_DECOMPOSE** — the task is genuinely too large or has hidden complexity you discovered during implementation (NOT just "many files"):
Keep task as `in_progress` and message the orchestrator:
"NEEDS_DECOMPOSE task {task_bd_id}: {specific reason}. Suggested split: {how to break it up}. Work done so far: {what you completed, if anything}."

Rules for NEEDS_DECOMPOSE:
- You CANNOT request decomposition for tasks ≤ 3 story points — do the work
- You MUST have attempted the implementation first — you cannot request decomposition after only reading the spec
- You MUST explain specifically what makes it too large (not "it's a lot of files" — that's not a valid reason)
- Valid reasons: discovered undocumented prerequisite work, spec assumes an API that doesn't exist, task actually contains 2+ unrelated deliverables, circular dependency found during implementation
- The orchestrator will decide whether to accept or reject the decomposition request

**FAILED** — you attempted the work but hit an error you can't resolve:
Keep task as `in_progress` and message the orchestrator:
"Failed task {task_bd_id}: {error details}. Worktree branch: {branch_name}."

### 11. Verify Worktree Cleanup
Confirm you are back on the main branch (not in a worktree).
If ExitWorktree failed, your worktree is still alive — this MUST be resolved.
Try ExitWorktree again after fixing any blocking issues.

### 12. Next Task
Go back to step 1 (Find Work). Check the task list for newly unblocked tasks.
Continue until you receive a shutdown message or no work remains.

## Communication Protocols

You have structured message types for communicating with the orchestrator. Use the right one — do not improvise free-form messages for situations these protocols cover.

### ACK — task claimed confirmation
**Send this IMMEDIATELY after claiming a task — before reading the spec, before entering a worktree, before doing anything else.** This is the most important message you send. Without it, the orchestrator has no way to know you picked up the task and may assign it to another worker, causing duplicate work.

"ACK task {task_bd_id}: {task_title}. Starting now."

This is mandatory for EVERY task. No exceptions.

### PROGRESS — status updates during work
Send PROGRESS messages at regular checkpoints throughout your work. This gives the orchestrator visibility into whether you're making progress or stuck. **Send these for ALL tasks, not just large ones.**

Required checkpoints:
- After worktree setup: "PROGRESS task {task_bd_id}: worktree ready, starting implementation."
- During implementation (after each major file or step): "PROGRESS task {task_bd_id}: {step_completed} ({N}/{total} if known). Next: {what you're doing next}."
- Before verification: "PROGRESS task {task_bd_id}: implementation complete, running verification."

Example: "PROGRESS task ydtb-a3f: migrated auth.ts (3/7 files). Next: migrating session.ts."

### BLOCKED — runtime dependency discovered
During implementation you discover that your task depends on something that doesn't exist yet — a function, schema, config, or API that another task was supposed to create but hasn't been merged.

"BLOCKED task {task_bd_id}: {what's missing}. Expected: {what should exist and where}. Likely source: {which task or epic should provide this, if you can tell}. Work done so far: {what you completed before hitting the block}."

After sending BLOCKED:
- Commit any work you've completed so far (the commit checkpoint protects it)
- Do NOT attempt workarounds or stubs — the orchestrator will resolve the dependency
- Stay in your worktree and wait for a response from the orchestrator
- The orchestrator may: unblock you by pointing to where the dependency actually is, reorder tasks so the blocker runs first, or merge the blocking work and tell you to pull

### CLARIFICATION — spec is ambiguous
The task spec is unclear, contradictory, or references something that doesn't match the actual codebase. You need guidance before proceeding.

"CLARIFICATION task {task_bd_id}: {what's unclear}. Options I see: (A) {option A}, (B) {option B}. Leaning toward: {your best guess and why}. Context: {relevant details that might help the orchestrator decide}."

Rules for CLARIFICATION:
- Always present options — do not just say "I don't understand"
- Always state which option you'd pick if forced to decide
- Wait for the orchestrator's response before proceeding
- If `unattended: true`, the orchestrator will either answer from the epic brief/docs or pick your suggested option. If it can't resolve the ambiguity, it will pause and ask the human.

### DISCOVERED_WORK — out-of-scope issue found
During implementation you discover things that need attention but are outside your task's scope — missing error handling elsewhere, deprecated patterns, tech debt, broken tests in other modules, undocumented APIs, etc.

Do NOT fix these yourself. Do NOT ignore them.

"DISCOVERED_WORK during task {task_bd_id}: {one-line summary}. Location: {file path or area}. Severity: {critical|important|minor}. Details: {what you found, why it matters, and your suggested approach if you have one}."

Then continue with your task. The orchestrator will triage it.

**Severity guide:**
- **critical**: blocks current milestone work or is a security/data issue (e.g., "auth check missing on admin route")
- **important**: doesn't block current work but should be addressed soon (e.g., "deprecated API used in 8 files, will break on next upgrade")
- **minor**: nice-to-have improvement (e.g., "this utility could be shared across 3 tools")

### Message Summary

| Message | When to use | Continue working? | Wait for response? |
|---------|-------------|-------------------|-------------------|
| ACK | Immediately after claiming a task — BEFORE any work | Yes — proceed to read spec | No |
| PROGRESS | After worktree setup, during implementation, before verification | Yes | No |
| BLOCKED | Can't proceed — runtime dependency missing | No — commit and wait | Yes |
| CLARIFICATION | Spec is ambiguous or contradictory | No — wait for answer | Yes |
| DISCOVERED_WORK | Found out-of-scope issue | Yes — continue your task | No |
| NEEDS_DECOMPOSE | Task genuinely too large (step 9) | No — report and wait | Yes |
| SUCCESS | Task complete (step 9) | Go to next task | No |
| FAILED | Can't complete task (step 9) | Go to next task | No |

## Rules
- **The task spec is the plan. Execute it exactly.** Do not simplify, do not take shortcuts, do not invent alternative approaches. If the spec says to change 15 files, change 15 files. "That's a lot of work" is never a reason to deviate — the plan already accounted for scope.
- Work independently. If you need a utility that might overlap with another worker's task, implement it locally.
- Do NOT modify files outside your task's Key References unless absolutely necessary.
- If you discover out-of-scope issues, report them via DISCOVERED_WORK (see above) — do NOT fix them and do NOT ignore them.
- If stuck for more than 2 attempts on the same error, message the orchestrator for guidance.
- When you go idle between tasks, that's normal — the orchestrator will wake you when new work is ready.
- If you think a task needs to be split, use the NEEDS_DECOMPOSE report (step 9) — NEVER silently reduce scope.
```

## Wave Planning

The orchestrator no longer manually assigns every task. Instead, it manages **wave gates** — points where all current work must complete before the next phase begins.

1. **Tester wave**: Mark all "test:" tasks as unblocked in the team task list
2. **Implementation wave**: After tester wave completes, unblock implementation tasks
3. Teammates self-assign from the unblocked pool — no explicit batching needed (concurrency is limited by `maxParallelAgents` teammates)

### File Overlap Detection

Before unblocking a wave's tasks, check for file conflicts:

1. For each task about to be unblocked, extract the file paths from its **Key References** section
2. Build a map: `file_path → [task_ids]`
3. If any file appears in 2+ tasks, those tasks have a **conflict**

**Resolving conflicts:**
- Pick the higher-priority task (lower story points first — smaller tasks finish faster) to run first
- Add a `blockedBy` dependency from the lower-priority task to the higher-priority one in the team task list
- This serializes conflicting tasks automatically — the second task won't be claimable until the first completes
- Log: "Serialized {task_A} → {task_B}: both touch {file_path}"

**Example:** If task A (2 points) and task B (5 points) both list `src/utils/auth.ts` in Key References:
- Task A runs first (fewer points)
- Task B gets `addBlockedBy: [task_A_id]` — it becomes claimable only after A completes
- When A merges, B's worktree will have A's changes in its base branch

This prevents merge conflicts from parallel edits to the same file and ensures the second task works on top of the first.

Present the wave proposal:
- List each task with role, points, and what it does
- Show worker count
- Note any serialized pairs and why
- If `unattended: false`: ask to launch, modify, or view details
- If `unattended: true`: auto-proceed (context sufficient: ready tasks exist, verification passed)

### Monitoring Workers

While a wave is in progress, monitor worker activity via the shared activity log:

```bash
cat .epic/worker-activity.jsonl
```

This file is automatically updated by PostToolUse hooks — workers don't need to remember to write to it. Each line is a JSON event with `ts`, `worker`, `event`, and `detail` fields. Events include:
- `enter_worktree` / `exit_worktree` — worker lifecycle
- `git_commit` — worker committed code (includes message)
- `test_run` / `check_run` — verification results (includes exit code)
- `task_closed` — worker closed a bd task

Use this to detect stuck workers (no events for >10 minutes), verify ACK compliance, and track wave progress without relying solely on SendMessage.

Workers are instructed to send an ACK message immediately after claiming a task. If a worker appears stuck without ACKing, it may have stalled — shut it down and spawn a replacement.

### Wave Transition

When all tasks in a wave are completed (all teammates report done or idle):

1. Run the **Post-Wave** checks (see below)
2. **Tag the post-wave state** after the wave commit:
   ```bash
   git tag "wave-{N}-post"
   ```
3. **Tag the next wave's pre-state** (snapshot before any new work begins):
   ```bash
   git tag "wave-{N+1}-pre"
   ```
4. Unblock the next wave's tasks in the team task list (with overlap detection — see above)
5. Message all idle teammates: "Wave {N+1} tasks are now available. Check the task list."

Teammates wake up and self-assign — no respawning needed.

## Post-Wave

After all tasks in a wave complete:

0. **Tag the pre-wave state** (before any merges from this wave — this should already exist from wave start):
   Verify the tag exists:
   ```bash
   git tag -l "wave-{N}-pre"
   ```
   If missing (first wave or tag wasn't created), tag the current HEAD now as a fallback:
   ```bash
   git tag "wave-{N}-pre"
   ```

0b. **Worktree cleanup**: Clean up all worker worktrees from this wave. Workers have already exited their worktrees (ExitWorktree merges changes), so remaining worktrees are orphans.
   ```bash
   bash ~/.claude/bin/worktree-cleanup.sh
   bash ~/.claude/bin/worktree-cleanup.sh --recover   # force-clean any that survived
   ```
   After both passes, verify with `git worktree list` — only the main repo should remain.
   Delete `.epic/wave-active.json` after cleanup.

1. **Merge verification**: For each task that reported success, confirm its changes landed on the milestone branch:
   ```bash
   git log --oneline -10 {milestone_branch}
   ```
   Check that commits from the task appear on the branch (match by task BD ID in commit messages or by expected file changes).

   If a task's commits are **missing**:
   - Check if the worktree still exists: `git worktree list`
   - If worktree exists with unmerged commits: message the teammate to re-enter and ExitWorktree, or spawn a **recovery subagent** (Agent tool, one-shot) to handle it
   - If worktree was already cleaned up: check if the branch still exists (`git branch --list *-{task_bd_id}`) and cherry-pick: `git cherry-pick {branch}`
   - If branch is gone: mark the task as **failed** in the team task list — it will be re-attempted by a teammate in the next wave
   - Log every recovery action in the wave log

   Only proceed to task closure for tasks whose merges are **confirmed**.

2. **Scope verification**: For each confirmed task, check that the worker actually changed the files the spec required:
   - Read the task's Key References from bd: `bd show {task_bd_id}`
   - Get the files the worker actually changed:
     ```bash
     git diff --name-only wave-{N}-pre..HEAD --
     ```
     Filter to commits with this task's bd ID in the message.
   - Compare: are all Key Reference files present in the diff?
   - **Missing files**: The worker may have skipped part of the spec. Do NOT close this task.
     Message the teammate: "Task {task_bd_id} scope incomplete — these files from Key References were not modified: {list}. Re-enter the worktree and complete the remaining work. The task spec is the contract — all listed files must be addressed."
     The task stays `in_progress` and the worker must finish it before the next wave.
   - **Extra files** (not in Key References): Log as informational — workers sometimes need to touch adjacent files. Only flag if the extra files overlap with another task's Key References.
   - Tasks that fail scope verification are NOT closed and do NOT count toward wave completion.

3. **Diff review**: For each task that passed scope verification, spawn a lightweight **review subagent** (one-shot, not a teammate) to scan the diff:
   - Get the diff: `git diff wave-{N}-pre..HEAD -- {files from this task}`
   - Check for:
     - Duplicated utilities (reimplemented something that already exists in the codebase?)
     - Pattern violations (conflicts with documented conventions in project docs?)
     - Hardcoded values that should be config/env vars
     - Missing error handling on external calls
     - TODO/FIXME/HACK comments without tracking issues
   - If issues found: message the orchestrator. Orchestrator decides: send worker back to fix (minor) or create a follow-up task (cosmetic).
   - If clean: proceed.
   - This is NOT a full code review — it's a 2-minute pattern scan. Keep it fast.

4. **Zero Exceptions Gate**: Run `.claude/hooks/verify-wave.sh` — ALL tests must pass (zero failures) and the check command must exit 0 (zero errors). There are no pre-existing exceptions. If it fails, the wave must fix it before committing.
5. **Node Repair** (on verification failure) — see decision tree below. The wave CANNOT be committed until the gate passes.
6. Close confirmed tasks in bd (only tasks that passed merge verification, scope verification, AND the Zero Exceptions Gate):
   ```bash
   bd close {task_bd_id}
   ```
   This automatically unblocks dependent tasks in bd.
6. Sync newly unblocked bd tasks into the team task list (create new TaskCreate entries if needed)
7. If the task has a linked GitHub issue (check description for `GitHub: #N`), close it:
   ```bash
   gh issue close {github_number} --repo {org}/{repo}
   ```
8. Stage only implementation changes (source code, docs, config). **Do NOT stage `.epic/` or `.beads/` state files.**
9. Commit (hooks enforce: verified, right branch)

### Worker Rotation

Workers have limited context windows. After completing 2-3 tasks, a worker's context may be degraded. The orchestrator should proactively rotate workers:

- **After a worker completes a task**: if the worker has completed 3+ tasks in this session, send it a shutdown message and spawn a fresh replacement. Fresh workers produce better results.
- **If a worker goes idle without responding**: it may have exhausted context. Shut it down, spawn a fresh worker, and reassign its in-progress task.
- **If a worker sends NEEDS_DECOMPOSE**: after handling the decomposition, consider shutting down that worker (it spent context on a failed attempt) and spawning a fresh one for the new smaller tasks.

To rotate: send `{type: "shutdown_request"}` to the old worker, then spawn a new one with the same `team_name` and a new `name` (e.g., `worker-{N+1}`).

**One task per worker at a time.** The orchestrator MUST NOT combine multiple tasks into a single agent prompt. Each worker claims ONE task from the task list, completes it, then claims the next. Never say "do tasks A, B, and C" in one prompt — this defeats the decomposition, bypasses the self-review gate on each task, and burns context.

### Handling Worker Messages (during wave)

Workers send structured messages during execution. Handle them as they arrive — do not batch.

**On ACK**:
- Log the acknowledgment: "{worker_name} claimed task {task_bd_id}"
- Update the team manifest or internal tracking to note which worker owns which task
- This confirms the worker received and is starting the task — do NOT assign this task to another worker
- If you don't receive an ACK within ~2 minutes of a task becoming available (and a worker was idle), check on the worker — it may have stalled or exhausted context

**On PROGRESS**:
- Log the progress update. No response needed.
- Use these to detect stalls: if a worker hasn't sent a PROGRESS or ACK message within ~5 minutes of their last message (or since they were spawned), send them a check-in: "Status check on task {task_bd_id} — are you still making progress?"
- If the worker doesn't respond to the check-in (goes idle without replying), treat it as a potential stall. Check if their worktree has recent commits. If no commits and no response, the worker likely exhausted context — shut it down and spawn a fresh replacement. Reassign the task.

**On BLOCKED**:
1. Read what the worker says is missing
2. Check if the missing dependency exists somewhere the worker didn't look:
   - Search the codebase: `grep -r "{function/schema name}"` or `bd show` the suspected task
   - If it exists: message the worker with the location. "The function is at {path}:{line}. Pull latest and check again."
   - If it genuinely doesn't exist: check which task should produce it
3. If the blocker is a task in the current wave:
   - Check if that task is done or in-progress
   - If done but not merged yet: prioritize its merge, then tell the blocked worker to pull
   - If in-progress: tell the blocked worker to wait, and note the implicit dependency for future planning
4. If the blocker is a task in a future wave:
   - Reorder: move the blocking task to the current wave (add to team task list, unblock it)
   - Or: tell the blocked worker to commit what they have, skip the blocked part, and the task will be completed after the dependency merges
5. Log: "BLOCKED: {task} waiting on {dependency}. Resolution: {action taken}"

**On CLARIFICATION**:
1. Read the options the worker presented
2. Try to resolve from available context:
   - Check the epic brief: `bd show {epic_bd_id}`
   - Check referenced documentation
   - Check the codebase for the answer (e.g., if the worker asks "which validation path?", look at the code)
3. If you can resolve it: message the worker with the answer and reasoning
4. If you cannot resolve it:
   - **Context sufficient** (non-architectural, worker's suggestion is reasonable): pick the worker's suggested option and message: "Going with option {X} per your suggestion. Reason: {brief justification}. If this turns out wrong, we'll fix it in review."
   - **Context insufficient** (architectural decision, security implication, or all options seem risky): pause and ask the human, presenting the worker's options and your assessment. This applies even when `unattended: true` — some decisions require human judgment.
5. Log: "CLARIFICATION: {task} — resolved: {option chosen} — reason: {why}"

### Node Repair (on verification failure)

When a task or wave verification fails, classify the failure and apply the appropriate strategy.
Each task gets a **repair budget of 2 attempts**. Track attempts per task.

**Strategy 1 — RETRY** (transient failures):
- Symptoms: network timeout, flaky test, race condition, "ECONNREFUSED", "ETIMEOUT", import resolution after parallel merge
- Action: Message the teammate to retry, or reassign the task to an idle teammate
- Costs 1 repair attempt

**Strategy 2 — DECOMPOSE** (task too complex, or worker sent NEEDS_DECOMPOSE):
- Symptoms: agent touched files outside Key References scope, multiple unrelated failures, OR worker explicitly reported NEEDS_DECOMPOSE
- **Before accepting a NEEDS_DECOMPOSE request from a worker**, the orchestrator MUST validate it:
  1. Is the task ≤ 3 story points? → **REJECT**. Message the worker: "Task is {N} points — too small to decompose. Complete it as specified. If a specific file or criterion is blocking you, report that as a failure instead."
  2. Did the worker actually attempt implementation? → Check if the worker made commits. If no commits, **REJECT**: "You must attempt the work before requesting decomposition."
  3. Is the reason valid? → "Many files" or "a lot of work" are NOT valid. Valid reasons: undocumented prerequisite, missing API, task contains unrelated deliverables, circular dependency discovered. If invalid, **REJECT** with explanation.
  4. If all checks pass → **ACCEPT** and proceed with decomposition.
- Action (on accepted decomposition):
  1. Close the original task in bd: `bd close {task_bd_id}` with a note
  2. Create 2-3 smaller replacement tasks in bd with narrower scopes
  3. Preserve any work the worker already completed — if they partially implemented, scope the new tasks around what's left
  4. Sync the new tasks into the team task list (TaskCreate with dependencies)
  5. Wire dependencies to the same parent epic
  6. Teammates will pick them up automatically
- Does NOT cost a repair attempt (the original task is replaced, not retried)

**Strategy 3 — PRUNE** (task unnecessary):
- Symptoms: feature already exists in codebase, requirement was removed, duplicate of another task
- Action: Close the task in bd: `bd close {task_bd_id}` with explanation. Mark team task as completed.
- Does NOT cost a repair attempt

**Strategy 4 — ESCALATE** (needs human judgment):
- Symptoms: ambiguous requirement, architectural decision needed, security concern, repair budget exhausted
- Action:
  1. Write handoff (see Handoff section below)
  2. Post detailed error report on GitHub issue
  3. Shutdown the team and stop the build
- Triggers when: repair budget (2 attempts) is exhausted, OR the failure doesn't match strategies 1-3

**Decision Flow**:
1. Read the message from the teammate
2. Is this a NEEDS_DECOMPOSE request? → Validate (see Strategy 2 checks), then ACCEPT or REJECT
3. Did scope verification fail (missing files)? → Send the worker back to finish the work (NOT a repair attempt — this is incomplete work, not a failure)
4. Is this a transient error? → RETRY
5. Did the agent go out of scope? → DECOMPOSE
6. Is the task actually needed? → PRUNE
7. Otherwise → ESCALATE

Track repair actions in the wave log:

| Task | Strategy | Attempt | Result |
|------|----------|---------|--------|
| {title} | RETRY | 1/2 | success/failed |

### Wave Rollback

When Node Repair fails and the wave's merged code is broken beyond repair, roll back the entire wave to the pre-wave snapshot.

**When to rollback:**
- `verify-wave.sh` fails after all repair strategies are exhausted
- A wave introduced a subtle regression caught by tests that no single task owns
- The orchestrator or user determines the wave needs to be undone

**Rollback procedure:**
1. Verify the pre-wave tag exists:
   ```bash
   git tag -l "wave-{N}-pre"
   ```
2. Reset the milestone branch to the pre-wave state:
   ```bash
   git reset --hard wave-{N}-pre
   ```
3. Reopen all tasks from the rolled-back wave in bd:
   ```bash
   bd update {task_bd_id} --status open
   ```
4. Reset corresponding tasks in the team task list to `pending` (remove owner)
5. Clean up worktrees from the rolled-back wave:
   ```bash
   bash ~/.claude/bin/worktree-cleanup.sh --recover
   ```
6. Delete the post-wave tag if it was created:
   ```bash
   git tag -d "wave-{N}-post"
   ```
7. Log the rollback in the wave log and GitHub issue:
   ```bash
   gh issue comment {epic_github_number} --repo {org}/{repo} --body-file - <<'EOF'
   ## Wave {N} Rolled Back

   **Reason**: {verification failure details}
   **Tasks reopened**: {count}
   **Reset to**: wave-{N}-pre ({commit_sha})

   These tasks will be re-attempted in the next wave. Consider DECOMPOSE if tasks were too large.

   *Posted by EpicFlow agent*
   EOF
   ```
8. Re-run wave planning — the reopened tasks will be picked up again

**IMPORTANT**: Rollback is a destructive operation on the milestone branch. Only use it when repair strategies have failed. Even with `unattended: true`, **always pause and confirm with the user before rolling back** — this is a context-insufficient decision by definition (repair failed, human judgment needed). Log the rollback prominently in the wave log and GitHub.

**Tag cleanup at epic completion**: When an epic is complete, clean up wave tags:
```bash
git tag -l "wave-*-pre" "wave-*-post" | xargs git tag -d
```

### Wave Log

After each wave, record a summary. Post as a comment on the epic's GitHub issue (if linked):

```bash
gh issue comment {epic_github_number} --repo {org}/{repo} --body-file - <<'EOF'
## Wave {N} Complete

**Type**: {tester|implementation|mixed}
**Tasks**: {count} completed
**Workers**: {count} active
**Repairs**: {count} ({strategies used})

| Task | BD ID | Worker | Result | Summary |
|------|-------|--------|--------|---------|
| {title} | {bd_id} | {worker_name} | done | {1-line summary} |

*Posted by EpicFlow agent*
EOF
```

### Handoff (on pause or context warning)

If stopping before all waves are complete (context warning, user request, or ESCALATE):

1. **Shutdown the team**: Send `{type: "shutdown_request"}` to all teammates via SendMessage
2. Wait for teammates to go idle (they'll finish current work and stop)
3. Run worktree cleanup: `bash ~/.claude/bin/worktree-cleanup.sh`
4. Delete `.epic/team-active.json`

Create `.epic/continue-here.md`:
```markdown
# EpicFlow Handoff

**Written**: {timestamp}
**Epic**: {title} (bd:{epic_bd_id})
**Branch**: {branch}
**Wave Completed**: {N}

## Completed Tasks
| BD ID | Title | Status |
|-------|-------|--------|
| {id} | {title} | done |

## Remaining Tasks
| BD ID | Title | Status | Blocked By |
|-------|-------|--------|------------|
| {id} | {title} | open | {deps or "ready"} |

## Repair Log
| Task | Strategy | Attempts | Outcome |
|------|----------|----------|---------|
| {title} | {strategy} | {n}/2 | {outcome} |

## Notes
{Any context the next session needs — errors encountered, decisions made, workarounds applied}
```

Post a comment on the GitHub issue (if linked):
```bash
gh issue comment {epic_github_number} --repo {org}/{repo} --body-file - <<'EOF'
## Build Paused — Wave {N}

**Completed**: {count} tasks
**Remaining**: {count} tasks
**Reason**: {context limit / user request / escalation}

Handoff written to `.epic/continue-here.md`. Resume with `/epic-build`.

*Posted by EpicFlow agent*
EOF
```

## Wave Loop

After post-wave completes:
1. Check context usage: `~/.claude/bin/claude-session-info $CLAUDE_SESSION_ID`
2. If **70% or above** → handoff and stop. Do NOT start another wave.
3. If **below 70%**, check for more ready tasks: `bd ready --json`
   - If more ready tasks exist → unblock them in the team task list, message idle workers
   - If all tasks in current epic done → **Epic Complete** (see below)

## Epic Review (The Lab)

When all child tasks for the current epic are closed, spawn a **review subagent** (one-shot Agent tool, NOT a teammate) to verify the epic was built correctly. This is a fresh agent with no implementation context.

The review agent should:
1. Read the original epic spec: `bd show {epic_bd_id}` and `bd show {epic_bd_id} --refs`
2. Check each success criterion against the actual codebase
3. Run the relevant unit tests using the testCommand from .epic/settings.json with appropriate filter flag for the changed packages
4. Run the project's E2E test command if configured (check .epic/settings.json or project scripts for E2E test commands)
5. **Live verification**: Start the dev server and verify the app actually works:
   - Use the playwright-cli skill (if available) or manual checks
   - Navigate to pages affected by this epic
   - Verify: no crash, no blank page, no console errors
   - This catches "tests pass but app is broken" — missing imports, broken routes, SSR errors
   - If playwright-cli is not available, skip this step (it's a bonus check, not a gate)
6. Report verdict:
   - **APPROVED**: All criteria met, tests pass, app runs → proceed to Epic Complete
   - **NEEDS WORK**: Create follow-up tasks in bd, run another wave

If needs work: sync follow-up tasks into the team task list, message idle workers.
If approved: proceed to Epic Complete below.

## Epic Complete

When all child tasks for the current epic are closed and the review passes:

1. **Shutdown the team**: Send `{type: "shutdown_request"}` to all teammates via SendMessage
2. Wait for all teammates to go idle, then **clean up ALL worker worktrees from this epic**:
   - First, run a normal cleanup: `bash ~/.claude/bin/worktree-cleanup.sh`
   - Then, run with `--recover` to force-clean any remaining dirty worktrees: `bash ~/.claude/bin/worktree-cleanup.sh --recover`
   - Verify no worker worktrees remain: `git worktree list` — only the main repo should remain
   - If any worker worktrees survived both cleanup passes, they have unmerged work — log a warning but proceed (the work was either merged via ExitWorktree or is lost)
   - Delete `.epic/team-active.json`
   - This is critical: leftover worktrees from previous epics accumulate and waste disk space. Clean up EVERY time an epic completes.
3. Close the epic in bd: `bd close {epic_bd_id}`
4. If a GitHub issue is linked:
   - Close it: `gh issue close {epic_github_number} --repo {org}/{repo}`
   - Update labels: add `completed`, remove `build-ready`/`in-progress`
   - Post completion comment
5. Check for remaining open epics in the milestone:
   ```bash
   bd children {milestone_bd_id} --json
   ```
   - If open epics remain:
     - If `unattended: true` → check context usage. If below 70%, invoke `Skill(skill: "epic-plan")` to capture and decompose the next epic. If ≥70%, write handoff instead.
     - If `unattended: false` → suggest `/epic-plan` to capture the next epic
   - If no open epics remain:
     - If `unattended: true` → invoke `Skill(skill: "epic-ship")` to ship the milestone.
     - If `unattended: false` → report "All epics complete. Run `/epic-ship` when ready."

## Milestone Queue

After `/epic-ship` completes (milestone shipped and archived), check for the next milestone in the queue.

1. **Clean up state files**: Remove `.epic/build-session.lock`, `.epic/team-active.json`, `.epic/wave-active.json` (these are ephemeral build state, not committed).
   ```bash
   bash ~/.epicflow/bin/epic-build-setup.sh cleanup
   ```
2. Query the queue:
   ```bash
   bd list --type epic --labels "milestone" --status open --json
   ```
3. For each milestone (sorted by bd priority, then creation date):
   - Check if it has child epics: `bd children {milestone_bd_id} --json`
   - If yes → this milestone is ready
4. If a ready milestone is found:
   - Check context usage
   - If ≥70% → write handoff: "Next milestone: {title} (bd:{id}). Resume with `/epic-build`."
   - If <70% → invoke `Skill(skill: "epic-plan")` to capture + decompose the new milestone, which will auto-invoke build.
5. If no ready milestones:
   - Send notification: `bash ~/.claude/bin/epic-notify.sh 3 "Queue Empty" "All milestones built. Run /epic-requirements to plan more work."`
   - Report: "All milestones complete. Build queue empty."

### Parallel Orchestrators

**Not supported.** The orchestrator works from the main repo root with state files in `.epic/`. Only one build runs at a time — the `.epic/build-session.lock` prevents concurrent builds. If a lock file exists when a new build starts, it should report "Build already in progress" and exit.

Workers are isolated via their own worktrees (`worker-{N}-{task_bd_id}`), so concurrent workers within a single build are safe.

## Discovered Work Triage

When a teammate sends a DISCOVERED_WORK message, the orchestrator must triage it. Do NOT batch these — triage each one as it arrives so critical items aren't buried.

### Triage Decision

Read the severity and details, then decide:

**Route A — Add to Current Milestone** (severity: critical, or directly impacts in-progress work):
The discovered work blocks or degrades the current milestone. Add it as a task immediately.

1. Create a bd task under the current epic:
   ```bash
   bd create --title "{description}" --type task --description "{details from worker}\n\nDiscovered by {worker_name} during task {task_bd_id}" --priority 1
   bd dep add {new_task_bd_id} {epic_bd_id}
   ```
2. Sync it into the team task list (TaskCreate) — a teammate will pick it up
3. Create a GitHub issue for visibility:
   ```bash
   gh issue create --title "{description}" --label "agent-suggested" --label "needs-review" --label "in-progress" --milestone "{current_milestone}" --repo {org}/{repo} --body-file - <<'EOF'
   ## Discovered During Build

   **Found by**: {worker_name} during task {task_bd_id} (wave {N})
   **Severity**: critical
   **Epic**: {epic_title}

   ## Details
   {what was found and why it matters}

   ## Suggested Approach
   {worker's suggestion, if provided}

   ## Triage Decision
   Added to current milestone — this blocks or degrades in-progress work.

   **Beads ID**: {new_task_bd_id}

   *Created by EpicFlow agent — requires human review*
   EOF
   ```
4. Log in wave log: "DISCOVERED_WORK (critical) → added to milestone: {title}"

**Route B — Create GitHub Issue for Later** (severity: important or minor):
The discovered work doesn't block the current milestone. Create it as a tracked issue for human review.

1. Create a bd issue (NOT under the current epic — it's standalone):
   ```bash
   bd create --title "Discovered: {description}" --type {task|bug} --description "{details from worker}\n\nDiscovered by {worker_name} during task {task_bd_id}" --priority {2 for important, 3 for minor}
   ```
2. Create a GitHub issue with triage labels:
   ```bash
   gh issue create --title "Discovered: {description}" --label "agent-suggested" --label "needs-review" --repo {org}/{repo} --body-file - <<'EOF'
   ## Discovered During Build

   **Found by**: {worker_name} during task {task_bd_id} (wave {N})
   **Severity**: {important|minor}
   **Epic**: {epic_title}

   ## Details
   {what was found and why it matters}

   ## Suggested Approach
   {worker's suggestion, if provided}

   ## Triage Decision
   Deferred — does not block current milestone. Needs human review to prioritize.

   **Beads ID**: {bd_id}

   *Created by EpicFlow agent — requires human review*
   EOF
   ```
3. Log in wave log: "DISCOVERED_WORK ({severity}) → GitHub issue #{number}: {title}"

### Labels

The following labels must exist (created by `/epic-init`):
- `agent-suggested` — item was identified by an agent during build, not by a human
- `needs-review` — requires human review before being planned or prioritized

These labels allow humans to filter all agent-suggested work with:
```bash
gh issue list --label "agent-suggested" --label "needs-review" --repo {org}/{repo}
```

After human review, remove the `needs-review` label and either:
- Add to a milestone (accept) — the item enters `/epic-plan` naturally
- Close with a comment (reject) — note why it's not needed
- Reclassify (e.g., change to `bug`, adjust priority)

## Notification Integration

The orchestrator uses `~/.claude/bin/epic-notify.sh` and `~/.claude/bin/epic-approve.sh` to communicate with the user via push notifications. The behavior depends on `workspace.channel` in `.epic/settings.json` (set via `/epic-mobile`).

### When to Notify

| Event | Terminal Mode | Mobile Mode |
|---|---|---|
| Wave complete | Log only | `epic-notify.sh --mobile-only 3 "Wave {N} Complete" "{count} tasks done"` |
| Epic complete | Log only | `epic-notify.sh --mobile-only 3 "Epic Complete" "{title}"` |
| ESCALATE | Log + `epic-notify.sh 5 "ESCALATE" "{details}"` | `epic-notify.sh 5 "ESCALATE" "{details}"` |
| Build paused (handoff) | Log + `epic-notify.sh 4 "Build Paused" "{reason}"` | `epic-notify.sh 4 "Build Paused" "{reason}"` |
| DISCOVERED_WORK (critical) | Log + `epic-notify.sh 4 "Critical Discovery" "{summary}"` | `epic-notify.sh 4 "Critical Discovery" "{summary}"` |

### When to Request Approval

Only in mobile mode. In terminal mode, use the normal terminal prompt instead.

```bash
# Check if we should use mobile approval
RESPONSE=$(bash ~/.claude/bin/epic-approve.sh choose "CLARIFICATION" "{question}" --options "{options}")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  # Got a response from phone — use it
  echo "User chose: $RESPONSE"
elif [ $EXIT_CODE -eq 2 ]; then
  # Not in mobile mode — use terminal prompt
  # (orchestrator asks the user directly in conversation)
elif [ $EXIT_CODE -eq 1 ]; then
  # Timeout — no response from phone
  # Write handoff and stop
fi
```

| Decision Point | Mobile Mode Script |
|---|---|
| CLARIFICATION (can't resolve from docs) | `epic-approve.sh choose "{question}" "{details}" --options "{option_A}:{a},{option_B}:{b}"` |
| Rollback confirmation | `epic-approve.sh approve "Rollback Wave {N}?" "Verification failed after all repair strategies"` |
| Epic selection (multiple open) | `epic-approve.sh choose "Next Epic" "Which epic?" --options "{epic1}:{id1},{epic2}:{id2}"` |

### Orchestrator Pattern

At every context-insufficient pause point, the orchestrator follows this pattern:

1. Determine if the decision can be auto-resolved (context-sufficiency check)
2. If **yes** → proceed automatically, optionally send informational notification
3. If **no** → check channel:
   - **Terminal**: ask the user in conversation
   - **Mobile**: call `epic-approve.sh`, handle response/timeout
4. If mobile timeout (exit 1) → write handoff, send `epic-notify.sh 4 "Build Paused" "No response to approval request"`

## Error Handling

| Scenario | Action |
|----------|--------|
| No active epic | Exit → /epic-plan |
| No ready tasks, blocked tasks exist | Show blockers (`bd dep tree`), wait for teammates to complete |
| Teammate sends ACK | Log it. Confirms worker claimed the task — do not reassign |
| Teammate sends PROGRESS | Log it. Detect stalls if no message for ~5 min |
| Teammate sends BLOCKED | Resolve dependency: find it, reorder tasks, or tell worker to wait |
| Teammate sends CLARIFICATION | Resolve from docs/code, or pick worker's suggested option (unattended) |
| Teammate reports NEEDS_DECOMPOSE | Validate request (see Node Repair Strategy 2), accept or reject |
| Teammate reports DISCOVERED_WORK | Triage: Route A (add to milestone) or Route B (GitHub issue) |
| Teammate reports failure (transient) | Node Repair → RETRY via message |
| Teammate reports failure (out of scope) | Node Repair → DECOMPOSE into smaller tasks |
| Scope verification fails (missing files) | Send worker back to complete the work — not a repair attempt |
| Task unnecessary | Node Repair → PRUNE the task |
| Teammate stuck, needs human judgment | Node Repair → ESCALATE with handoff |
| Repair budget exhausted, wave broken | Wave Rollback → reset to wave-{N}-pre, reopen tasks |
| Repair budget exhausted, needs human | ESCALATE — shutdown team, write handoff, stop |
| Context usage ≥ 70% (via session-info) | Finish current wave, shutdown team, write handoff, stop |
| Handoff file exists on startup | Resume from saved state, create new team |
| All epic tasks done | Review → shutdown team → close epic or start next |
| Teammate goes idle (no message) | Normal — they're waiting for work. Check task list for unblocked tasks to assign |
| No ACK after ~2 min | Worker may have stalled. Check on it, potentially rotate |

---

_EpicFlow Build Command — powered by bd + Teams_
