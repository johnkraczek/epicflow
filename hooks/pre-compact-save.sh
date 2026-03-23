#!/bin/bash
# EpicFlow — PreCompact hook: saves bd state to MEMORY.md so it survives compaction

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Skip if not an EpicFlow project or bd not available
if [ ! -f "$PROJECT_DIR/.epic/settings.json" ]; then
  exit 0
fi

if ! command -v bd &>/dev/null; then
  exit 0
fi

# Derive memory directory path (Claude's sanitization: replace / with -)
SANITIZED=$(echo "$PROJECT_DIR" | sed 's|/|-|g')
MEMORY_DIR="$HOME/.claude/projects/${SANITIZED}/memory"
MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

BD_STATE=$(bd list --status in_progress --json 2>/dev/null || echo "[]")
BD_READY=$(bd ready --json 2>/dev/null || echo "[]")
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")

if [ "$BD_STATE" = "[]" ] && [ "$BD_READY" = "[]" ]; then
  exit 0
fi

mkdir -p "$MEMORY_DIR"

if [ -f "$MEMORY_FILE" ]; then
  sed -i '' '/^<!-- BEGIN EPICFLOW STATE -->/,/^<!-- END EPICFLOW STATE -->/d' "$MEMORY_FILE" 2>/dev/null || \
  sed -i '/^<!-- BEGIN EPICFLOW STATE -->/,/^<!-- END EPICFLOW STATE -->/d' "$MEMORY_FILE" 2>/dev/null
fi

cat >> "$MEMORY_FILE" <<BLOCK

<!-- BEGIN EPICFLOW STATE -->
## EpicFlow State (saved before compaction)

**Branch**: $BRANCH

### In Progress
\`\`\`json
$BD_STATE
\`\`\`

### Ready Tasks
\`\`\`json
$BD_READY
\`\`\`

**Quick Reference:**
- View all work: \`bd list\`
- Ready tasks: \`bd ready\`
- Show task details: \`bd show {id}\`
- Commands: /epic-plan, /epic-build, /epic-ship, /epic-status, /epic-audit
<!-- END EPICFLOW STATE -->
BLOCK

if [ -f "$PROJECT_DIR/.epic/continue-here.md" ]; then
  echo "Note: Active handoff exists at .epic/continue-here.md — resume with /epic-build"
fi

echo "EpicFlow state saved to MEMORY.md (bd-native)"
exit 0
