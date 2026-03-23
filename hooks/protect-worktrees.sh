#!/bin/bash
# EpicFlow — Worktree Protection (PreToolUse for Edit/Write)
# Prevents agents from modifying files inside other agents' worktrees

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=""

if [ "$TOOL" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
elif [ "$TOOL" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -q '\.claude/worktrees/'; then
  WORKTREE_NAME=$(echo "$FILE_PATH" | sed 's|.*\.claude/worktrees/||' | cut -d'/' -f1)
  if echo "$PWD" | grep -q "\.claude/worktrees/$WORKTREE_NAME"; then
    exit 0
  fi
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Attempted to modify files in worktree '${WORKTREE_NAME}' which belongs to another agent. Only modify worktrees you created."}}
JSON
  exit 0
fi

exit 0
