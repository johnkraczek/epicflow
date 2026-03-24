---
description: "EpicFlow — Cut a release from main to production with version bump and release notes"
---

# EpicFlow Release

Creates a versioned release from `main` → `production`.

## Project Settings

Read `.epic/settings.json` for project-specific configuration. If it doesn't exist, exit with: "No EpicFlow project found. Run /epic-init first."

Use these values throughout:
- `testCommand` (default: project's test script) — e.g., `bun run test`
- `checkCommand` (default: project's check script) — e.g., `bun run check`
- `setupCommands` (default: package manager install) — e.g., `["bun install", "bun run generate"]`
- `github.org` and `github.repo` — auto-detect via `gh repo view --json owner,name` if not in settings
- `workspace.unattended` — `true` / `false`

## Phase 1: Gather Changes

1. Fetch latest tags and branches:
   ```bash
   git fetch origin --tags
   ```
2. Find the last release tag:
   ```bash
   gh release list --repo {org}/{repo} --limit 1 --json tagName --jq '.[0].tagName'
   ```
   - If no releases exist, this is the first release — compare against the initial commit on `production`
3. Get the comparison base:
   - If a previous release tag exists, use that tag
   - If no releases, use `origin/production` (or the root commit if production doesn't exist yet)
4. List all commits on `main` since the last release:
   ```bash
   git log {base}..origin/main --oneline --no-merges
   ```
5. List all merged PRs since the last release:
   ```bash
   gh pr list --repo {org}/{repo} --state merged --base main --json number,title,mergedAt,labels --jq '[.[] | select(.mergedAt > "{last_release_date}")]'
   ```

## Phase 2: Suggest Version

1. Read the current version from root `package.json` (`version` field)
   - If no `version` field exists, treat current version as `0.0.0`
2. Analyze the changes to suggest a version bump:
   - **Major**: breaking changes, major architectural shifts, or user explicitly included `BREAKING CHANGE` in commits/PRs
   - **Minor**: new features, new epics shipped (most common)
   - **Patch**: bug fixes only, no new features
3. Present the suggestion to the user:
   ```
   ## Release Summary

   **Changes since {last_version}:**
   - {PR #N}: {title}
   - ...

   **{commit_count} commits** across **{pr_count} PRs**

   **Suggested version: {suggested_version}** ({reason})

   Confirm this version or enter a different one:
   ```
4. Wait for user confirmation
   - User can confirm the suggested version or provide an override
   - Do NOT proceed until the user confirms

## Phase 3: Generate Release Notes

1. Group changes by category based on PR titles and commit messages:
   - **Features**: commits/PRs starting with `feat:`
   - **Fixes**: commits/PRs starting with `fix:`
   - **Performance**: commits/PRs starting with `perf:`
   - **Other**: everything else (chore:, refactor:, docs:, etc.)
2. Format release notes:
   ```markdown
   ## What's Changed

   ### Features
   - {description} ({PR link})

   ### Fixes
   - {description} ({PR link})

   ### Other
   - {description} ({PR link})

   **Full Changelog**: {compare_url}
   ```

## Phase 4: Update Version

1. Update the `version` field in the root `package.json`:
   - If the field doesn't exist, add it after the `"name"` field
   - Set it to the confirmed version (without `v` prefix)
2. Commit the version bump on `main`:
   ```bash
   git checkout main
   git pull origin main
   ```
   - Edit `package.json` with the new version
   ```bash
   git add package.json
   git commit -m "release: v{version}"
   git push origin main
   ```

## Phase 5: Create Release PR

1. Create a PR from `main` → `production`:
   ```bash
   gh pr create --title "Release v{version}" --base production --head main --repo {org}/{repo} --body-file - <<'EOF'
   ## Release v{version}

   {release_notes}

   ---
   *Created by EpicFlow release*
   EOF
   ```
2. Report the PR URL to the user
3. Enable auto-merge (merge commit):
   ```bash
   gh pr merge {pr_number} --auto --merge --repo {org}/{repo}
   ```

## Phase 6: Wait for Merge

1. Poll for PR merge (30s intervals, 10min max):
   ```bash
   gh pr view {pr_number} --repo {org}/{repo} --json state,statusCheckRollup
   ```
2. On CI failure: report to user and exit — do not attempt fixes on the production PR
3. On merge success: proceed to Phase 7

## Phase 7: Create GitHub Release

1. Create a git tag and GitHub release from the merge commit on `production`:
   ```bash
   gh release create v{version} --repo {org}/{repo} --target production --title "v{version}" --notes-file - <<'EOF'
   {release_notes}
   EOF
   ```

## Phase 8: Report

1. Pull latest main locally:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Report success:
   ```
   ## Release v{version} complete

   - PR: {pr_url}
   - Release: {release_url}
   - Tag: v{version}
   ```

---

_EpicFlow Release Command — powered by bd_
