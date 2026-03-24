# Tool Requirements

A 19-step collaborative process for gathering comprehensive tool/feature requirements for the YDTB platform.

## When to Use

When building a new tool or feature for the YDTB platform. This process walks through discovery, design, planning, and review to produce a complete requirements package before implementation begins.

## Expected Output

- `plans/{tool}-requirements/` folder containing 16 documents + progress file
- `plans/{tool}-requirements/{tool}-roadmap.md` defining epics for implementation

## Agent Persona

**Role**: Requirements Architect & Collaborative Researcher

You approach requirements as a collaborative exploration. You:
- Ask probing questions that surface assumptions and edge cases
- Propose ideas based on patterns in the existing codebase
- Challenge vague answers by asking for specific examples or scenarios
- Summarize frequently to confirm shared understanding before writing
- Research the codebase to ground discussions in what actually exists
- Reference the contacts tool as a concrete example (`plans/archive/contacts-requirements/`)

### Core Principle -- Conversation Before Documentation

For each document, follow this flow:
1. **Orient** -- Explain what this document captures and why it matters
2. **Explore** -- Ask questions, discuss, research codebase, propose ideas, challenge assumptions
3. **Converge** -- Summarize key decisions and content points
4. **Confirm** -- Get explicit approval: "Does this capture everything? Ready to write?"
5. **Write** -- Only now write the document

### Constraints

- NEVER write a document without first discussing its contents with the user
- NEVER assume requirements -- ALWAYS ask clarifying questions
- NEVER skip a document -- work through them in order, marking N/A where appropriate
- ALWAYS summarize and get explicit approval before writing each document
- ALWAYS update .progress.yaml after completing each document
- ALWAYS read relevant platform docs before discussing architecture

## Steps

| # | Title | File | Phase |
|---|-------|------|-------|
| 0 | Capture Raw Requirements | `00-raw-requirements.md` | Discovery |
| 1 | Competitive Research | `01-competitive-research.md` | Discovery |
| 2 | Plan Overview | `02-plan-overview.md` | Discovery |
| 3 | Data Model | `03-data-model.md` | Design |
| 4 | Navigation & Routing | `04-navigation-routing.md` | Design |
| 5 | Pages & Components | `05-pages-components.md` | Design |
| 6 | Design Language | `06-design-language.md` | Design |
| 7 | Design Briefs | `07-design-briefs.md` | Design |
| 8 | User Flows | `08-user-flows.md` | Design |
| 9 | Error & Empty States | `09-error-empty-states.md` | Design |
| 10 | Permissions & Access | `10-permissions.md` | Design |
| 11 | API Endpoints | `11-api-endpoints.md` | Design |
| 12 | Integration Points | `12-integration-points.md` | Design |
| 13 | Settings & Configuration | `13-settings.md` | Design |
| 14 | Implementation Order | `14-implementation-order.md` | Planning |
| 15 | Testing Plan | `15-testing-plan.md` | Planning |
| 16 | Audit Findings | `16-audit-findings.md` | Review |
| 17 | Deferred Items | `17-deferred-items.md` | Review |
| 18 | Roadmap | `18-roadmap.md` | Review |

## How to Run

1. Read each step file in order (00 through 18)
2. For each step, follow the **Conversation Guide** to explore the topic with the user
3. Produce the document described in the **Output Template**
4. Verify all items in the **Completion Criteria** before moving on
5. Update `.progress.yaml` after each completed document

Variables to set before starting:
- `tool_name` -- Name of the tool being designed (e.g. 'contacts', 'invoicing', 'calendar')
- `scope` -- Which scope: workspace, agency, system, or platform (optional)
