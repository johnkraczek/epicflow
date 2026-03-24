---
description: "EpicFlow — Plan epics: requirements, milestones, decomposition"
---

# EpicFlow Plan

This command handles the full planning lifecycle. It detects where you are and routes to the right phase.

**When `unattended: true`, auto-proceed through every phase transition where context is sufficient.** Do NOT pause to ask "Want me to continue?" or say "Run /epic-build". If the plan is decomposed and validated, invoke `Skill(skill: "epic-build")` to start building immediately. If an epic is captured and briefed, proceed directly to decomposition.

**CRITICAL: Always use the Skill tool to transition to another command.** Do NOT run `/epic-build` from memory — use `Skill(skill: "epic-build")` so the full command spec is reloaded fresh. This ensures consistent behavior across transitions.

The only phases that pause are: Requirements Gathering (always needs human), Epic Capture with insufficient detail (needs human briefing), and plan validation failures after 2 iterations.

### Banned Phrases (unattended: true)

When `unattended: true`, you MUST NOT output any of these patterns:

- "Want me to continue?" → Just continue.
- "Run /epic-build" → Invoke `Skill(skill: "epic-build")`
- "Run /epic-plan" → Invoke `Skill(skill: "epic-plan")`
- "Should I...?" → Yes. Do it.
- "Or you can..." → Pick the option that continues the work.
- "wrap up here?" → Do NOT wrap up. Check context — if below 70%, keep going.

Every question is a failure of the unattended contract. The user is not at the terminal.

## Settings

Read `.epic/settings.json` for configuration (if it exists):
- `workspace.unattended`: `true` (auto-proceed when context sufficient) / `false` (always pause)
- `github.org`, `github.repo`: GitHub integration (auto-detect via `gh repo view --json owner,name` if missing)

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Context-Sufficiency Rules for Planning

When `unattended: true`, each phase uses a context-sufficiency check to decide whether to auto-proceed or pause:

| Phase | Auto-proceed if... | Pause if... |
|-------|-------------------|-------------|
| Requirements Gathering | **Never** — always requires human conversation | Always (no roadmap = creative input needed) |
| Publish Milestone | Roadmap has ≥1 epic with title + description | Roadmap has only titles, no descriptions |
| Epic Capture | Epic description has ≥3 success criteria AND ≥1 key reference | Epic description is ≤2 sentences or has no success criteria |
| Decompose | Plan validation APPROVED | Plan validation NEEDS REVISION after 2 iterations |

When `unattended: false`, pause at every phase transition for human confirmation.

## Phase Detection

1. Check for roadmap: glob `plans/*-requirements/*-roadmap.md`
2. **Staleness check** (if roadmap found): Before assuming the roadmap is actionable, verify its work isn't already done:
   - Read the roadmap's epic list
   - For each epic, check if its key deliverables already exist in the codebase (grep for files, functions, or routes it describes)
   - If ALL epics appear to be already implemented → the roadmap is stale. Archive it:
     ```bash
     mkdir -p plans/archive
     mv plans/{name}-requirements plans/archive/{name}-requirements
     git add plans/ && git commit -m "epic-plan: archive stale roadmap — {name} (already implemented)"
     ```
     Then re-run phase detection (the roadmap is gone, so it will route differently).
   - If at least one epic is NOT implemented → roadmap is valid, proceed normally
3. Check for milestone in bd: `bd list --type epic --labels "milestone" --json`
4. Check for active epic in bd: `bd list --type epic --status in_progress --json`
5. Check for child tasks: `bd children {epic_id} --json`

Route to the first matching phase:

| State | Phase |
|-------|-------|
| No roadmap | **Requirements Gathering** |
| Roadmap exists, no milestone | **Publish Milestone** |
| Milestone exists, no active epic | **Epic Capture** |
| Active epic, no tasks | **Decompose** |
| Active epic with tasks | If `unattended: true` → invoke `Skill(skill: "epic-build")` (context sufficient: tasks exist and are ready). If `unattended: false` → suggest `/epic-build` |

---

## Phase: Requirements Gathering

Collaborative deep-dive to capture tool/feature requirements. This is the one phase that should remain conversational — it's about understanding what to build.

1. Read the SOP: `.epic/library/tool-requirements/README.md` — this contains the 19-step requirements process
2. Follow each step file in order (00 through 18). Each step has a Conversation Guide, Output Template, and Completion Criteria.
3. Output: `plans/{name}-requirements/` folder + `{name}-roadmap.md`

**Context check**: This phase is ALWAYS context-insufficient — it requires human creative input. Even with `unattended: true`, do NOT skip or auto-generate requirements. Pause and engage the human.

---

## Phase: Publish Milestone

Create milestone epic in bd + GitHub milestone + individual epic issues, and create the milestone branch.

1. Read the roadmap file
2. Extract milestone title from H1 heading
3. Derive prefix (2-letter abbreviation, e.g., "Audit Remediation" → `AR`, "Server Portal" → `SP`) and slug (e.g., `system-scope`)
4. Create the milestone as a parent epic in bd:
   ```bash
   bd create --title "Milestone: {title}" --type epic --description "{roadmap summary}" --priority 1
   ```
   Record the returned bd ID.
5. Create GitHub labels if missing:
   - `plan-ready`, `build-ready`, `in-progress`, `done-ready`, `merge-ready`, `completed`, `deferred`
   - `task` (color: `#0E8A16`, description: "Sub-issue task within an epic")
   - `agent-suggested` (color: `#D4C5F9`, description: "Identified by an agent during build — not human-originated")
   - `needs-review` (color: `#FBCA04`, description: "Requires human review before planning or prioritization")
6. Create GitHub milestone via `gh api repos/{org}/{repo}/milestones --method POST --field title="..." --jq '.number'`
7. For each epic in roadmap order:
   - Create a bd issue as child of the milestone:
     ```bash
     bd create --title "{epic_title}" --type epic --description "{description, deliverables, success criteria}" --priority 2
     bd dep add {epic_bd_id} {milestone_bd_id}
     ```
   - Create a corresponding GitHub issue with label `plan-ready`, assigned to milestone:
     ```bash
     gh issue create --title "{epic_title}" --label "plan-ready" --milestone "{milestone}" --body-file - <<'EOF'
     {description, deliverables, success criteria, requirements references}

     **Beads ID**: {epic_bd_id}
     EOF
     ```
   - Update the bd issue with the GitHub reference:
     ```bash
     bd update {epic_bd_id} --description "{original_desc}\n\nGitHub: #{github_issue_number}"
     ```
8. **Ask: worktree or local branch?**
   - **Always ask** (regardless of unattended setting) — this affects the working environment
   - **If worktree**: use the `EnterWorktree` tool with `name: "milestone-{slug}"`
   - **If local branch**: `git checkout -b milestone/{slug}` from main
9. Show summary table of created epics (bd IDs + GitHub issue numbers)
10. **Tech Debt Allocation**: After creating epics from the roadmap, check for existing debt:
    - Query open agent-suggested issues: `gh issue list --label "agent-suggested" --label "needs-review" --state open --repo {org}/{repo} --json number,title,labels`
    - Query standalone bugs: `bd list --type bug --status open --json`
    - Calculate milestone capacity: sum of all epic story point estimates
    - Allocate up to 20% of capacity for tech debt (e.g., 50 points → 10 points for debt)
    - If items fit: create a "Tech Debt" epic in the milestone with the selected items
    - This epic goes through capture → decompose → build like any other
11. **Context check for next phase**: The milestone is now published. Check if the roadmap has sufficient detail for epics (descriptions, not just titles). If sufficient → auto-proceed to Epic Capture. If not → pause and tell the user which epics need more detail before proceeding.

---

## Phase: Epic Capture

Select the next epic from the milestone and prepare it for decomposition. No new branch — work continues on the milestone branch.

1. List unstarted epics in the milestone:
   ```bash
   bd children {milestone_bd_id} --json
   ```
   Filter for status=open (not in_progress or closed).
2. If no open epics remain, check for in_progress: suggest `/epic-build`
3. **Context check for epic selection**:
   - If only 1 open epic → auto-select it (no ambiguity)
   - If multiple open epics AND the roadmap defines an ordering → pick the next in order
   - If multiple open epics AND no ordering → pause and ask the user to choose
4. Read the epic's description from bd: `bd show {epic_bd_id}`
5. **Context check for briefing depth**:
   - Determine if lightweight (1-5 files, single deliverable) or full epic
   - Check if the epic description already has sufficient detail (≥3 success criteria, ≥1 key reference)
6. For **lightweight**: generate brief directly (Overview, Success Criteria, Key Code) — auto-proceed
7. For **full** with sufficient detail: generate brief from existing description — auto-proceed
8. For **full** with insufficient detail: conversational capture → Pre-Brief Completeness Gate → generate brief — **pause and engage the human** (context insufficient for autonomous briefing)
8. Store the brief in the bd issue description:
   ```bash
   bd update {epic_bd_id} --description "{full description with brief appended}"
   ```
9. If the epic has a linked GitHub issue, post brief as comment:
   ```bash
   gh issue comment {github_number} --repo {org}/{repo} --body-file - <<'EOF'
   <!-- epicflow:brief -->
   {brief content}
   EOF
   ```
10. Mark the epic as in_progress:
    ```bash
    bd update {epic_bd_id} --status in_progress
    ```
11. Update GitHub label: `plan-ready` → `build-ready` (if GitHub issue exists)
12. Proceed to **Decompose**

---

## Phase: Decompose

Break the epic into tasks with dependency ordering. All tasks are created in bd.

1. Read the epic brief from bd: `bd show {epic_bd_id}`
2. Read all referenced spec docs from the brief
3. Identify discrete deliverables
4. Check the process library: `ls .epic/library/`
   - If a matching SOP exists (e.g., `feature/`), read its `README.md` and follow the decomposition steps
   - If no matching SOP exists, decompose manually (see below)

### Manual Decomposition

5. For each deliverable with testable logic, create paired tasks:
   - Test task:
     ```bash
     bd create --title "test: {feature}" --type task --description "{test spec with inputs, outputs, failure expectations}" --priority 2
     bd dep add {test_bd_id} {epic_bd_id}
     ```
   - Implementation task:
     ```bash
     bd create --title "impl: {feature}" --type task --description "{implementation spec with file paths, doc refs}" --priority 2
     bd dep add {impl_bd_id} {test_bd_id}
     ```
6. For config/schema/docs deliverables, create single tasks
7. Each task description MUST include:
   - **Parent Context** (milestone, epic, why) — carries the bigger picture
   - Role hint (tester/coder/frontend/dba/integrator/devops/security/documenter)
   - Story points (1/2/3/5/8)
   - Specific file paths under `## Key References`
   - Relevant docs under `## Relevant Documentation`
   - Success criteria under `## Success Criteria`
   - Scope boundaries under `## Scope Boundaries`

### Task Description Format

Each task's description in bd should follow this structure. If `.epic/library/task-template.md` exists, read and use that instead.

The **Parent Context** section is critical — it carries the "why" from the milestone and epic so the agent understands the bigger picture when making implementation decisions.

```markdown
## Parent Context
- **Milestone**: {milestone title and goal}
- **Epic**: {epic title and brief}
- **Why**: {one sentence — why this work matters in the bigger picture}

## Task
- **Role**: {role}
- **Points**: {N}

## Specification
{What to build/test — detailed, actionable description}

## Key References
- {source file path} ({what to modify and why})

## Relevant Documentation
- {doc path} ({which section and why it matters for this task})
- {requirements/design refs from planning phase}

## Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}
- [ ] The project's check command passes

## Scope Boundaries
- Only modify files listed in Key References
- Do NOT touch: {excluded areas}
- If you discover out-of-scope issues, note them but don't fix them

## Dependencies
- Depends on: {task IDs or "none"}
- Blocks: {task IDs that depend on this}
```

8. View the dependency graph: `bd dep tree {epic_bd_id}`
9. **Cycle detection**: Verify no dependency cycles exist in the task graph.
   Walk the dependency tree for each task — if any task is reachable from itself, there's a cycle.
   ```bash
   bd dep tree {epic_bd_id}
   ```
   Inspect the output: if `bd dep tree` shows a cycle warning, or if any task appears as both ancestor and descendant of another, fix it immediately:
   - Identify which dependency is incorrect (usually the last one added)
   - Remove it: `bd dep remove {task_a} {task_b}`
   - Re-evaluate whether the dependency is real or if the tasks can run in parallel
   - If tasks genuinely depend on each other bidirectionally, they must be merged into a single task

   Do NOT proceed to plan validation until the graph is acyclic. A cycle means tasks will never become ready and the build will deadlock.

10. **Plan validation**: Spawn a plan-checker agent to validate the decomposition against 7 dimensions:
    - Requirement coverage, task atomicity, dependency ordering, file scope conflicts, specification completeness, gap detection, and Nyquist test coverage
    - If NEEDS REVISION: fix violations and re-check (max 2 iterations)
    - If Nyquist coverage gaps found: create additional test tasks and wire dependencies before re-checking
    - If APPROVED: proceed to GitHub sync
11. If the epic has a linked GitHub issue, post decomposition summary:
    ```bash
    gh issue comment {github_number} --repo {org}/{repo} --body-file - <<'EOF'
    ## Task Decomposition

    | BD ID | Task | Points | Role | Depends On |
    |-------|------|--------|------|-----------|
    | {id} | test: schema validation | 2 | tester | — |
    ...

    Plan validation: APPROVED (7/7 dimensions passed)

    *Posted by EpicFlow agent*
    EOF
    ```

### Auto-Continue After Decomposition

When decomposition is complete (plan validation APPROVED, tasks created, GitHub synced):

- If `unattended: true` → check context usage, then invoke `Skill(skill: "epic-build")` immediately. Do NOT say "Run /epic-build" and wait — just continue. The plan is done, tasks are ready, there is nothing to ask about.
- If `unattended: false` → present the task table and suggest `/epic-build`
- If in mobile mode → send `epic-notify.sh --mobile-only 3 "Decomposition Done" "{epic}: {count} tasks. Starting build..."` before auto-continuing

### Cross-Epic Dependencies

Sometimes a task in the current epic depends on a deliverable from a different epic (already completed or in-progress). This is common for platform/foundation work that multiple epics build on.

**During decomposition**, check whether any task references files, APIs, or features that belong to another epic:
1. List all epics in the milestone: `bd children {milestone_bd_id} --json`
2. For each task being created, check if its Key References or Relevant Documentation overlaps with another epic's scope
3. If a dependency exists on a **completed** epic's task: no action needed (the work is already merged)
4. If a dependency exists on an **open/in-progress** epic's task:
   - Wire the cross-epic dependency in bd:
     ```bash
     bd dep add {this_task_bd_id} {other_epic_task_bd_id}
     ```
   - Note the cross-epic dep in the task description under `## Dependencies`:
     ```
     - Depends on: {other_epic_bd_id} task {other_task_bd_id} ({title}) — cross-epic
     ```
   - The task will not appear in `bd ready` until the upstream task is closed

**During build**, `epic-build` handles cross-epic deps automatically — `bd ready` already respects all deps regardless of which epic they belong to. The wave planner syncs any cross-epic blocker into the team task list as an external dependency.

### Decomposition Principles

- Every task's description MUST include the specific docs and source files relevant to that task
- Test tasks contain test specifications (inputs, expected outputs, what correct failure looks like)
- Implementation tasks depend on their test task (enforces test-first)
- Story points: 1 (trivial), 2 (small), 3 (medium), 5 (significant), 8 (large)
- Prefer more small tasks over fewer large ones
- Read the project's testing documentation (if it exists) — check for minimum test coverage requirements, E2E conventions, integration test patterns, and permission boundary specs
- If a feature should ship incrementally or is high-risk, check `.epic/library/feature-flags/` for the feature flag SOP. Add flag creation as the first task and flag cleanup as the last task.
- For tasks that modify UI, add a note to check `.epic/library/accessibility-review/` during self-review

### Velocity-Calibrated Estimation

If `.epic/velocity.json` exists, read it before assigning story points. Look for patterns in past estimation accuracy:

1. Filter historical tasks by **role** (e.g., past "tester" tasks, past "frontend" tasks)
2. Calculate the average `delta` (actual - estimated) for that role
3. If the average delta is **> +1** (tasks consistently harder than estimated): bump your estimates up by 1 point for that role, and note the adjustment in the task description
4. If the average delta is **< -1** (tasks consistently easier): bump down by 1 point
5. If tasks of a certain role were frequently DECOMPOSED during build (check `decomposed: true`): prefer smaller task scopes for that role

Example: if past "integrator" tasks averaged +2 delta, a task you'd normally estimate at 3 should be estimated at 5.

This is advisory — the goal is to reduce surprise during build, not to achieve perfect accuracy. Include a note when velocity data influenced the estimate:
```
**Points**: 5 (velocity-adjusted from 3 — integrator tasks averaged +2.1 delta over last 2 milestones)
```

---

## Notification Integration

When planning requires human input and `workspace.channel` is `"mobile"`:

| Phase | Notification |
|---|---|
| Requirements Gathering | `epic-notify.sh 4 "Input Needed" "Requirements gathering for {name}. Return to terminal."` |
| Epic Capture (simple selection) | `epic-approve.sh choose "Next Epic" "Which epic?" --options "{epic1}:{id1},{epic2}:{id2}"` |
| Epic Capture (full briefing) | `epic-notify.sh 4 "Input Needed" "Epic {name} needs detailed briefing. Return to terminal."` |
| Decomposition complete | `epic-notify.sh --mobile-only 3 "Decomposition Done" "{epic}: {count} tasks created. Proceeding to build."` |

When `workspace.channel` is `"terminal"`, all planning conversations happen in the terminal — no notifications sent.

---

## GitHub Content Pattern

Always use heredoc stdin for `gh` body content:
```bash
gh issue create --title "..." --body-file - <<'EOF'
Body content here
EOF
```

---

_EpicFlow Plan Command — powered by bd_
