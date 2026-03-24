#!/bin/bash
# EpicFlow — Dangerous Command Blocker (PreToolUse)
# Blocks destructive shell commands before they execute.
#
# SAFETY: This script must ONLY output valid JSON deny responses or nothing.
# Any unexpected output (error messages, partial strings) causes Claude Code
# to show "BLOCKED: null". To prevent this, we run the real logic in a
# subshell and validate the output.
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

# Read stdin once, then run all checks. If anything crashes, allow the command.
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || true
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || true
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || true

# If jq failed to parse, allow the command
if [ -z "$TOOL_NAME" ] && [ -z "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Helper: output a valid deny JSON and exit. Uses jq to properly escape the reason string.
deny() {
  local reason="$1"
  jq -n --arg r "$reason" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}'
  exit 0
}

# --- Global Claude directory protection (Edit/Write) ---
if [ -n "$FILE_PATH" ] && [ "${EPICFLOW_DEV:-0}" != "1" ]; then
  HOME_CLAUDE="$HOME/.claude"
  case "$FILE_PATH" in
    "$HOME_CLAUDE"/commands/*|"$HOME_CLAUDE"/hooks/*|"$HOME_CLAUDE"/bin/*|"$HOME_CLAUDE"/agents/*|"$HOME_CLAUDE"/settings.json)
      deny "BLOCKED: Cannot modify global EpicFlow files in ~/.claude/. Ask the user to restart Claude with process-editing enabled."
      ;;
  esac
fi

# Nothing to check for Bash commands
if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Catastrophic commands (always block) ---
# NOTE: rm -rf with absolute paths is allowed IF the path is under PROJECT_DIR.
# Only block rm -rf targeting system root, home root, or current directory.
CATASTROPHIC_PATTERNS=(
  'rm -rf /[^A-Za-z]'    # rm -rf / or rm -rf /; but NOT rm -rf /Users/...
  'rm -rf /\s*$'          # rm -rf / at end of command
  'rm -rf /\*'            # rm -rf /*
  'rm -rf ~'
  'rm -rf ~/'
  'rm -rf \.\s*$'         # rm -rf . at end
  'rm -rf \./\s*$'        # rm -rf ./ at end
  'mkfs\.'
  'dd\s+if=.* of=/dev/'
  ':(){:|:&};:'
  '>\s*/dev/sd[a-z]'
  'chmod -R 777 /'
  'chown -R .* /$'
)

for pattern in "${CATASTROPHIC_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    deny "BLOCKED: Catastrophic command detected. This command could destroy your system."
  fi
done

# --- Block rm -rf outside project directory ---
# Allow rm -rf for paths under PROJECT_DIR, block everything else
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r|-rf)'; then
  # Extract paths from the rm command (everything after flags)
  RM_ARGS=$(echo "$COMMAND" | sed -E 's/rm\s+(-[a-zA-Z]+\s+)*//')
  for arg in $RM_ARGS; do
    # Skip flags
    [[ "$arg" == -* ]] && continue
    # Resolve to absolute path
    case "$arg" in
      /*) ABS_PATH="$arg" ;;
      *)  ABS_PATH="$PROJECT_DIR/$arg" ;;
    esac
    # Block if path is NOT under project directory
    case "$ABS_PATH" in
      "$PROJECT_DIR"/*) ;; # allowed — inside project
      *)
        deny "BLOCKED: recursive delete target is outside the project directory. Only paths under $PROJECT_DIR are allowed."
        ;;
    esac
  done
fi

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
    deny "BLOCKED: Destructive operation on a critical path. These files are protected."
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
    deny "BLOCKED: Dangerous git command detected. This could cause irreversible data loss."
  fi
done

# --- bd (beads) database protection ---
if echo "$COMMAND" | grep -qE 'bd\s+init\s+.*--force|bd\s+init\s+--force'; then
  deny "BLOCKED: bd init --force wipes the entire beads issue tracker database."
fi

if echo "$COMMAND" | grep -qE 'rm\s+.*\.beads/dolt'; then
  deny "BLOCKED: Deleting .beads/dolt removes the beads issue tracker database."
fi

# --- Worktree protection (multi-agent safety) ---
if echo "$COMMAND" | grep -qE 'git\b.*\bworktree\s+(remove|prune)'; then
  deny "BLOCKED: Do not use git worktree remove/prune directly. Use: bash ~/.claude/bin/worktree-cleanup.sh"
fi

if echo "$COMMAND" | grep -qE 'git\b.*\bclean\b' && ! echo "$COMMAND" | grep -qE '\-e\s+\.claude'; then
  deny "BLOCKED: git clean without excluding .claude/. Use git clean -fd -e .claude/ instead."
fi

# --- Block deleting the project root itself ---
if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r|--recursive)"; then
  # Block "rm -rf ." or "rm -rf ./" (deleting project root from inside)
  if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*)\s+\./?( |$)"; then
    deny "BLOCKED: Cannot delete the project root directory."
  fi
  # Block the literal project dir path as target
  ESCAPED_PD=$(printf '%s' "$PROJECT_DIR" | sed 's/[.[\\*^$()+?{|]/\\&/g')
  if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*)\s+${ESCAPED_PD}/?( |$)"; then
    deny "BLOCKED: Cannot delete the project root directory."
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
      deny "BLOCKED: ${REASON}"
    fi
  done

  # Check custom critical paths
  PATHS=$(jq -r '.criticalPaths[]?' "$EXTENSIONS" 2>/dev/null)
  for path in $PATHS; do
    if echo "$COMMAND" | grep -qE "$DESTRUCTIVE_OPS" && echo "$COMMAND" | grep -q "$path"; then
      deny "BLOCKED: Destructive operation on a project-protected path."
    fi
  done
fi

# All checks passed
exit 0
