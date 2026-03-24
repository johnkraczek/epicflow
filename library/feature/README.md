# Feature SOP

Lightweight feature decomposition for small-to-medium work that doesn't need the full 19-step tool-requirements process.

## When to Use

- Small-to-medium features (5-20 story points)
- Features where the design is already clear
- Enhancements to existing tools or systems
- NOT for new tools or major architectural changes (use [tool-requirements](../tool-requirements/README.md) instead)

## Expected Output

- Decomposed tasks in bd, ready for /epic-build

## Steps

### 1. Brief

Write a 1-paragraph description of the feature plus success criteria.

```
**Feature**: {one paragraph describing what to build and why}

**Success Criteria**:
- [ ] {criterion 1}
- [ ] {criterion 2}
- [ ] {criterion 3}
```

### 2. Decompose

Break the feature into test/impl task pairs. Each pair consists of:

1. A test task (write tests first)
2. An implementation task (make the tests pass)

Use the [task template](../task-template.md) for each task description.

Guidelines:
- Each task should be 1-3 story points
- Tasks should be independently completable
- Define clear dependencies between tasks
- Include a final integration/smoke test task

### 3. Build

Execute tasks using /epic-build. Tasks are picked up in dependency order.

### 4. Review

- Verify all success criteria from the brief are met
- Run `bun run check` and `bun run test`
- Verify the feature works end-to-end in the browser
- Close the bd issues
