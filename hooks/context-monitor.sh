#!/bin/bash
# EpicFlow — Context Monitor Hook (PostToolUse)
# Tracks tool call count per session and warns when context is likely degrading.

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
COUNTER_FILE="/tmp/epicflow-ctx-${SESSION_ID}.count"

if [ ! -f "$COUNTER_FILE" ]; then
  echo "0" > "$COUNTER_FILE"
fi

COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ "$COUNT" -eq 250 ]; then
  echo "CONTEXT WARNING: ~60% context estimated used ($COUNT tool calls). Consider wrapping up the current wave and letting the next /epic-build invocation handle remaining waves."
elif [ "$COUNT" -eq 350 ]; then
  echo "CONTEXT CRITICAL: ~85% context estimated used ($COUNT tool calls). Finish current task and stop. Do NOT start a new wave. Write handoff state (.epic/continue-here.md) and exit."
elif [ "$COUNT" -gt 350 ] && [ $(( COUNT % 25 )) -eq 0 ]; then
  echo "CONTEXT CRITICAL: $COUNT tool calls. Write handoff and stop immediately."
fi

exit 0
