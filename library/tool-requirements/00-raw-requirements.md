# Step 0: Capture Raw Requirements

## Purpose

Capture the user's raw vision and requirements for {{tool_name}}. This is the unedited source of truth for "what the user asked for." The plan overview doc (step 2) captures interpreted decisions.

## Prerequisites

- None -- this is the first step
- Create directory: `plans/{{tool_name}}-requirements/` and `reference/` subfolder
- Initialize `.progress.yaml` with all documents set to pending (see progress format below)
- Scan existing tools in `tools/` to understand what's already built

## Conversation Guide

### Exploration Strategy

Ask these questions conversationally:

- What is this tool? What does it do at the highest level?
- Who uses it? What are they trying to accomplish?
- Walk me through the ideal experience -- what happens when a user opens this tool for the first time?
- What inspired this? Have you seen this done well elsewhere?
- What's the minimum viable version? What could be deferred to v2?
- Are there any hard constraints (tech, timeline, integration requirements)?
- Is this workspace-scoped, agency-scoped, or both?

### Research Actions

- Read `plans/archive/contacts-requirements/prompt.md` for an example of what good looks like
- Scan `tools/` directory to see what tools already exist

## Output Template

**File**: `plans/{{tool_name}}-requirements/prompt.md`

The document is a raw capture -- paste the conversation, feature requests, and constraints. Keep it unedited. The plan overview doc (step 2) captures interpreted decisions.

```
# {{tool_name}} -- Original Requirements

<!-- Raw requirements conversation, feature requests, and constraints -->
<!-- This is the source of truth for "what the user asked for." -->
<!-- Keep it unedited -- the plan overview doc captures interpreted decisions. -->
```

### Progress File Format (.progress.yaml)

```yaml
tool: "{{tool_name}}"
started: "<date>"
last_updated: "<date>"
documents:
  prompt: { status: pending, completed_at: null }
  competitive-research: { status: pending, completed_at: null }
  plan-overview: { status: pending, completed_at: null }
  data-model: { status: pending, completed_at: null }
  navigation-and-routing: { status: pending, completed_at: null }
  pages-and-components: { status: pending, completed_at: null }
  design-language: { status: pending, completed_at: null }
  design-briefs: { status: pending, completed_at: null }
  user-flows: { status: pending, completed_at: null }
  error-and-empty-states: { status: pending, completed_at: null }
  permissions-and-access: { status: pending, completed_at: null }
  api-endpoints: { status: pending, completed_at: null }
  integration-points: { status: pending, completed_at: null }
  settings-and-configuration: { status: pending, completed_at: null }
  implementation-order: { status: pending, completed_at: null }
  testing-plan: { status: pending, completed_at: null }
  audit-findings: { status: pending, completed_at: null }
  deferred-items: { status: pending, completed_at: null, issues_created: [] }
notes: []
```

## Completion Criteria

- [ ] Directory `plans/{{tool_name}}-requirements/` exists with `reference/` subfolder
- [ ] `.progress.yaml` initialized with all documents set to pending
- [ ] `prompt.md` written with raw requirements conversation
- [ ] User's core vision, target users, and constraints are captured
- [ ] Existing tools scanned and potential overlaps noted
- [ ] `.progress.yaml` updated: prompt status set to complete
