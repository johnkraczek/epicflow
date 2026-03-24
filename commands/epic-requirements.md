---
description: "EpicFlow — Interactive requirements gathering, SOP routing, and milestone creation"
---

# EpicFlow Requirements

Strategic planning command. Works interactively with the human to understand what needs to be built, routes to the appropriate SOP from the process library, and produces a milestone queued for decomposition and building.

This command NEVER decomposes tasks or builds. It produces milestones — `/epic-plan` decomposes them, `/epic-build` builds them.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — ignored for this command (requirements gathering is always interactive)

## Phase 1: Understand the Work

Start by asking the user what they want to build or accomplish. Listen to their description, then route to the appropriate SOP from the process library.

### SOP Selection

Read `.epic/library/` to discover available SOPs. For each SOP directory, read its `README.md` "When to Use" section.

Match the user's description to the best SOP:

| User describes... | SOP | Path |
|---|---|---|
| New tool, major feature, full product capability | tool-requirements | `.epic/library/tool-requirements/` |
| Small-medium feature, enhancement, quick addition | feature | `.epic/library/feature/` |
| Dependency upgrade, security advisory, framework migration | dependency-upgrade | `.epic/library/dependency-upgrade/` |
| Production emergency, critical bug in prod | hotfix | `.epic/library/hotfix/` |
| Gradual rollout, A/B testing, feature flag work | feature-flags | `.epic/library/feature-flags/` |
| Audit, consistency check | → suggest `/epic-audit` instead | — |
| Something that doesn't fit any SOP | freeform | — |

If uncertain, ask: "This sounds like it could be a {type}. Should I use the {SOP name} process, or would you prefer to work through this freeform?"

If the user describes multiple things, handle them sequentially — one milestone per SOP run.

### Custom SOPs

If the project has custom SOPs in `.epic/library/` beyond the defaults, include them in the routing. Read each README.md to understand when it applies.

## Phase 2: Execute the SOP

Follow the selected SOP's steps interactively with the user.

### For tool-requirements (19 steps)
Read `.epic/library/tool-requirements/README.md` for the step order. Follow each step file (00 through 18) in sequence. Each step has:
- **Conversation Guide** — questions to ask, things to explore
- **Output Template** — the document structure to produce
- **Completion Criteria** — how to know this step is done

Work through each step conversationally. Do NOT rush or skip steps. This is the one place in EpicFlow where thoroughness matters more than speed.

Output: `plans/{name}-requirements/` folder + `{name}-roadmap.md`

### For feature (4 steps)
Read `.epic/library/feature/README.md`. Lighter process:
1. Brief — capture the feature description + success criteria
2. Design — identify key files, APIs, components involved
3. Produce a short roadmap with 1-3 epics
4. Output: `plans/{name}-requirements/{name}-roadmap.md`

### For dependency-upgrade
Read `.epic/library/dependency-upgrade/README.md`. Conversational:
1. What's being upgraded and why?
2. Review breaking changes together
3. Identify affected files/packages
4. Produce a roadmap with the upgrade steps as epics

### For hotfix
Read `.epic/library/hotfix/README.md`. This is urgent — skip milestone creation:
1. Assess the problem
2. Guide the user through the fix process
3. Do NOT create a milestone — hotfixes bypass the queue
4. Exit after the fix is deployed and backported

### For freeform
No SOP — just have a conversation:
1. Ask probing questions to understand scope, constraints, success criteria
2. Research the codebase to ground the discussion
3. Propose an approach
4. Produce a roadmap document: `plans/{name}-requirements/{name}-roadmap.md`

## Phase 3: Publish Milestone

After the SOP produces a roadmap (skip this phase for hotfixes):

1. Read the roadmap file
2. Extract milestone title from H1 heading
3. Derive prefix (2-letter abbreviation) and slug
4. Create the milestone as a parent epic in bd:
   ```bash
   bd create --title "Milestone: {title}" --type epic --description "{roadmap summary}" --priority 1
   ```
5. Create GitHub labels if missing:
   - `plan-ready`, `build-ready`, `in-progress`, `done-ready`, `merge-ready`, `completed`, `deferred`
   - `task` (color: `#0E8A16`)
   - `agent-suggested` (color: `#D4C5F9`)
   - `needs-review` (color: `#FBCA04`)
6. Create GitHub milestone: `gh api repos/{org}/{repo}/milestones --method POST --field title="..." --jq '.number'`
7. For each epic in roadmap order:
   - Create bd issue as child of milestone
   - Create GitHub issue with label `plan-ready`, assigned to milestone
   - Update bd issue with GitHub reference
8. **Tech Debt Allocation**: Check for open `agent-suggested` + `needs-review` issues and standalone bugs. Allocate up to 20% of milestone capacity for tech debt. Create a "Tech Debt" epic if items fit.
9. **Create milestone worktree**: All work happens in worktrees — never on main directly.
   Use `EnterWorktree` with `name: "milestone-{slug}"`. This creates an isolated working directory for the milestone branch.
10. Show summary table of created epics (bd IDs + GitHub issue numbers)

## Phase 4: Queue Confirmation

After publishing:

1. Log: "Milestone '{title}' published with {N} epics. Queued for decomposition and build."
2. Check if a build session is running:
   - If `.epic/build-session.lock` exists: "A build session is active on {lock.milestone}. This milestone will be picked up when it finishes."
   - If no lock: "Run `/epic-plan` to decompose epics, or `/epic-build` for the full pipeline."
3. Send notification: `bash ~/.claude/bin/epic-notify.sh 3 "Milestone Queued" "{title}: {N} epics ready for decomposition"`

## Phase 5: Continue or Done

After publishing a milestone:

- Ask: "Want to plan another milestone, or are we done?"
- This is the ONE command where asking is appropriate — the user is actively in conversation.
- If more ideas → loop back to Phase 1
- If done → end session

## GitHub Content Pattern

Always use heredoc stdin for `gh` body content:
```bash
gh issue create --title "..." --body-file - <<'EOF'
Body content here
EOF
```

---

_EpicFlow Requirements Command — powered by bd + Process Library_
