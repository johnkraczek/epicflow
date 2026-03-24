# Task Description Template

The default task description format for bd issues. The **Parent Context** section is critical -- it carries the "why" from the milestone and epic so the agent understands the bigger picture when making implementation decisions.

If `.beads/formulas/task-template.md` exists, use that instead.

## Template

```markdown
## Parent Context
- **Milestone**: {milestone title and goal}
- **Epic**: {epic title and brief}
- **Why**: {one sentence -- why this work matters in the bigger picture}

## Task
- **Role**: {role}
- **Points**: {N}

## Specification
{What to build/test -- detailed, actionable description}

## Key References
- {source file path} ({what to modify and why})

## Relevant Documentation
- {doc path} ({which section and why it matters for this task})
- {requirements/design refs from planning phase}

## Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}
- [ ] The project's check command passes

## Scope Boundaries
- Only modify files listed in Key References
- Do NOT touch: {excluded areas}
- If you discover out-of-scope issues, note them but don't fix them

## Dependencies
- Depends on: {task IDs or "none"}
- Blocks: {task IDs that depend on this}
```
