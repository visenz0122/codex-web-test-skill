# Execution Report: AI Chatbot Core Dialogue

> This is an execution report example corresponding to `chatbot-cases-example.md`.
> **Core showcase**: Codex-tool-plan, viewport evidence, Playwright trace, Screenshot Review, and Coordinator Final Review as they appear in actual reports.
> In real situations, running all 4 TCs would be longer; here we show details for 2 TCs, other TCs simplified.

## Summary

- **Total**: 4 test cases
- **Passed**: 2 (TC-001, TC-004)
- **Failed**: 2 (TC-002 rendering issue, TC-003 error message style issue)
- **Skipped**: 0
- **Duration**: 6m 12s
- **Setup status**: ✅ Success
- **Teardown status**: ✅ All recovered

## Setup Phase

- Call `POST /test/reset-messages` → 200 ✅
- Configure LLM mock → 200 ✅
- Browser navigate `/chat` → 200 ✅

## Environment

- Browser: Codex Browser Use / Playwright Chromium
- Test target URL: http://localhost:3000/chat
- LLM mock: enabled, fixture path `tests/fixtures/pneumonia-answer.txt`
- Viewport target: desktop 1280x800
- Viewport actual: 1280x800
- Viewport evidence note: all desktop layout judgments came from 1280x800 evidence; no small Codex-window screenshot was used as desktop failure evidence

## Results

### TC-001: User sends plain message, sees complete streaming reply

- **Status**: ✅ PASSED
- **Duration**: 24.3s
- **References**: B1, INV-C1, INV-C2
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport actual**: 1280x800

**Steps executed**

1. ✅ Browser navigate to `/chat`
2. ✅ Input "What is bacterial pneumonia?" in textarea
3. ✅ Click send button, record SSE start event
4. ✅ Screenshot point 1: `screenshots/TC-001-streaming.png`
5. ✅ Wait for SSE done event (actual duration 23.8s) — Screenshot point 2: `screenshots/TC-001-completed.png`

**Observations**

- Final URL: /chat
- textarea state: empty (has been cleared)
- SSE event sequence received: start → delta×42 → done

**Playwright trace summary**

- Script path: `tests/generated/TC-001.spec.ts`
- Execution command: `npx playwright test tests/generated/TC-001.spec.ts`
- Passed assertions: 8 items
  - `await expect(page.locator('textarea')).toBeEmpty()` ✅
  - `await expect(page.locator('.user-bubble').last()).toContainText('What is bacterial pneumonia?')` ✅
  - `await expect(page.locator('.assistant-bubble').last()).toBeVisible()` ✅
  - SQL: 2 message records ✅
  - (other 4 items SQL / cookie verification)
- Failed assertions: 0 items
- Trace file: `test-results/TC-001/trace.zip`

**Screenshot Review**

| Screenshot | Judgment question | Result | Description |
|----|--------|----|----|
| TC-001-streaming.png | User bubble + assistant bubble display simultaneously? | ✅ | Both side bubbles visible, alignment reasonable |
| TC-001-streaming.png | Send button changes to "Generating..." and disabled? | ✅ | Button text "Generating...", color fades to light gray |
| TC-001-streaming.png | textarea cleared? | ✅ | Completely cleared, displaying placeholder |
| TC-001-completed.png | Assistant bubble displays complete reply? | ✅ | 200-character reply fully visible |
| TC-001-completed.png | Send button restored to "Send" and clickable? | ✅ | Button text "Send", color normal blue |
| TC-001-completed.png | Overall bubble layout normal, no text overflow? | ✅ | Long text properly wrapped, no overflow |

**Invariant checks**

- INV-C1 (textarea cannot submit again during streaming): ✅ Passed (attempted to click send again during streaming, no effect)
- INV-C2 (user bubble and assistant bubble visible simultaneously): ✅ Passed (see screenshot TC-001-streaming)
- INV-S1 (user input stored as-is): ✅ Passed (SQL query returned raw string)
- INV-S2 (system prompt not leaked): ⚠️ Cannot directly verify (requires checking LLM mock internals), depends on human code review

**Anomalies**: None

---

### TC-002: Send Markdown message, front-end renders correctly

- **Status**: ❌ FAILED (2/4 visual judgments did not pass)
- **Duration**: 18.7s
- **References**: B2, INV-S1, INV-X1
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport actual**: 1280x800

**Steps executed**

1. ✅ Browser navigate to `/chat`
2. ✅ Input Markdown message in textarea (`**emphasis point 1**\n# large heading`)
3. ✅ Click send button
4. ✅ Wait for streaming to end (2.4s)
5. ✅ Screenshot point: `screenshots/TC-002-markdown.png`

**Observations**

- User message bubble DOM contains `<strong>` element ✅
- User message bubble DOM contains `<h1>` element ✅
- User message bubble DOM contains `<ol>` and `<li>` elements ✅
- SQL verification: user message content field stored as-is as Markdown string ✅

**Playwright trace summary**

- Script path: `tests/generated/TC-002.spec.ts`
- Passed assertions: 6 items
  - DOM contains strong / h1 / ol / li elements ✅
  - SQL content field stored as raw string ✅
- Failed assertions: 0 items
- Trace file: `test-results/TC-002/trace.zip`

**Screenshot Review**

| Screenshot | Judgment question | Result | Description |
|----|--------|----|----|
| TC-002-markdown.png | **emphasis point 1** rendered as bold (visibly bolder than body text)? | ❌ | DOM has `<strong>` element, but CSS `font-weight: bold` is ineffective — visually same thickness as body text. **Suspected front-end bug: CSS loading order or style override** |
| TC-002-markdown.png | # large heading rendered as large heading (font size noticeably larger than body)? | ❌ | `<h1>` element present, but actual font size only 1px larger than body, almost no visual difference. **Suspected front-end bug: h1 style overridden by global reset** |
| TC-002-markdown.png | List items 1. / 2. rendered as ordered list? | ✅ | Numbers displayed correctly, indentation reasonable |
| TC-002-markdown.png | Overall bubble layout normal, reasonable spacing between Markdown elements? | ✅ | Overall layout OK |

**Invariant checks**

- INV-S1 (user input stored as-is): ✅ Passed (SQL verification)
- INV-X1 (front-end rendering derived from content): ✅ Passed (DOM elements consistent with content)

**Anomalies**

- ⚠️ **Important**: DOM passes but visual fails — this is a typical "front-end rendering fidelity" problem.
  Playwright alone would pass (because it only checks for `<strong>` / `<h1>` element existence),
  but what users actually see is **unbolded "emphasis point 1" and non-enlarged "large heading"**.
  This type of bug can only be caught by Screenshot Review — proving the value of Browser Use / Playwright / Screenshot Review together.

**Root cause suggestions for developers**

- Check if global CSS overrides `<strong>` and `<h1>` styles
- Check if CSS scope of Markdown rendering container is effective
- Use browser Developer Tools "Computed" panel to check actual `font-weight` value of `<strong>` element

---

### TC-003: Streaming response error mid-stream, display error message

- **Status**: ❌ FAILED (1/3 visual judgments did not pass)
- **Duration**: 8.2s
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script
- **Viewport actual**: 1280x800

**Playwright trace summary**

- Passed assertions: 5 items (SSE error event received + status field updated, etc.)
- Failed assertions: 0 items

**Screenshot Review**

| Screenshot | Judgment question | Result | Description |
|----|--------|----|----|
| TC-003-error.png | Error message in red or warning color? | ❌ | Text "Connection interrupted, please retry" appears, but **color is normal gray** (same as body text), users difficult to notice this is an error. **Suspected front-end bug: error style class not applied** |
| TC-003-error.png | Partially received assistant content still visible? | ✅ | 2 chunks of content already displayed remain visible |
| TC-003-error.png | Send button restored to "Send" and clickable? | ✅ | Button already restored |

**Root cause suggestions for developers**

- Check if `.error-message` class CSS is effective
- Check if error message component correctly passes type="error" prop

---

### TC-004: Empty message send rejected

- **Status**: ✅ PASSED
- **Duration**: 1.8s
- **Codex-tool-plan used**: Browser Use + Screenshot Review
- **Viewport actual**: 1280x800

**Playwright trace summary**

Not applicable (this TC used Browser Use + Screenshot Review, no Playwright script).

**Screenshot Review**

| Screenshot | Judgment question | Result |
|----|--------|----|
| TC-004-empty-textarea.png | textarea displays placeholder? | ✅ |
| TC-004-empty-textarea.png | Send button disabled? | ✅ |
| TC-004-whitespace.png | Button still disabled after typing spaces? | ✅ |

**Anomalies**: None

---

## Anomalies Aggregated

### Critical level

None

### Important level

- **TC-002**: Markdown bold and heading visual styles ineffective — DOM passes but visual fails. May affect all users' Markdown reading experience.
- **TC-003**: Error message color not applying warning color — users may miss error message, thinking message was sent successfully.

### Minor level

- None

## Skipped Test Cases

None

## What Operator Did Not Do

- **INV-S2 (system prompt not leaked)**: Operator cannot directly verify LLM mock internal behavior,
  depends on human code review of `src/services/llm.js` to confirm.
- **Streaming character-by-character typewriter effect**: Per spec §3.4b engineering boundary, not tested this period.
- **emoji / long text boundary**: Not tested separately (marked ⚠ in scenario pattern self-check, not tested this period).

## Viewport Evidence

| Purpose | Target viewport | Actual viewport | Evidence path | Conclusion boundary |
|---|---:|---:|---|---|
| Desktop chat layout | 1280x800 | 1280x800 | `screenshots/TC-001-completed.png` | Valid desktop evidence |
| Markdown rendering | 1280x800 | 1280x800 | `screenshots/TC-002-markdown.png` | Valid desktop evidence |
| Error prompt style | 1280x800 | 1280x800 | `screenshots/TC-003-error.png` | Valid desktop evidence |

No small Codex-window screenshot was used to decide desktop layout failures.

## Failure Classification Draft

| Finding | Category | Evidence | Retest recommendation |
|---|---|---|---|
| TC-002 Markdown bold / heading visual style failure | product bug | DOM passed, 1280x800 screenshot failed visually | Fix CSS, rerun TC-002 |
| TC-003 error prompt color not warning-colored | product bug | 1280x800 screenshot showed normal gray text | Fix error style, rerun TC-003 |
| INV-S2 cannot be directly verified | needs manual review | Operator lacks LLM mock internals | Human reviews prompt-injection/service logic |

## Coordinator Final Review

- **Overall result**: Full Flow Test completed; 2 product bugs, 0 test script bugs, 0 environment/setup issues.
- **Tool boundary**: Web trigger actions were completed through Browser Use / Playwright UI operations; API did not replace user clicks.
- **Viewport conclusion**: Visual failures came from 1280x800 desktop evidence, not Codex small-window screenshots.
- **Retest priority**: Rerun TC-002 / TC-003 first; if Markdown container CSS changed broadly, rerun TC-001 for regression.

## Next Steps Recommendation

1. **Priority: fix visual bugs in TC-002 / TC-003** — affects user experience, but Playwright alone would miss
2. After fixes, **re-run these two TCs** to confirm visual bug resolution (only 2 TCs, low token cost)
3. Consider adding dedicated TC for emoji / long text scenarios — marked ⚠ in self-check this round, can be added next round
