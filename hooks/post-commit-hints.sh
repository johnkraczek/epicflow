#!/bin/bash
# EpicFlow — PostToolUse hook: non-blocking hints after git commit

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

BD_EPIC=$(bd list --type epic --status in_progress --json 2>/dev/null | jq -r '.[0].title // empty' 2>/dev/null)
if [ -z "$BD_EPIC" ]; then
  exit 0
fi

BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
LOCAL=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null)
REMOTE=$(git -C "$PROJECT_DIR" rev-parse "origin/$BRANCH" 2>/dev/null || echo "none")

if [ "$LOCAL" != "$REMOTE" ]; then
  echo "{\"reason\": \"Push to remote: git push origin $BRANCH.\"}"
fi

exit 0
