# Hotfix SOP

Lightweight procedure for production emergencies.

## When to Use

- Production is broken and users are affected
- The issue cannot wait for normal milestone/epic flow
- A minimal, targeted fix is needed immediately

## Steps

### 1. Assess
Determine severity, scope, and who is affected. Ask:
- How many users are impacted?
- Is data being lost or corrupted?
- Is there a workaround?

This determines urgency. If there is a safe workaround, communicate it before coding.

### 2. Branch from production
```bash
git checkout -b hotfix/{description} production
```
Always branch from the production branch, not main. The fix must go to production first.

### 3. Fix
Make the minimal change that resolves the issue. One bug, one fix. Do not refactor adjacent code, do not add features, do not clean up "while you're here." Every extra line of change is extra risk in an emergency.

### 4. Test
Run the project check command (`{checkCommand}`) and any tests relevant to the affected area (`{testCommand}`). If time permits, manually verify the fix in a staging-like environment.

### 5. PR to production
Create a pull request targeting the production branch directly. The PR description should include:
- What broke
- Root cause (if known)
- What the fix does
- How it was tested

This bypasses the normal milestone flow intentionally.

### 6. Deploy
Merge the PR. Production deploys automatically on merge. Monitor logs and error rates after deployment to confirm the fix is effective.

### 7. Backport to main
```bash
git checkout main
git cherry-pick {commit-sha}
```
This ensures main does not regress when the next release is cut. Resolve any conflicts carefully.

### 8. Track root cause
Create a bd issue for root cause investigation:
```bash
bd create --title="Root cause: {description}" --type=bug --priority=2
```
The hotfix stops the bleeding. The follow-up issue prevents it from happening again.

## Expected Output

- Production fix deployed and verified
- Fix backported to main
- Root cause investigation issue created

## Rules

- NO refactoring
- NO feature work
- NO "while I'm here" changes
- NO dependency upgrades (unless the dependency is the root cause)
- Keep the diff as small as possible
