<!--
================================================================================
Inspector Feedback Output Template

Inspector produces a Markdown document in this format after completing review.
- One feedback round corresponds to one review cycle
- Severity levels: P0 / P1 / P2
- Every feedback item must be actionable — vague suggestions are not allowed
- From round two onward, Inspector can only follow up on unresolved issues from previous round, cannot introduce new issues
================================================================================
-->

# Inspector Feedback Round <N>

**Test cases version**: <version of corresponding test case document>
**Inspector reviewed at**: <ISO 8601 timestamp>
**Methodologies applied**: <e.g. Equivalence Partitioning, BVA, Decision Table>

## Summary

| Severity | Count | Explanation |
|----------|-------|-------------|
| P0 | N | Must be fixed before proceeding to next phase |
| P1 | M | Recommended fix, Cartographer can decide not to fix but must fill rationale |
| P2 | K | Optional optimization, Cartographer can ignore |

## Findings

### P0 (Must Fix)

<!--
P0 criteria:
- Missing test coverage for core behaviors
- Critical boundary values not tested (e.g. security-related boundaries)
- Decision table branches omitted
- Test case and spec directly contradict
-->

#### P0-001: <One-sentence title>

- **Methodology**: <e.g. Decision Table Coverage>
- **Issue**: <specific problem description>
- **Affected**: <e.g. spec section B3 has no corresponding test case>
- **Suggested fix**: <e.g. add a TC with preconditions setting token expired, trigger visiting /reset-password, expected UI shows "link expired">

### P1 (Recommended Fix)

<!--
P1 criteria:
- Equivalence partition incomplete
- General boundary values not tested
- Test granularity too coarse or too fine
- Primary/backup/exception path classification unclear
-->

#### P1-001: <title>

- **Methodology**: <e.g. Equivalence Partitioning>
- **Issue**: ...
- **Suggested fix**: ...

### P2 (Optional Optimization)

<!--
P2 criteria:
- Test case description could be clearer
- Test case order could be more logical
- Comments and rationale could be more detailed
-->

#### P2-001: <title>

- **Issue**: ...
- **Suggested fix**: ...

## Methodology Coverage Self-Check

<!--
Only list methodologies **actually applied**. Do not write methodologies not in the feature characteristic list —
do not list "not applicable" as a placeholder.
Application rationale must specifically explain: why was this methodology chosen for this feature?
-->

| Methodology | Application Rationale | Issues Found |
|---|---|---|
| Equivalence Partitioning | This feature has 3 input fields (email, password, code) | 3 |
| Boundary Value Analysis | Same as above, and code has numeric range restrictions | 2 |
| Use Case Testing | This feature is an end-to-end login flow | 1 |
| Right-BICEP (I) | Triggered this activation condition: behaviors contain write semantics (create session) | 1 |

<!--
Note:
- If Decision Table, State Transition, multi-field combination and other methodologies were not selected,
  they **do not appear** in this table, rather than writing "not applicable"
- Right-BICEP must be followed by letter(s) indicating which aspect(s) triggered (I / C / P / multiple),
  if not triggered then do not list at all
-->

## What I Did Not Check

<!--
Inspector must honestly declare what it could not judge.
These will be left for human review.
-->

- Business correctness: Inspector does not read code, cannot judge "is this behavior what the business wants?"
- Correspondence between test cases and actual page elements: requires human cross-verification with real page
- Performance acceptability: unless spec explicitly specifies threshold
