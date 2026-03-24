#!/bin/bash
# EpicFlow — Dangerous Command Blocker (PreToolUse)
# Blocks destructive shell commands before they execute.
#
# Global patterns protect against universal dangers. Projects can extend
# with additional patterns by creating .claude/hooks/dangerous-commands.json:
#
#   {
#     "patterns": [
#       { "regex": "db:reset", "reason": "db:reset drops and rebuilds the local database." }
#     ],
#     "criticalPaths": ["supabase/migrations/"]
#   }

# Wrap everything in a function to catch unexpected errors.
# If anything goes wrong, exit 0 (allow) rather than outputting garbage to stdout.
trap 'exit 0' ERR

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# --- Global Claude directory protection (Edit/Write) ---
if [ -n "$FILE_PATH" ] && [ "${EPICFLOW_DEV:-0}" != "1" ]; then
  HOME_CLAUDE="$HOME/.claude"
  case "$FILE_PATH" in
    "$HOME_CLAUDE"/commands/*|"$HOME_CLAUDE"/hooks/*|"$HOME_CLAUDE"/bin/*|"$HOME_CLAUDE"/agents/*|"$HOME_CLAUDE"/settings.json)
      cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Cannot modify global EpicFlow files in ~/.claude/. These are managed by /epic-init and should only be updated manually or via a dedicated upgrade process. If you need to modify these files, ask the user to restart Claude with process-editing enabled."}}
JSON
      exit 0
      ;;
  esac
fi

# Nothing to check for Bash commands
if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Catastrophic commands (always block) ---
CATASTROPHIC_PATTERNS=(
  'rm -rf /'
  'rm -rf /*'
  'rm -rf ~'
  'rm -rf ~/'
  'rm -rf \.'
  'mkfs\.'
  'dd\s+if=.* of=/dev/'
  ':(){:|:&};:'
  '>\s*/dev/sd[a-z]'
  'chmod -R 777 /'
  'chown -R .* /'
)

for pattern in "${CATASTROPHIC_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Catastrophic command detected — '${pattern}' pattern matched. This command could destroy your system."}}
JSON
    exit 0
  fi
done

# --- Critical path protection (block destructive ops on important dirs) ---
CRITICAL_PATHS=(
  '\.claude/'
  '\.claude$'
  '\.git/'
  '\.git$'
  '\.env'
  '\.beads/'
  '\.beads$'
  'node_modules$'
)

DESTRUCTIVE_OPS='rm |rm -|rmdir |mv .* /dev/null|> '

for path in "${CRITICAL_PATHS[@]}"; do
  if echo "$COMMAND" | grep -qE "$DESTRUCTIVE_OPS" && echo "$COMMAND" | grep -qE "$path"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Destructive operation on critical path '${path}'. These files are protected from deletion/overwrite."}}
JSON
    exit 0
  fi
done

# --- Dangerous git operations ---
DANGEROUS_GIT=(
  'git push.*--force'
  'git push.*-f '
  'git reset --hard'
  'git checkout -- \.'
  'git restore \.'
)

for pattern in "${DANGEROUS_GIT[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Dangerous git command detected — '${pattern}'. This could cause irreversible data loss."}}
JSON
    exit 0
  fi
done

# --- bd (beads) database protection ---
if echo "$COMMAND" | grep -qE 'bd\s+init\s+.*--force|bd\s+init\s+--force'; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: 'bd init --force' wipes the entire beads issue tracker database. All issues, epics, and dependencies will be permanently lost. If the bd database is broken, ask the user to fix it manually or restore from a Dolt remote."}}
JSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'rm\s+.*\.beads/dolt'; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Deleting .beads/dolt removes the beads issue tracker database. All issues will be permanently lost."}}
JSON
  exit 0
fi

# --- Worktree protection (multi-agent safety) ---
if echo "$COMMAND" | grep -qE 'git\b.*\bworktree\s+(remove|prune)'; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Do not use git worktree remove/prune directly — another agent may be working in that worktree. Use: bash ~/.claude/bin/worktree-cleanup.sh"}}
JSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'git\b.*\bclean\b' && ! echo "$COMMAND" | grep -qE '\-e\s+\.claude'; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: git clean without excluding .claude/. Other agents may have active worktrees. Use 'git clean -fd -e .claude/' instead."}}
JSON
  exit 0
fi

# --- Block deleting the project root itself ---
if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r|--recursive)"; then
  # Block "rm -rf ." or "rm -rf ./" (deleting project root from inside)
  if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*)\s+\./?( |$)"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Cannot delete the project root directory. This would destroy the entire project."}}
JSON
    exit 0
  fi
  # Block the literal project dir path as target
  ESCAPED_PD=$(printf '%s' "$PROJECT_DIR" | sed 's/[.[\\*^$()+?{|]/\\&/g')
  if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*)\s+${ESCAPED_PD}/?( |$)"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Cannot delete the project root directory. This would destroy the entire project."}}
JSON
    exit 0
  fi
fi

# --- Project-specific extensions ---
EXTENSIONS="$PROJECT_DIR/.claude/hooks/dangerous-commands.json"
if [ -f "$EXTENSIONS" ]; then
  # Check custom patterns
  PATTERN_COUNT=$(jq -r '.patterns | length' "$EXTENSIONS" 2>/dev/null || echo "0")
  for i in $(seq 0 $((PATTERN_COUNT - 1))); do
    REGEX=$(jq -r ".patterns[$i].regex" "$EXTENSIONS" 2>/dev/null)
    REASON=$(jq -r ".patterns[$i].reason" "$EXTENSIONS" 2>/dev/null)
    if [ -n "$REGEX" ] && echo "$COMMAND" | grep -qE "$REGEX"; then
      cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: ${REASON}"}}
JSON
      exit 0
    fi
  done

  # Check custom critical paths
  PATHS=$(jq -r '.criticalPaths[]?' "$EXTENSIONS" 2>/dev/null)
  for path in $PATHS; do
    if echo "$COMMAND" | grep -qE "$DESTRUCTIVE_OPS" && echo "$COMMAND" | grep -q "$path"; then
      cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Destructive operation on project-protected path '${path}'."}}
JSON
      exit 0
    fi
  done
fi

# All checks passed
exit 0
