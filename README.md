# EpicFlow

An agentic software development lifecycle for Claude Code. EpicFlow manages the full lifecycle from requirements gathering through release, using parallel agent teams for execution and mobile push notifications for remote oversight.

## What It Does

- `/epic-init` — Bootstrap a project for epic-based development
- `/epic-plan` — Requirements → roadmap → milestone → epics → task decomposition
- `/epic-build` — Execute tasks in parallel waves using persistent agent teams
- `/epic-status` — Show current state, recommend next action
- `/epic-next` — Analyze open work and recommend what to do next
- `/epic-ship` — Ship a completed milestone: retrospective, PR, merge, archive
- `/epic-release` — Cut a versioned release from main to production
- `/epic-audit` — Scan codebase for pattern violations using parallel auditor agents
- `/epic-mobile` — Switch between terminal and mobile notification channels

## Install

```bash
git clone git@github.com:johnkraczek/epicflow.git ~/.epicflow
cd ~/.epicflow
bash install.sh
```

This creates symlinks from the repo into `~/.claude/` so Claude Code discovers the commands, hooks, and scripts.

## Update

```bash
cd ~/.epicflow
git pull
```

Symlinks mean updates are instant — no re-install needed.

## Uninstall

```bash
cd ~/.epicflow
bash install.sh --uninstall
```

## Getting Started

1. Install EpicFlow (see above)
2. Open Claude Code in your project
3. Run `/epic-init` to configure the project
4. Run `/epic-plan` to start planning your first milestone

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- [bd (beads)](https://github.com/steveyegge/beads) — issue tracker
- [gh](https://cli.github.com/) — GitHub CLI
- [jq](https://jqlang.github.io/jq/) — JSON processor

## Mobile Notifications (optional)

EpicFlow can send push notifications to your phone for approvals and alerts via [ntfy](https://ntfy.sh). Self-hosted or cloud.

Configure during `/epic-init` or see the [notification docs](docs/notifications.md) (coming soon).

## Architecture

```
/epic-plan → /epic-build → /epic-ship → /epic-release
     ↑            ↓              ↓
     └── /epic-audit ←───────────┘
```

- **Planning**: Context-sufficiency checks auto-proceed when the plan has enough detail, pause when human input is needed
- **Building**: Persistent agent teams with self-assigning workers, wave-based execution, file overlap detection, rollback support
- **Worker protocols**: PROGRESS, BLOCKED, CLARIFICATION, DISCOVERED_WORK, NEEDS_DECOMPOSE, SUCCESS, FAILED
- **Mobile**: Terminal/mobile channel switching, button-based and free-text approval from phone

## License

MIT
