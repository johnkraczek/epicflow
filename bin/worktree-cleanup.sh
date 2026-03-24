#!/bin/bash
# EpicFlow v3 — Safe Worktree Cleanup
#
# Removes orphaned worktrees while protecting active agent work.
# This script is the ONLY approved way to remove worktrees (direct
# `git worktree remove` is blocked by dangerous-command-blocker.sh).
#
# Safety checks before removing any worktree:
#   1. Has a .agent-active file that's been updated in the last 10 minutes? → SKIP
#   2. Has uncommitted changes? → SKIP (warn), or discard with --recover
#   3. Otherwise → safe to remove

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORKTREE_DIR="$PROJECT_DIR/.claude/worktrees"
STALE_MINUTES=10
DRY_RUN=false
RECOVER=false
TARGET_NAME=""

show_help() {
  cat <<'USAGE'
Usage: worktree-cleanup.sh [OPTIONS] [NAME]

Remove orphaned EpicFlow worktrees safely.

Arguments:
  NAME                    Remove a specific worktree by name (optional)

Options:
  --dry-run               Report only, don't remove anything
  --recover               Discard uncommitted changes in dirty worktrees, then
                          remove them. Use when the work is already merged to
                          main and the worktree is left over from a crashed agent.
  --stale-minutes N       Custom staleness threshold (default: 10)
  -h, --help              Show this help message

Examples:
  worktree-cleanup.sh                          # remove all clean orphans
  worktree-cleanup.sh --dry-run                # preview what would be removed
  worktree-cleanup.sh --recover                # discard changes + remove dirty worktrees
  worktree-cleanup.sh --recover --dry-run      # preview what --recover would do
  worktree-cleanup.sh migrate-foo              # remove specific worktree (if clean)
  worktree-cleanup.sh --recover migrate-foo    # discard + remove specific worktree
USAGE
  exit 0
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --recover)
      RECOVER=true
      shift
      ;;
    --stale-minutes)
      STALE_MINUTES="$2"
      shift 2
      ;;
    *)
      TARGET_NAME="$1"
      shift
      ;;
  esac
done

echo "=== EpicFlow Worktree Cleanup ==="
echo "Staleness threshold: ${STALE_MINUTES} minutes"
if [ "$DRY_RUN" = true ]; then
  echo "Mode: DRY RUN (no removals)"
fi
if [ "$RECOVER" = true ]; then
  echo "Mode: RECOVER (will discard uncommitted changes in dirty worktrees)"
fi
echo ""

# Get list of worktrees
WORKTREES=$(git -C "$PROJECT_DIR" worktree list --porcelain 2>/dev/null | grep '^worktree ' | sed 's/^worktree //')

REMOVED=0
RECOVERED=0
SKIPPED_ACTIVE=0
SKIPPED_DIRTY=0
SKIPPED_MAIN=0

for WT_PATH in $WORKTREES; do
  # Skip the main working tree
  if [ "$WT_PATH" = "$PROJECT_DIR" ]; then
    continue
  fi

  # Only process worktrees under .claude/worktrees/
  case "$WT_PATH" in
    "$WORKTREE_DIR"/*) ;;
    *) SKIPPED_MAIN=$((SKIPPED_MAIN + 1)); continue ;;
  esac

  WT_NAME=$(basename "$WT_PATH")

  # If targeting a specific worktree, skip others
  if [ -n "$TARGET_NAME" ] && [ "$WT_NAME" != "$TARGET_NAME" ]; then
    continue
  fi

  AGENT_FILE="$WT_PATH/.agent-active"

  # Check 1: Is an agent actively working here?
  if [ -f "$AGENT_FILE" ]; then
    # Check file age
    if [[ "$OSTYPE" == "darwin"* ]]; then
      FILE_MOD=$(stat -f %m "$AGENT_FILE" 2>/dev/null || echo "0")
    else
      FILE_MOD=$(stat -c %Y "$AGENT_FILE" 2>/dev/null || echo "0")
    fi
    NOW=$(date +%s)
    AGE_SECONDS=$((NOW - FILE_MOD))
    AGE_MINUTES=$((AGE_SECONDS / 60))

    if [ "$AGE_MINUTES" -lt "$STALE_MINUTES" ]; then
      TASK_INFO=$(cat "$AGENT_FILE" 2>/dev/null | head -1)
      echo "SKIP (active): $WT_NAME — agent active ${AGE_MINUTES}m ago ($TASK_INFO)"
      SKIPPED_ACTIVE=$((SKIPPED_ACTIVE + 1))
      continue
    else
      echo "STALE: $WT_NAME — .agent-active is ${AGE_MINUTES}m old (threshold: ${STALE_MINUTES}m)"
    fi
  fi

  # Check 2: Are there uncommitted changes?
  UNCOMMITTED=$(git -C "$WT_PATH" status --porcelain 2>/dev/null || echo "")
  if [ -n "$UNCOMMITTED" ]; then
    UNCOMMITTED_COUNT=$(echo "$UNCOMMITTED" | wc -l | tr -d ' ')

    if [ "$RECOVER" = true ]; then
      # Discard all changes and proceed to removal
      if [ "$DRY_RUN" = true ]; then
        echo "WOULD RECOVER: $WT_NAME — discard ${UNCOMMITTED_COUNT} uncommitted change(s), then remove"
      else
        echo "RECOVERING: $WT_NAME — discarding ${UNCOMMITTED_COUNT} uncommitted change(s)"
        git -C "$WT_PATH" checkout -- . 2>/dev/null || true
        git -C "$WT_PATH" clean -fd 2>/dev/null || true
      fi
      RECOVERED=$((RECOVERED + 1))
    else
      echo "SKIP (dirty): $WT_NAME — has uncommitted changes:"
      echo "$UNCOMMITTED" | head -5 | sed 's/^/  /'
      if [ "$UNCOMMITTED_COUNT" -gt 5 ]; then
        echo "  ... and $((UNCOMMITTED_COUNT - 5)) more files"
      fi
      echo "  → Run with --recover to discard changes and remove"
      SKIPPED_DIRTY=$((SKIPPED_DIRTY + 1))
      continue
    fi
  fi

  # Check 3: Are there commits not merged to any branch?
  WT_BRANCH=$(git -C "$WT_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "HEAD" ]; then
    # Find the best parent branch: check orchestrator branches first, then main
    # Worker worktrees merge into orchestrator branches, not main directly.
    PARENT_BRANCH=""
    WT_HEAD=$(git -C "$WT_PATH" rev-parse HEAD 2>/dev/null)

    # Check if the worktree HEAD is reachable from any other local branch
    for candidate in $(git -C "$PROJECT_DIR" branch --format='%(refname:short)' 2>/dev/null); do
      [ "$candidate" = "$WT_BRANCH" ] && continue
      if git -C "$PROJECT_DIR" merge-base --is-ancestor "$WT_HEAD" "$candidate" 2>/dev/null; then
        PARENT_BRANCH="$candidate"
        break
      fi
    done

    # If no branch contains this work, fall back to main
    [ -z "$PARENT_BRANCH" ] && PARENT_BRANCH="main"

    UNMERGED=$(git -C "$PROJECT_DIR" log --oneline "$PARENT_BRANCH".."$WT_BRANCH" 2>/dev/null || echo "")
    if [ -n "$UNMERGED" ]; then
      UNMERGED_COUNT=$(echo "$UNMERGED" | wc -l | tr -d ' ')

      if [ "$RECOVER" = true ]; then
        if [ "$DRY_RUN" = true ]; then
          echo "WOULD DISCARD: $WT_NAME — ${UNMERGED_COUNT} unmerged commit(s) on branch $WT_BRANCH:"
          echo "$UNMERGED" | head -5 | sed 's/^/  /'
        else
          echo "WARNING: $WT_NAME — discarding ${UNMERGED_COUNT} unmerged commit(s) on branch $WT_BRANCH"
          echo "$UNMERGED" | head -5 | sed 's/^/  /'
        fi
        RECOVERED=$((RECOVERED + 1))
      else
        echo "SKIP (unmerged): $WT_NAME — has ${UNMERGED_COUNT} commit(s) on branch $WT_BRANCH not in $PARENT_BRANCH:"
        echo "$UNMERGED" | head -5 | sed 's/^/  /'
        if [ "$UNMERGED_COUNT" -gt 5 ]; then
          echo "  ... and $((UNMERGED_COUNT - 5)) more commits"
        fi
        echo "  → Cherry-pick with: git cherry-pick $WT_BRANCH"
        echo "  → Or discard with: worktree-cleanup.sh --recover $WT_NAME"
        SKIPPED_DIRTY=$((SKIPPED_DIRTY + 1))
        continue
      fi
    fi
  fi

  # Safe to remove
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD REMOVE: $WT_NAME"
  else
    echo "REMOVING: $WT_NAME"
    git -C "$PROJECT_DIR" worktree remove "$WT_PATH" 2>/dev/null || \
      git -C "$PROJECT_DIR" worktree remove "$WT_PATH" --force 2>/dev/null || \
      echo "  FAILED to remove $WT_NAME — may need manual cleanup"
  fi
  REMOVED=$((REMOVED + 1))
done

echo ""
echo "--- Summary ---"
if [ "$DRY_RUN" = true ]; then
  echo "Would remove: $REMOVED"
  echo "Would recover: $RECOVERED"
else
  echo "Removed: $REMOVED"
  echo "Recovered: $RECOVERED"
fi
echo "Skipped (active agent): $SKIPPED_ACTIVE"
echo "Skipped (uncommitted changes): $SKIPPED_DIRTY"

if [ "$SKIPPED_DIRTY" -gt 0 ]; then
  echo ""
  echo "Worktrees with uncommitted changes or unmerged commits were skipped."
  echo "If the work is already merged, run again with --recover to discard and remove."
  echo "If the work is NOT merged, cherry-pick the commits first, then clean up."
fi

exit 0
