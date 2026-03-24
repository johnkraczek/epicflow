# Finding Format

## Core Principle

Findings must enable correct fixes, not just deletions. Every finding answers:

1. **What** -- the specific violation (file paths, line numbers, evidence)
2. **Why it matters** -- which principle/pattern it breaks and why that pattern exists (linked to docs)
3. **Original intent** -- what we were trying to achieve when this code was written
4. **Correct approach** -- how to implement it properly, referencing a canonical example
5. **Acceptance criteria** -- concrete, testable criteria for knowing the fix is right

The goal: make a thing -> wasn't made properly -> here's what we were trying to make -> make it properly -> done

NOT: make a thing -> wrong -> delete it -> done

## File Location

Write each finding to: `{audit_dir}/findings/CAT-XX-{category-slug}/finding-NNN.md`

Create the category directory if it doesn't exist. Findings within a category are numbered sequentially: `finding-001.md`, `finding-002.md`, etc.

## Finding Template

```markdown
---
id: CAT-XX-NNN
category: {category-slug}
severity: critical | major | minor | info
status: open
files:
  - path/to/violating/file.ts
doc_refs:
  - docs/NN-relevant-doc.md
created: {YYYY-MM-DD}
---

# [CAT-XX-NNN] {Concise title describing the violation}

## What

{Specific description of the violation. Include file:line references.}

**Evidence**:
- `path/to/file.ts:NN` -- {what's wrong at this location}
- `path/to/other-file.ts:NN` -- {related evidence}

## Why It Matters

{Explain which documented pattern this breaks and why that pattern exists.
Reference the specific docs file and section. Explain the architectural
consequence of this violation.}

## Original Intent

{Explain what the developer was trying to achieve when they wrote this code.
We are NOT saying the code is bad -- we are saying it tried to do the right
thing but needs adjustment to match the canonical pattern.}

## Correct Approach

{Show how to implement this correctly. Reference a canonical example from the
codebase. Include a code snippet showing the correct pattern.}

Reference: See `{path/to/canonical/example.ts}` for the pattern to follow.

## Acceptance Criteria

- [ ] {Specific, testable criterion}
- [ ] {Another criterion}
- [ ] `bun run check` passes
```

## Severity Guidelines

| Severity | Description |
|----------|-------------|
| **critical** | Workspace isolation bypassed, security boundary violated, data integrity at risk |
| **major** | Documented pattern violated in a way that affects maintainability, singleton broken, boundary crossed |
| **minor** | Naming convention violated, structure inconsistency, missing but non-critical pattern |
| **info** | Observation or suggestion, no immediate impact |

## Important Rules

1. **Be precise** -- every finding must have exact file paths and line numbers
2. **No false positives** -- if unsure, read the file and verify before writing a finding
3. **Reference canonical examples** -- always point to a correct implementation in the codebase
4. **Respect documented exceptions** -- if a pattern violation has a documented reason, it's not a finding
5. **One violation per finding** -- don't bundle unrelated issues. If the same violation appears in multiple files for the same reason, group them in one finding with multiple file references
6. **Use consistent numbering** -- findings numbered sequentially within each category

## Scope-Aware Verification

For each tool, agents should verify:
- Tools are in the correct scope directory for their data model
- Permission registrations use the correct scope hook
- Route registrations use the correct tier
- Cross-scope imports go through `@ydtb/db/schema` or hooks, never direct tool-to-tool imports

## Agent Prompt Template

Each agent receives:

```
You are scanning Group {X} ({name}) for consistency violations.

1. Read the docs index (docs/*.md) to understand the canonical patterns for your categories.
2. Scan the codebase (tools/, platform/, packages/) for violations against those patterns.
3. For each category in your group, look for code that contradicts documented conventions.
4. For security categories (Group E): also read auth config, middleware chains, route handlers, and DB queries.

Categories: {list category names and scan rules from above}
Audit directory: {path}

For each violation found, write a finding file to:
  {audit_dir}/findings/CAT-{NN}-{slug}/finding-{NNN}.md

Each finding has 5 parts: What, Why It Matters, Original Intent, Correct Approach, Acceptance Criteria.

Return a summary table of findings per category.
```

## Agent Return Format

After scanning all assigned categories, each agent returns:

```
## Scan Complete: Group {A/B/C/D/E}

| Category | Findings | Critical | Major | Minor | Info |
|----------|----------|----------|-------|-------|------|
| CAT-XX {name} | N | N | N | N | N |
| CAT-XX {name} | N | N | N | N | N |
| **Total** | **N** | **N** | **N** | **N** | **N** |

Finding files written to: {audit_dir}/findings/
```

## Status Values (Domain Audit)

| Status | Description |
|--------|-------------|
| pass   | Check verified and confirmed passing. Platform meets this requirement. |
| fail   | Check verified and confirmed failing. Platform does not meet this requirement. |
| na     | Not applicable to current state. Feature doesn't exist yet or doesn't apply. Include brief reason. |
| skip   | Intentionally skipped. Include detailed reason (e.g., "deferred to v2.0", "blocked by issue #123"). |

## Domain Check Recording Format

For each check:

```
## {CHECK-ID} {Title}

**Severity**: {critical|major|minor|info}
**Status**: {pass|fail|na|skip}
**Evidence**: {concrete details -- file paths, line numbers, test results}

**Notes**:
- {Additional context}
```

## Action Item Modes

- **Guided** (default): Present each finding, ask approve/reject/defer
- **Unattended**: Auto-approve all findings as action items

### Actions

For each finding:
- **Approve**: Create a bd issue for remediation
- **Reject**: Not a real violation. Document the reason (false positive, documented exception, etc.)
- **Defer**: Real issue but not now. Create bd issue with low priority.

### Creating Issues

For each approved item:

```bash
bd create --title "Audit: {finding summary}" --type bug --description "{finding details}" --priority {0 for critical, 1 for major, 2 for minor, 3 for info}
```

Approved items are written to `{audit_dir}/action-items/` and feed into bug-fix or feature SOPs.
