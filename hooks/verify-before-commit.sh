#!/bin/bash
# EpicFlow — PreToolUse hook: blocks git commit unless wave is verified
# Only enforced when an active epic exists (.epic/state.md present)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Only intercept git commit commands
if [[ "$COMMAND" != git\ commit* ]]; then
  exit 0
fi

# Skip if not an EpicFlow project
if [ ! -f "$PROJECT_DIR/.epic/settings.json" ]; then
  exit 0
fi

# Skip if no active epic state
if [ ! -f "$PROJECT_DIR/.epic/state.md" ]; then
  exit 0
fi

# Allow non-wave commits
if echo "$COMMAND" | grep -qiE "WIP|planning|docs|audit|archive|epic-done|epic-ship|release"; then
  exit 0
fi

# Check for verification flag
if [ ! -f "/tmp/epicflow-verified" ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Wave not verified. Run: .claude/hooks/verify-wave.sh — tests and checks must pass before committing wave changes."}}
JSON
  exit 0
fi

rm -f /tmp/epicflow-verified
exit 0
