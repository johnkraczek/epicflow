# Step 1: Competitive Research

## Purpose

Research how competitors handle this type of tool. Organize findings into patterns to adopt and patterns to avoid, with clear rationale.

## Prerequisites

- Step 0 (Raw Requirements) must be complete
- `prompt.md` written and available for reference

## Conversation Guide

### Exploration Strategy

- What products does the user already use for this? What works well? What frustrates them?
- Have they seen this feature done well in any product? What specifically did they like?
- What are the industry-standard approaches? What's table-stakes vs innovative?
- Are there patterns we should explicitly avoid? Why?
- Help categorize patterns as "adopt" vs "avoid" with clear rationale

### Research Actions

- Discuss competitor products with the user
- Organize any screenshots the user provides in the `reference/` folder
- Name reference files descriptively (e.g., `competitor-inline-edit.png`, not `image.png`)

## Output Template

**File**: `plans/{{tool_name}}-requirements/00-competitive-research.md`

```
# {{tool_name}} -- Competitive Research

Research into how existing products handle this feature space.

---

## Products Reviewed

| Product | Relevant Feature | Notes |
|---------|-----------------|-------|
| ... | ... | ... |

---

## Patterns to Adopt

### Pattern N: [Name]

**Seen in**: [Product]
**What it does**: ...
**Why adopt it**: ...
**Reference**: reference/[screenshot].png

---

## Patterns to Avoid

### Anti-pattern N: [Name]

**Seen in**: [Product]
**What's wrong**: ...
**Our alternative**: ...

---

## Feature Comparison Matrix

| Feature | Product A | Product B | Product C | Our Plan |
|---------|-----------|-----------|-----------|----------|
| ... | ... | ... | ... | ... |

---

## Key Takeaways

- 3-5 bullet points summarizing the most important findings
```

## Completion Criteria

- [ ] At least one competitor product reviewed
- [ ] Patterns categorized as "adopt" or "avoid" with rationale
- [ ] Feature comparison matrix populated
- [ ] Key takeaways summarized
- [ ] Reference screenshots named descriptively in `reference/` folder
- [ ] `.progress.yaml` updated: competitive-research status set to complete
