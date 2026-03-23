#!/bin/bash
# EpicFlow — PreToolUse hook: blocks commit if on wrong branch

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if [[ "$COMMAND" != git\ commit* ]]; then
  exit 0
fi

# Skip if not an EpicFlow project or bd not available
if [ ! -f "$PROJECT_DIR/.epic/settings.json" ]; then
  exit 0
fi

if ! command -v bd &>/dev/null; then
  exit 0
fi

EXPECTED_BRANCH=$(bd list --type epic --status in_progress --json 2>/dev/null | jq -r '.[0].metadata.branch // empty' 2>/dev/null)

if [ -z "$EXPECTED_BRANCH" ]; then
  exit 0
fi

CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)

if [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Wrong branch. Expected: $EXPECTED_BRANCH, Current: $CURRENT_BRANCH. Switch to the milestone branch before committing."}}
JSON
  exit 0
fi

exit 0
