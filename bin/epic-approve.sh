#!/bin/bash
# EpicFlow — Interactive Approval via ntfy
#
# Usage:
#   epic-approve.sh approve <title> <message>
#   epic-approve.sh choose <title> <message> --options "Label1:value1,Label2:value2"
#   epic-approve.sh confirm <title> <message>
#
# Types:
#   approve  — Allow / Deny buttons
#   choose   — Custom labeled buttons
#   confirm  — OK / Cancel buttons
#
# Output: prints the selected value to stdout
# Exit codes:
#   0 — response received
#   1 — timeout (no response within window)
#   2 — ntfy not configured or disabled
#
# In terminal mode: exits immediately with code 2 (caller should use terminal prompt)
# In mobile mode: sends notification and waits for response via SSE

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SETTINGS="$PROJECT_DIR/.epic/settings.json"

# --- Read settings ---
if [ ! -f "$SETTINGS" ]; then
  exit 2
fi

NTFY_ENABLED=$(jq -r '.ntfy.enabled // false' "$SETTINGS" 2>/dev/null)
if [ "$NTFY_ENABLED" != "true" ]; then
  exit 2
fi

NTFY_SERVER=$(jq -r '.ntfy.server // empty' "$SETTINGS" 2>/dev/null)
NTFY_TOKEN=$(jq -r '.ntfy.token // empty' "$SETTINGS" 2>/dev/null)
NTFY_WRITE_TOKEN=$(jq -r '.ntfy.writeToken // empty' "$SETTINGS" 2>/dev/null)
NTFY_ALERT_TOPIC=$(jq -r '.ntfy.alertTopic // empty' "$SETTINGS" 2>/dev/null)
NTFY_APPROVAL_TOPIC=$(jq -r '.ntfy.approvalTopic // empty' "$SETTINGS" 2>/dev/null)
NTFY_TIMEOUT=$(jq -r '.ntfy.timeout // 120' "$SETTINGS" 2>/dev/null)

if [ -z "$NTFY_SERVER" ] || [ -z "$NTFY_ALERT_TOPIC" ] || [ -z "$NTFY_APPROVAL_TOPIC" ]; then
  exit 2
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

CHANNEL=$(get_channel)
if [ "$CHANNEL" != "mobile" ]; then
  exit 2  # Not in mobile mode — caller should use terminal prompt
fi

# --- Parse arguments ---
TYPE="${1:-}"
TITLE="${2:-}"
MESSAGE="${3:-}"
OPTIONS=""

shift 3 2>/dev/null || true

while [ $# -gt 0 ]; do
  case "$1" in
    --options) OPTIONS="$2"; shift 2 ;;
    --timeout) NTFY_TIMEOUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$TYPE" ] || [ -z "$TITLE" ]; then
  echo "Usage: epic-approve.sh <type> <title> <message> [--options 'Label1:value1,Label2:value2']" >&2
  exit 1
fi

# --- Generate request ID ---
REQ_ID="$(date +%s)-$$"

# --- Build action buttons ---
build_actions() {
  local actions="[]"
  local approval_url="$NTFY_SERVER/$NTFY_APPROVAL_TOPIC"

  # Use write token for action buttons (scoped, write-only access to approval topic)
  local wtoken="${NTFY_WRITE_TOKEN:-$NTFY_TOKEN}"

  case "$TYPE" in
    approve)
      actions=$(jq -n --arg url "$approval_url" --arg id "$REQ_ID" --arg wt "$wtoken" '[
        {"action": "http", "label": "Allow", "url": $url, "method": "POST", "headers": {"Authorization": ("Bearer " + $wt)}, "body": ("allow|" + $id), "clear": true},
        {"action": "http", "label": "Deny", "url": $url, "method": "POST", "headers": {"Authorization": ("Bearer " + $wt)}, "body": ("deny|" + $id), "clear": true}
      ]')
      ;;
    confirm)
      actions=$(jq -n --arg url "$approval_url" --arg id "$REQ_ID" --arg wt "$wtoken" '[
        {"action": "http", "label": "OK", "url": $url, "method": "POST", "headers": {"Authorization": ("Bearer " + $wt)}, "body": ("ok|" + $id), "clear": true},
        {"action": "http", "label": "Cancel", "url": $url, "method": "POST", "headers": {"Authorization": ("Bearer " + $wt)}, "body": ("cancel|" + $id), "clear": true}
      ]')
      ;;
    choose)
      if [ -z "$OPTIONS" ]; then
        echo "Error: --options required for 'choose' type" >&2
        exit 1
      fi
      actions="[]"
      IFS=',' read -ra PAIRS <<< "$OPTIONS"
      for pair in "${PAIRS[@]}"; do
        local btn_label="${pair%%:*}"
        local btn_value="${pair#*:}"
        actions=$(echo "$actions" | jq --arg url "$approval_url" --arg id "$REQ_ID" \
          --arg btn "$btn_label" --arg val "$btn_value" --arg wt "$wtoken" \
          '. + [{"action": "http", "label": $btn, "url": $url, "method": "POST", "headers": {"Authorization": ("Bearer " + $wt)}, "body": ($val + "|" + $id), "clear": true}]')
      done
      ;;
    text)
      # Opens custom reply page with write token in URL hash (not sent to server logs)
      local reply_url="$NTFY_SERVER/reply.html#t=$wtoken&topic=$NTFY_APPROVAL_TOPIC&id=$REQ_ID&s=$NTFY_SERVER&title=$(printf '%s' "$TITLE" | jq -sRr @uri)&msg=$(printf '%s' "$MESSAGE" | jq -sRr @uri)"
      actions=$(jq -n --arg url "$reply_url" '[
        {"action": "view", "label": "Reply", "url": $url, "clear": true}
      ]')
      ;;
    *)
      echo "Error: unknown type '$TYPE'. Use: approve, choose, confirm, text" >&2
      exit 1
      ;;
  esac

  echo "$actions"
}

ACTIONS=$(build_actions)

# --- Build auth header ---
AUTH=""
if [ -n "$NTFY_TOKEN" ]; then
  AUTH="Bearer $NTFY_TOKEN"
fi

# --- Get context ---
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")
PROJECT_NAME=$(basename "$PROJECT_DIR")

# --- Send notification with actions ---
PAYLOAD=$(jq -n \
  --arg topic "$NTFY_ALERT_TOPIC" \
  --arg title "$TITLE" \
  --arg message "$MESSAGE [$PROJECT_NAME:$BRANCH]" \
  --arg priority "4" \
  --arg tag "question" \
  --argjson actions "$ACTIONS" \
  '{topic: $topic, title: $title, message: $message, priority: ($priority | tonumber), tags: [$tag], actions: $actions}')

SEND_HEADERS=(-H "Content-Type: application/json")
if [ -n "$AUTH" ]; then
  SEND_HEADERS+=(-H "Authorization: $AUTH")
fi

curl -s -o /dev/null --max-time 10 \
  "${SEND_HEADERS[@]}" \
  -d "$PAYLOAD" \
  "$NTFY_SERVER" 2>/dev/null || {
    echo "Failed to send notification" >&2
    exit 1
  }

# --- Wait for response via SSE ---
DECISION=""

SSE_HEADERS=(-H "Accept: text/event-stream")
if [ -n "$AUTH" ]; then
  SSE_HEADERS+=(-H "Authorization: $AUTH")
fi

while IFS= read -r line; do
  if [[ "$line" == data:* ]]; then
    DATA="${line#data: }"
    MSG=$(echo "$DATA" | jq -r '.message // empty' 2>/dev/null)
    if [ -z "$MSG" ]; then continue; fi
    # Match our request ID
    if [[ "$MSG" == *"|$REQ_ID" ]]; then
      DECISION="${MSG%%|*}"
      break
    fi
  fi
done < <(curl -s -N --max-time "$NTFY_TIMEOUT" \
  "${SSE_HEADERS[@]}" \
  "$NTFY_SERVER/$NTFY_APPROVAL_TOPIC/sse" 2>/dev/null)

if [ -n "$DECISION" ]; then
  echo "$DECISION"
  exit 0
else
  exit 1  # Timeout — no response
fi
