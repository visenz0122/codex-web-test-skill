<!--
================================================================================
Operator Test Execution Report Template

Operator produces this document after running tests.
Core principle: Operator only records faithfully, makes no judgment on correctness.
- Pass/fail judgment of test cases is made by Operator (based on test case expected values)
- But causation analysis of "why it failed" is not done (left to humans or subsequent agents)
- Unexpected situations are classified as critical / important / minor
================================================================================
-->

# Test Execution Report

**Test cases version**: <version of corresponding test cases>
**Executed by**: Operator
**Started at**: <ISO 8601>
**Finished at**: <ISO 8601>
**Tools used**: <Browser Use / Playwright Script / Screenshot Review / Computer Use / Supabase Verify / API/Security Supplemental>
**Artifact root**: <path to screenshots, traces, generated specs, logs>

## Summary

| Status | Count |
|--------|-------|
| Setup phase | succeeded / failed |
| Passed | N |
| Failed | M |
| Skipped (due to prerequisite failure) | K |
| Terminated due to critical anomaly | <0 or 1> |

## Setup Phase

<!--
Fill this section only when the spec's Setup Strategy field is non-empty (focused test mode).
Full-flow test mode can write "(no setup phase)".

If setup fails, all subsequent test cases are marked SKIPPED, and this section should detail the failure reason.
This phase is separated to allow humans to immediately judge: is the failure a problem with the feature being tested, or a test environment issue?
-->

- **Setup steps executed** (from spec Setup Strategy):
  1. <e.g. call `POST /test/login-as?email=alice@example.com`> — ✅ succeeded / ❌ failed
  2. <e.g. confirm cookie session_token exists> — ✅ succeeded / ❌ failed
  3. <e.g. navigate to `/chat`> — ✅ succeeded / ❌ failed
- **Status**: succeeded / failed
- **If failed**, detailed record:
  - Which step failed
  - Error message (HTTP response, console output, screenshot path)
  - Number of retry attempts
- **Conclusion**:
  - If setup failed → **subsequent test results are unreliable, this report is for prerequisite failure diagnosis only**
  - If setup succeeded → continue to test case results below

## Environment

<!--
Brief record of the test environment for reproducibility.
Operator does not need to start the environment (that's the user's responsibility), but should record what environment Operator actually ran on.
-->

- Browser: <e.g. Chrome 122>
- Test target URL: <e.g. http://localhost:3000>
- Test user identity: <e.g. logged-in state, not logged in, specific permissions>
- Viewport target: <desktop 1280x800 / desktop 1440x900 / tablet / mobile>
- Viewport actual: <width>x<height>
- Viewport evidence note: <normal desktop evidence / small-codex-viewport evidence / not layout-sensitive>

## Results

### TC-001: <test case title>

- **Status**: PASSED / FAILED / SKIPPED
- **Duration**: <e.g. 3.2s>
- **References**: B1, INV-C1
- **Codex-tool-plan used**: <tools actually used>
- **Operator-mode used**: <optional legacy compatibility field>
- **Viewport actual**: <width>x<height>

<!-- If PASSED, the following sections can be brief -->
<!-- If FAILED or has anomalies, document in detail -->

**Steps executed**

1. ✅ Visit /login
2. ✅ Submit form
3. ❌ Expected URL /dashboard, actual /login (still on login page)

**Observations**

- Final URL: /login
- Cookie session_token: does not exist
- Visible text: "Email or password incorrect"
- (if any) Screenshot: <path>
- (if any) Console errors: <content>

**Playwright trace summary** (only when Playwright Script is used)

<!--
When Playwright Script is used, Playwright produces trace.zip / report.html.
Give key summary here, not the entire report.
-->

- Script path: `tests/generated/TC-001.spec.ts`
- Execution command: `npx playwright test tests/generated/TC-001.spec.ts`
- Passed assertions: N items
- Failed assertions: M items (list each failed expect statement + actual value)
- Trace file: `test-results/TC-001/trace.zip` (for later debugging)
- Key screenshot: `test-results/TC-001/test-failed-1.png` (auto-generated failure screenshot)

**Screenshot Review** (when Browser Use + Screenshot Review or Playwright screenshot review is used)

<!--
For each screenshot point defined in the test case's Screenshot points, record the judgment result after LLM analyzes the image.
Each llm_judges question must have ✅ / ❌ + brief description.

If any judgment is ❌, this is an independent FAILED signal — even if Playwright part is all PASSED,
this TC's overall status is FAILED (any failure = FAILED).
-->

| Screenshot | Judgment question | Result | Description |
|------------|------------------|--------|-------------|
| TC-001-after-send.png | Is Markdown **important** rendered as bold? | ✅ | strong element exists in bubble |
| TC-001-after-send.png | Is # title rendered as H1? | ✅ | h1 element exists, font size normal |
| TC-001-after-send.png | Is overall bubble layout correct? | ❌ | Long text overflows bubble, touches right margin |

**Invariant checks**

- INV-C1 (URL does not contain password): ✅ passed
- INV-S1 (logs do not contain password): ⚠️ unable to verify (Operator has no log access)

**Frontend-backend data comparison** (only when verify involves both browser observation + server query)

<!--
Does this TC verify both "backend data" (SQL/API query) and "frontend rendering" (browser observation)?
If yes, **compare values on both sides for each data dimension** to precisely locate "frontend rendering fidelity" issues.

Classic scenario: backend SQL retrieves message.content as Markdown string "**Hello**",
but browser bubble displays literal string "**Hello**" (not rendered as bold) —
this bug cannot be caught by single-sided assertions, must observe both frontend and backend + compare.

If this TC does not involve frontend-backend comparison (pure frontend / pure backend assertion), omit this section.
-->

| Data dimension | Backend value (source) | Frontend rendering (browser observation) | Consistent? |
|---|---|---|---|
| Username | "Alice" (SQL: SELECT name FROM users WHERE id=1) | "Alice" (user bubble .username text) | ✅ |
| Timestamp | 2026-04-26T10:00:00Z (SQL: created_at) | "2026-04-26 18:00" (.timestamp text) | ✅ timezone conversion correct |
| Message Markdown | "**Important**" (SQL: messages.content) | "**Important**" (.bubble text, no `<strong>` element) | ❌ not rendered as bold |
| Number precision | 12345.67 (API response.amount) | "12,345.7" (.amount text) | ⚠ precision lost |

**Frontend rendering issue** (if inconsistency found):

- Description: Message Markdown not rendered — SQL data is `"**Important**"`, but frontend .bubble shows literal string
- Severity: moderate (affects reading experience, does not block functionality)
- Suggested causation direction: frontend Markdown renderer not enabled / wrong render timing / over-escaping function

**Anomalies**

<!--
If unexpected situations encountered (anomalies), record them here.
Classify by severity: critical / important / minor. Operator does not judge right/wrong, only records phenomena.
-->

- Severity: minor
- Description: After clicking login button, page top-right briefly flashes a toast notification not in expected list

### TC-002: ...

<!-- Repeat -->

## Anomalies Aggregated

<!--
Summary of all anomalies across test cases for convenient human review.
Sorted by severity descending.
-->

### Critical (causes test interruption or subsequent cases unable to run)

- None / list items

### Important (single test case fails but does not affect others)

- TC-005: browser rendering anomaly, but page text assertion passed
- TC-008: API response time > 30s

### Minor (does not affect assertions but worth noting)

- TC-001: unexpected toast appears (see above)
- TC-003: console has one warning (<content>)

## Skipped Test Cases

<!--
If some test cases did not run (due to prerequisite failure, critical anomaly, etc.), explain the reason.
-->

- TC-020: skipped, reason: depends on TC-019 state (TC-019 failed)
- TC-021 ~ TC-030: skipped, reason: critical anomaly triggered (browser crash), Operator proactively terminated

## What Operator Did Not Do

<!--
Operator must honestly declare what it did and did not do.
-->

- Did not judge whether a failed test case is a "bug in the system being tested" or "test case incorrectly written" — that is human's work
- Did not attempt to fix test cases or system code — outside Operator's responsibility
- Did not access database to verify server_state — unless the test case's expected explicitly indicates a verifiable method and Operator has permission to access
- Did not use small Codex-window screenshots as desktop layout-failure evidence unless explicitly marked `small-codex-viewport evidence`

## Viewport Evidence

| Purpose | Target viewport | Actual viewport | Evidence path | Conclusion boundary |
|---|---:|---:|---|---|
| <desktop layout / mobile layout / visual rendering> | <1280x800> | <1280x800> | <screenshot path> | <valid desktop evidence / small-codex-viewport evidence / needs retest> |

## Console / Dialog / Network Summary

- Console errors:
- Dialogs:
- Network failures:
- Downloads / OS-level events:

## Failure Classification Draft

| Finding | Category | Evidence | Retest recommendation |
|---|---|---|---|
| <finding> | product bug / test script bug / environment/setup issue / tool limitation / data pollution / needs manual review | <evidence path or summary> | <next retest> |

## Coordinator Final Review

- Overall result:
- Tool boundary check:
- Viewport conclusion:
- Data cleanup / pollution risk:
- Retest priority:
