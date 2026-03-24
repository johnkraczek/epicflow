#!/bin/bash
# EpicFlow — Dangerous Command Blocker (PreToolUse)
#
# Wrapper: runs the actual checks in a subshell and ONLY passes through
# valid deny JSON. Any other output (errors, partial strings, stderr leaks)
# is discarded. This prevents "BLOCKED: null" from malformed output.

IMPL="$(dirname "$0")/dangerous-command-blocker-impl.sh"

if [ ! -f "$IMPL" ]; then
  cat > /dev/null
  exit 0
fi

# Run impl, capture ALL output (stdout+stderr)
RESULT="$(bash "$IMPL" 2>&1)"
RC=$?

# Only pass through if it contains a valid deny response
if echo "$RESULT" | grep -q '"permissionDecision":"deny"' 2>/dev/null; then
  # Extract just the JSON line (in case stderr leaked into output)
  echo "$RESULT" | grep '"permissionDecision"'
fi

exit 0
