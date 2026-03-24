# Step 18: Roadmap

## Purpose

Generate the epic roadmap from implementation order and requirements. The roadmap defines all epics that /epic-plan will create. This is the final deliverable of the tool requirements process.

## Prerequisites

- Step 17 (Deferred Items) must be complete
- All 16 completed documents available for deriving epics

## Conversation Guide

### Exploration Strategy

- Map implementation phases (doc 13) to epics
- Every deliverable MUST have Spec refs linking to the specific requirement docs
- Use epic ID format: `{NN}-{descriptive-slug}` (e.g., `01-foundation`, `02-api-layer`)
- Present roadmap summary to user for approval
- Once approved, this feeds directly into `/epic-plan`

### Research Actions

- Review all 16 completed documents
- Derive epic boundaries from implementation phases (doc 13)
- Ensure every requirement doc section is referenced by at least one epic

## Output Template

**File**: `plans/{{tool_name}}-requirements/{{tool_name}}-roadmap.md`

The roadmap should include:
- Epic ID and title for each epic
- Description of what the epic delivers
- Spec refs to specific requirement documents and sections
- Dependencies between epics
- Estimated complexity/size

Present roadmap summary to user for approval before writing.

## Completion Criteria

- [ ] All implementation phases mapped to epics
- [ ] Every epic has ID, title, description, spec refs, and dependencies
- [ ] Every requirement document section is referenced by at least one epic
- [ ] Dependencies between epics are correct
- [ ] Complexity/size estimates provided
- [ ] User has approved the roadmap
- [ ] `.progress.yaml` updated: all documents complete
- [ ] Roadmap is ready to feed into `/epic-plan`
