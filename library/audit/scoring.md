# Audit Scoring

## Severity Weights

| Severity | Weight | Description |
|----------|--------|-------------|
| critical | 10 | Workspace isolation bypassed, security boundary violated, data integrity at risk |
| major    | 5  | Documented pattern violated in a way that affects maintainability, singleton broken, boundary crossed |
| minor    | 2  | Naming convention violated, structure inconsistency, missing but non-critical pattern |
| info     | 0  | Observation or suggestion, no immediate impact |

## Consistency Audit Scoring

Calculate scores per category:

```
Category Score = 100 - sum(severity_weights)
```

For each finding in a category, subtract the severity weight from 100. A category with no findings scores 100.

Example:
- CAT-01 has 1 major (5) and 2 minor (2+2) findings
- Score = 100 - 5 - 2 - 2 = 91

## Domain Audit Scoring

Calculate domain scores based on pass/fail counts:

```
Domain Score = (Pass / (Pass + Fail)) * 100
```

Rules:
- Only "pass" and "fail" count toward scoring
- "na" and "skip" are excluded from the denominator
- Overall Score = Sum of Domain Scores / 12

### Domain Summary Table Format

| #  | Domain        | Total | Pass | Fail | NA | Skip | Score |
|----|---------------|-------|------|------|----|------|-------|
| 01 | Architecture  | 13    |      |      |    |      |       |
| 02 | Code Quality  | 14    |      |      |    |      |       |
| 03 | Security      | 15    |      |      |    |      |       |
| 04 | Database      | 13    |      |      |    |      |       |
| 05 | API           | 12    |      |      |    |      |       |
| 06 | Plugin System | 14    |      |      |    |      |       |
| 07 | Frontend      | 14    |      |      |    |      |       |
| 08 | Dependencies  | 11    |      |      |    |      |       |
| 09 | Documentation | 12    |      |      |    |      |       |
| 10 | Testing       | 10    |      |      |    |      |       |
| 11 | Performance   | 10    |      |      |    |      |       |
| 12 | DevOps        | 12    |      |      |    |      |       |
|    | **Overall**   |**150**|      |      |    |      |       |

## Score Interpretation

| Range   | Rating    | Description |
|---------|-----------|-------------|
| 90-100% | Excellent | Minimal issues, strong platform health |
| 80-89%  | Good      | Manageable issues, address soon |
| 70-79%  | Fair      | Multiple issues, action plan needed |
| Below 70% | Poor    | Systemic issues, urgent remediation required |

## Report Outputs

1. `{audit_dir}/README.md` with:
   - Consistency scan summary table (all 24 categories, finding counts by severity, scores)
   - Domain audit summary table (all 12 domains, pass/fail/na/skip counts, scores)
   - Overall score and interpretation
   - Top findings by severity

2. `{audit_dir}/learnings.md` with process insights:
   - Documentation gaps
   - Drift patterns
   - Recurring themes
   - Systemic issues

3. Commit message format:
   ```
   audit: {type} audit {YYYY-MM-DD} -- {score}% ({finding_count} findings)
   ```

## Action Items

For each approved finding, create a bd issue:

```bash
bd create --title "Audit: {finding summary}" --type bug --description "{finding details}" --priority {0 for critical, 1 for major, 2 for minor, 3 for info}
```

Action items feed into bug-fix or feature SOPs for remediation.
