# Step 17: Deferred Items

## Purpose

Collect all deferred items from throughout the process and create bd issues for them. This step does NOT produce a document file -- it files issues in the beads tracker.

## Prerequisites

- Step 16 (Audit Findings) must be complete
- All preceding documents available to scan for deferred items

## Conversation Guide

### Process

For each deferred item identified throughout the process:

1. Determine type (bug, feature, enhancement)
2. Search existing bd issues to avoid duplicates: `bd list`
3. Create bd issue: `bd create --title="{title}" --type={type} --priority=3`
4. Also check GitHub for matching issues -- import any relevant ones

### Research Actions

- Scan all preceding documents for items marked as deferred, v2, or out of scope
- Check `bd list` for existing issues to avoid duplicates
- Check GitHub issues for matching items

## Output Template

No document file is produced. Instead:

- Create bd issues for each deferred item
- Record created bd issue IDs in `.progress.yaml` under `deferred-items.issues_created`

Example `.progress.yaml` update:
```yaml
deferred-items: { status: complete, completed_at: "<date>", issues_created: ["abc12", "def34", "ghi56"] }
```

## Completion Criteria

- [ ] All deferred items from all documents identified
- [ ] Duplicate check performed against existing bd issues
- [ ] bd issues created for each deferred item
- [ ] Issue IDs recorded in `.progress.yaml` under `deferred-items.issues_created`
- [ ] `.progress.yaml` updated: deferred-items status set to complete
