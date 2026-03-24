# Bug Fix SOP

Lightweight process for fixing bugs, failing tests, and regressions.

## When to Use

- Bug reports from users or QA
- Failing tests in CI or locally
- Regression fixes after a deploy or merge

## Expected Output

- Fix commit with minimal, targeted change
- Regression test that covers the specific bug

## Steps

### 1. Triage

- Determine severity (critical / major / minor)
- Reproduce the bug locally
- Identify affected area (tool, package, platform layer)
- Check if there's an existing bd issue; create one if not

### 2. Root Cause Analysis

- Read the code in the affected area
- Check `git blame` / `git log` to understand when and why the bug was introduced
- Identify the actual bug -- not just the symptom
- Verify the bug is not already fixed on another branch

### 3. Fix

- Make the minimal change needed to fix the bug
- Do NOT refactor surrounding code -- stay focused on the fix
- If the fix requires touching more than 3 files, reassess whether this is truly a bug fix or a feature/refactor
- Follow existing patterns in the codebase

### 4. Verify

- Confirm the original reproduction case now passes
- Add a regression test that would have caught this bug
- Run `bun run check` and `bun run test` to ensure no regressions
- If fixing a UI bug, verify visually in the browser

### 5. Document

- Update any affected documentation if the bug revealed a gap
- If the fix changes API behavior, update relevant docs
- Add a note to the bd issue with root cause and fix summary
