---
description: "EpicFlow — Switch between terminal and mobile notification channels"
---

# EpicFlow Mobile

Switch the notification channel between terminal and mobile mode.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

## Commands

### `/epic-mobile` or `/epic-mobile on`

Switch to mobile mode. Decisions will be sent to your phone via ntfy push notifications.

1. Read `.epic/settings.json` and verify `ntfy.enabled` is `true`
   - If ntfy is not configured: exit with "ntfy not configured. Run /epic-init to set up mobile notifications."
2. Update `workspace.channel` to `"mobile"`:
   ```bash
   jq '.workspace.channel = "mobile"' .epic/settings.json > /tmp/epic-settings.json && mv /tmp/epic-settings.json .epic/settings.json
   ```
3. Send a confirmation push notification:
   ```bash
   bash ~/.claude/bin/epic-notify.sh --force 3 "Mobile Mode Active" "EpicFlow decisions will come to your phone. Tap actions to respond."
   ```
4. Report: "Mobile mode active. Notifications will be sent to your phone. Run `/epic-mobile off` to switch back to terminal."

### `/epic-mobile off`

Switch to terminal mode. Decisions will use the terminal prompt. Only important background alerts (ESCALATE, handoff) will push to phone.

1. Update `workspace.channel` to `"terminal"`:
   ```bash
   jq '.workspace.channel = "terminal"' .epic/settings.json > /tmp/epic-settings.json && mv /tmp/epic-settings.json .epic/settings.json
   ```
2. Report: "Terminal mode active. Decisions will use the terminal prompt."

### `/epic-mobile status`

Show current notification status.

1. Read `.epic/settings.json`
2. Display:
   ```
   ## Notification Status

   **Channel**: {workspace.channel or "terminal" (default)}
   **ntfy enabled**: {ntfy.enabled}
   **ntfy server**: {ntfy.server}
   **Alert topic**: {ntfy.alertTopic}
   **Approval topic**: {ntfy.approvalTopic}
   **Timeout**: {ntfy.timeout}s
   ```
3. Test connectivity:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" --max-time 5 {ntfy.server}/v1/health
   ```
   - 200 → "Server: reachable"
   - Other → "Server: unreachable — notifications will fail"

---

_EpicFlow Mobile Command — powered by ntfy_
