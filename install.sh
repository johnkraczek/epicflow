#!/bin/bash
# EpicFlow Installer
#
# Creates symlinks from this repo into ~/.claude/ so that
# Claude Code picks up the commands, hooks, bin scripts, and agents.
#
# Usage: bash install.sh [--uninstall]
#
# Safe to re-run — skips existing symlinks that already point here.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Directories to link
DIRS=("commands" "hooks" "bin" "agents")

if [ "${1:-}" = "--uninstall" ]; then
  echo "Uninstalling EpicFlow..."
  for dir in "${DIRS[@]}"; do
    for file in "$REPO_DIR/$dir"/*; do
      base=$(basename "$file")
      target="$CLAUDE_DIR/$dir/$base"
      if [ -L "$target" ]; then
        echo "  Removing symlink: $target"
        rm "$target"
      fi
    done
  done
  echo "Done. EpicFlow commands removed from Claude Code."
  exit 0
fi

echo "Installing EpicFlow into $CLAUDE_DIR..."

for dir in "${DIRS[@]}"; do
  mkdir -p "$CLAUDE_DIR/$dir"
  for file in "$REPO_DIR/$dir"/*; do
    base=$(basename "$file")
    target="$CLAUDE_DIR/$dir/$base"

    if [ -L "$target" ]; then
      existing=$(readlink "$target")
      if [ "$existing" = "$file" ]; then
        echo "  OK (already linked): $dir/$base"
        continue
      else
        echo "  Replacing symlink: $dir/$base (was → $existing)"
        rm "$target"
      fi
    elif [ -e "$target" ]; then
      echo "  CONFLICT: $target exists and is not a symlink."
      echo "           Back it up and re-run, or remove it manually."
      echo "           Skipping $dir/$base."
      continue
    fi

    ln -s "$file" "$target"
    echo "  Linked: $dir/$base"
  done
done

# Ensure bin scripts are executable
chmod +x "$REPO_DIR"/bin/*.sh 2>/dev/null || true

echo ""
echo "EpicFlow installed. Run /epic-init in a project to get started."
