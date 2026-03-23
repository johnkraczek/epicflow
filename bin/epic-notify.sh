#!/bin/bash
# EpicFlow — Push Notification (fire-and-forget)
#
# Usage:
#   epic-notify.sh <priority> <title> <message> [--tag emoji] [--mobile-only]
#   epic-notify.sh --go-mobile        # switch channel to mobile
#   epic-notify.sh --go-terminal      # switch channel to terminal
#
# Priority: 1=min, 2=low, 3=default, 4=high, 5=urgent
#
# Reads ntfy config from .epic/settings.json:
#   ntfy.server, ntfy.token, ntfy.alertTopic, ntfy.enabled
#
# Channel-aware: checks workspace.channel to decide whether to send.
#   --mobile-only: only send if channel is "mobile"
#   Without flag: always send (for important alerts like ESCALATE)

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SETTINGS="$PROJECT_DIR/.epic/settings.json"

# --- Channel switching commands ---
if [ "${1:-}" = "--go-mobile" ]; then
  if [ ! -f "$SETTINGS" ]; then
    echo "No .epic/settings.json found." >&2
    exit 1
  fi
  TMP=$(mktemp)
  jq '.workspace.channel = "mobile"' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  echo "Channel set to mobile."
  # Send confirmation push (bypass channel check)
  exec "$0" --force 3 "Mobile Mode" "Decisions will come to your phone."
fi

if [ "${1:-}" = "--go-terminal" ]; then
  if [ ! -f "$SETTINGS" ]; then
    echo "No .epic/settings.json found." >&2
    exit 1
  fi
  TMP=$(mktemp)
  jq '.workspace.channel = "terminal"' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  echo "Channel set to terminal."
  exit 0
fi

# --- Read settings ---
if [ ! -f "$SETTINGS" ]; then
  exit 0  # No settings, silently skip
fi

NTFY_ENABLED=$(jq -r '.ntfy.enabled // false' "$SETTINGS" 2>/dev/null)
if [ "$NTFY_ENABLED" != "true" ]; then
  exit 0  # Notifications disabled
fi

NTFY_SERVER=$(jq -r '.ntfy.server // empty' "$SETTINGS" 2>/dev/null)
NTFY_TOKEN=$(jq -r '.ntfy.token // empty' "$SETTINGS" 2>/dev/null)
NTFY_TOPIC=$(jq -r '.ntfy.alertTopic // empty' "$SETTINGS" 2>/dev/null)

if [ -z "$NTFY_SERVER" ] || [ -z "$NTFY_TOPIC" ]; then
  exit 0  # Not configured
fi

# --- Channel detection ---
get_channel() {
  if [ -f "$SETTINGS" ]; then
    local ch
    ch=$(jq -r '.workspace.channel // empty' "$SETTINGS" 2>/dev/null)
    if [ -n "$ch" ]; then echo "$ch"; return; fi
  fi
  if [ "${EPICFLOW_MOBILE:-0}" = "1" ]; then
    echo "mobile"; return
  fi
  if [ ! -t 0 ]; then
    echo "mobile"; return
  fi
  echo "terminal"
}

# --- Parse arguments ---
MOBILE_ONLY=false
FORCE=false
TAG=""
PRIORITY=""
TITLE=""
MESSAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --mobile-only) MOBILE_ONLY=true; shift ;;
    --force) FORCE=true; shift ;;
    --tag) TAG="$2"; shift 2 ;;
    *)
      if [ -z "$PRIORITY" ]; then PRIORITY="$1"
      elif [ -z "$TITLE" ]; then TITLE="$1"
      elif [ -z "$MESSAGE" ]; then MESSAGE="$1"
      fi
      shift ;;
  esac
done

if [ -z "$PRIORITY" ] || [ -z "$TITLE" ]; then
  echo "Usage: epic-notify.sh <priority> <title> <message> [--tag emoji] [--mobile-only]" >&2
  exit 1
fi

# --- Channel check ---
CHANNEL=$(get_channel)
if [ "$MOBILE_ONLY" = true ] && [ "$CHANNEL" != "mobile" ] && [ "$FORCE" != true ]; then
  exit 0  # Suppress in terminal mode
fi

# --- Build headers ---
AUTH_HEADER=""
if [ -n "$NTFY_TOKEN" ]; then
  AUTH_HEADER="-H \"Authorization: Bearer $NTFY_TOKEN\""
fi

TAG_HEADER=""
if [ -n "$TAG" ]; then
  TAG_HEADER="-H \"Tags: $TAG\""
fi

# --- Get branch for context ---
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")
PROJECT_NAME=$(basename "$PROJECT_DIR")

# --- Send notification ---
eval curl -s -o /dev/null --max-time 5 \
  -H \"Title: "$TITLE"\" \
  -H \"Priority: $PRIORITY\" \
  -H \"X-Project: $PROJECT_NAME\" \
  -H \"X-Branch: $BRANCH\" \
  $AUTH_HEADER \
  $TAG_HEADER \
  -d \""$MESSAGE"\" \
  "\"$NTFY_SERVER/$NTFY_TOPIC\"" 2>/dev/null || true

# Silent failure — never block the build
exit 0
