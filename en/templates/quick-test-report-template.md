<!--
================================================================================
Quick Feature Test Report Template

Use for quick single-feature verification. No full spec / test cases / Inspector required.
Core requirement: fast, real browser evidence, and explicit viewport limits.
================================================================================
-->

# Quick Feature Test: <feature name>

**Tested by**: Coordinator / Operator
**Started at**: <ISO 8601>
**Finished at**: <ISO 8601>
**Target URL**: <http://localhost:...>
**Tools used**: Browser Use / Browser Use + Screenshot Review / Playwright Script / Computer Use / Supabase Verify / API/Security Supplemental
**Artifact root**: `test-artifacts/<feature>/<YYYYMMDD-HHMMSS>/`

## Scope

- Target:<what this quick test covers>
- Out of scope:<dependencies, full flow, performance, security audit, etc.>
- Code changes allowed: yes / no
- Test data creation allowed: yes / no

## Environment

- Dev server:<command or "already running">
- Browser:<Codex in-app browser / Chrome>
- Viewport target:<desktop 1280x800 / mobile / small-codex-viewport>
- Viewport actual:<width x height>
- Viewport evidence note:<desktop evidence / small-codex-viewport evidence>

## Steps Executed

1. <user-facing step>
2. <user-facing step>
3. <user-facing step>

## Evidence

| Type | Path/Summary | Notes |
|----|----------|----|
| Screenshot | `screenshots/quick-001.png` | <screenshot note + viewport> |
| Console | <no errors / error summary> | <notes> |
| Dialog | <none / alert content> | <notes> |
| URL/client state | <final URL / cookie/localStorage summary> | <notes> |
| Server verify | <SQL/API/Supabase summary or "not verified"> | <notes> |

## Result

- **Status**: PASSED / FAILED / BLOCKED / NEEDS MANUAL REVIEW
- **Summary**:<one-line conclusion>

## Findings

| Finding | Evidence | Category | Recommendation |
|----|----|----|----|
| <issue or pass signal> | <screenshot/console/URL> | product bug / environment/setup issue / tool limitation / needs manual review | <next step> |

## Retest Notes

- <whether desktop viewport retest is needed>
- <whether to upgrade to Full Flow Test>
- <whether to add Playwright regression>
