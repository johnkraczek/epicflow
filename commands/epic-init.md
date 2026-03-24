---
description: "EpicFlow — Initialize a project for epic-based development"
---

# EpicFlow Init

Bootstrap a project for EpicFlow development. Creates `.epic/settings.json`, initializes bd (beads issue tracker), generates project-specific hooks, and wires them into `.claude/settings.local.json`.

This command is idempotent — running it again updates configuration without destroying existing state.

## Step 1: Detect Existing State

Check for existing EpicFlow configuration:
- `.epic/settings.json` — if exists, offer to reconfigure or exit
- `.beads/` — if exists, skip bd init
- `.claude/settings.local.json` — if exists, merge (don't overwrite)

## Step 2: Auto-Detect Project Configuration

Detect the package manager from lockfiles:
- `bun.lock` or `bun.lockb` → bun
- `package-lock.json` → npm
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `Cargo.toml` → cargo (Rust)
- `go.mod` → go
- `requirements.txt` or `pyproject.toml` → python

Ask the user to confirm or override.

Set defaults based on detected package manager:

| Package Manager | testCommand | checkCommand | setupCommands |
|----------------|-------------|--------------|---------------|
| bun | `bun run test` | `bun run check` | `["bun install"]` |
| npm | `npm test` | `npm run check` | `["npm install"]` |
| pnpm | `pnpm test` | `pnpm run check` | `["pnpm install"]` |
| yarn | `yarn test` | `yarn run check` | `["yarn install"]` |
| cargo | `cargo test` | `cargo clippy && cargo test` | `["cargo build"]` |
| go | `go test ./...` | `go vet ./... && go test ./...` | `["go mod download"]` |

Ask the user to confirm or customize each command. Mention that `setupCommands` is what runs after entering a worktree — they may want to add codegen steps like `bun run generate`.

## Step 3: Detect GitHub Configuration

Auto-detect via: `gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'`

If detection fails, ask the user for org/repo or skip GitHub integration.

Detect main branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
Default to `main` if detection fails.

Ask if they have a production branch (default: `production`, or `none` to skip releases).

## Step 4: Initialize bd (Beads Issue Tracker)

If `.beads/` doesn't exist:
1. Check if `bd` is installed: `which bd`
   - If not installed, tell the user: "bd (beads) is required. Install: `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`"
   - Exit after showing install instructions
2. Run: `bd init --prefix {project_name}` (derive project name from directory name)
3. Confirm initialization succeeded

If `.beads/` already exists, skip and note: "bd already initialized."

## Step 5: Configure Mobile Notifications (optional)

Ask the user if they want mobile push notifications for EpicFlow decisions.

If **yes**:
1. Ask for the ntfy server URL (e.g., `https://ntfy.dev-ydtb.link`)
2. Ask for an auth token (if the server requires authentication)
3. Generate topic names based on project: `epicflow-{project_name}-alerts` and `epicflow-{project_name}-approval`
4. Test the connection:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" --max-time 5 {server}/v1/health
   ```
   - If 200: "ntfy server reachable."
   - Otherwise: warn and ask to proceed or skip
5. Send a test notification:
   ```bash
   bash ~/.claude/bin/epic-notify.sh --force 3 "EpicFlow Setup" "Notifications are working! 🎉"
   ```
6. Ask the user to confirm they received it on their phone

If **no**: set `ntfy.enabled` to `false`. Can be configured later with `/epic-init`.

## Step 6: Seed Process Library

Create `.epic/library/` with default SOPs from the EpicFlow installation:

1. Check if `~/.epicflow/library/` exists (the epicflow repo's default SOPs)
2. If it exists, copy the entire directory:
   ```bash
   cp -r ~/.epicflow/library/ .epic/library/
   ```
3. If it doesn't exist, create an empty library:
   ```bash
   mkdir -p .epic/library
   ```
4. Note: ".epic/library/ seeded with {count} SOPs. Customize them for your project."

The library is project-specific — once copied, the project owns its SOPs and can modify them independently.

## Step 7: Write .epic/settings.json

Create the `.epic/` directory (if not already created) and write `settings.json`:

```json
{
  "packageManager": "{detected}",
  "testCommand": "{confirmed}",
  "checkCommand": "{confirmed}",
  "setupCommands": ["{confirmed}"],
  "github": {
    "org": "{detected}",
    "repo": "{detected}"
  },
  "branches": {
    "main": "{detected}",
    "production": "{confirmed}"
  },
  "workspace": {
    "unattended": false,
    "maxParallelAgents": 4,
    "channel": "terminal",
    "mode": "full"
  },
  "ntfy": {
    "server": "{confirmed or empty}",
    "token": "{confirmed or empty}",
    "alertTopic": "epicflow-{project_name}-alerts",
    "approvalTopic": "epicflow-{project_name}-approval",
    "timeout": 120,
    "enabled": "{true if configured, false otherwise}"
  }
}
```

## Step 8: Generate Project-Specific Hooks

Create `.claude/hooks/` directory if it doesn't exist.

### Generate verify-wave.sh

Write `.claude/hooks/verify-wave.sh` — a verification script that uses the `testCommand` and `checkCommand` from settings. The script should:

1. Read `.epic/settings.json` for `testCommand` and `checkCommand`
2. Run the test command
3. Run the check command
4. Create `/tmp/epicflow-verified` flag on success
5. Exit with code 1 on any failure

Make it executable: `chmod +x .claude/hooks/verify-wave.sh`

### Generate dangerous-command-blocker.sh

Write `.claude/hooks/dangerous-command-blocker.sh` — a PreToolUse hook that blocks destructive commands. Include these base patterns:

**Catastrophic commands**: `rm -rf /`, `rm -rf ~`, `mkfs.`, `dd if=.* of=/dev/`, fork bomb, `chmod -R 777 /`

**Critical path protection**: `.claude/`, `.git/`, `.env`, `node_modules/`

**Dangerous git operations**: `git push.*--force`, `git reset --hard`, `git checkout -- .`

**Worktree protection**: `git worktree remove/prune` (use worktree-cleanup.sh instead), `git clean` without `-e .claude`

**bd database protection**: `bd init.*--force` (blocks accidental database wipe), deletion of `.beads/dolt`

Make it executable: `chmod +x .claude/hooks/dangerous-command-blocker.sh`

## Step 9: Wire Hooks into .claude/settings.local.json

Read the existing `.claude/settings.local.json` (or create `{}` if it doesn't exist).

Merge in the following hook wiring (don't overwrite existing hooks — append to existing arrays):

**PreToolUse Bash hooks** (project-specific):
- `"$CLAUDE_PROJECT_DIR"/.claude/hooks/dangerous-command-blocker.sh`

**Permissions to add** (if not already present):
- `Bash(bd:*)`
- `Bash(gh:*)`

Write the merged result back to `.claude/settings.local.json`.

## Step 10: Summary

Print a summary of what was created:

```
## EpicFlow Initialized

**Project**: {project_name}
**Package Manager**: {packageManager}
**Issue Tracker**: bd (prefix: {prefix})
**GitHub**: {org}/{repo}

### Files Created
- .epic/settings.json — project configuration
- .claude/hooks/verify-wave.sh — test + check verification
- .claude/hooks/dangerous-command-blocker.sh — destructive command blocker

### Hook Wiring
- dangerous-command-blocker.sh → PreToolUse (Bash)

### Next Steps
- Run `/epic-plan` to start planning your first milestone
- Run `/epic-status` to see current state
```

---

_EpicFlow Init Command — powered by bd_
