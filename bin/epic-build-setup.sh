#!/bin/bash
# EpicFlow — Orchestrator Build Setup
#
# Handles all file writes the orchestrator needs in its worktree.
# Since orchestrator worktrees are read-only for Edit/Write tools,
# the orchestrator calls this script via Bash instead.
#
# Commands:
#   lock <session_id> <milestone_id> <branch>
#     → Creates .epic/build-session.lock
#
#   team-manifest <team_name> <epic_id> <branch> <max_workers> <worker_json_array>
#     → Creates .epic/team-active.json
#
#   wave-state <wave_json>
#     → Creates .epic/wave-active.json
#
#   continue-here <content>
#     → Creates .epic/continue-here.md
#
#   cleanup
#     → Removes lock, team manifest, wave state, gate file

set -euo pipefail

CMD="${1:-}"
shift 2>/dev/null || true

EPIC_DIR=".epic"
ensure_epic_dir() {
  mkdir -p "$EPIC_DIR" 2>/dev/null
}

case "$CMD" in
  lock)
    SESSION_ID="${1:-unknown}"
    MILESTONE="${2:-unknown}"
    BRANCH="${3:-unknown}"
    ensure_epic_dir
    cat > "$EPIC_DIR/build-session.lock" <<LOCKEOF
{"sessionId": "$SESSION_ID", "started": "$(date -u +%Y-%m-%dT%H:%M:%SZ)", "milestone": "$MILESTONE", "branch": "$BRANCH"}
LOCKEOF
    echo "Lock created: $EPIC_DIR/build-session.lock"
    ;;

  team-manifest)
    TEAM_NAME="${1:-}"
    EPIC_ID="${2:-}"
    BRANCH="${3:-}"
    MAX_WORKERS="${4:-4}"
    WORKERS_JSON="${5:-[]}"
    ensure_epic_dir
    jq -n \
      --arg team "$TEAM_NAME" \
      --arg epic "$EPIC_ID" \
      --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg branch "$BRANCH" \
      --argjson max "$MAX_WORKERS" \
      --argjson workers "$WORKERS_JSON" \
      '{team: $team, epic: $epic, started: $started, branch: $branch, maxWorkers: $max, workers: $workers}' \
      > "$EPIC_DIR/team-active.json"
    echo "Team manifest created: $EPIC_DIR/team-active.json"
    ;;

  wave-state)
    WAVE_JSON="${1:-{}}"
    ensure_epic_dir
    echo "$WAVE_JSON" | jq '.' > "$EPIC_DIR/wave-active.json"
    echo "Wave state created: $EPIC_DIR/wave-active.json"
    ;;

  continue-here)
    CONTENT="${1:-}"
    ensure_epic_dir
    echo "$CONTENT" > "$EPIC_DIR/continue-here.md"
    echo "Continue-here created: $EPIC_DIR/continue-here.md"
    ;;

  cleanup)
    rm -f "$EPIC_DIR/build-session.lock" "$EPIC_DIR/team-active.json" "$EPIC_DIR/wave-active.json"
    echo "Cleaned up build state files"
    ;;

  *)
    echo "Usage: epic-build-setup.sh <command> [args...]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  lock <session_id> <milestone_id> <branch>" >&2
    echo "  team-manifest <team_name> <epic_id> <branch> <max_workers> '<workers_json>'" >&2
    echo "  wave-state '<wave_json>'" >&2
    echo "  continue-here '<content>'" >&2
    echo "  cleanup" >&2
    exit 1
    ;;
esac
