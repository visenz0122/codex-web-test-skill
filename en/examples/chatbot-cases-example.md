# Test Cases: AI Chatbot Core Dialogue

> This is a test case example corresponding to `chatbot-spec-example.md`.
> **Core showcase**: Full Flow Test with `Codex-tool-plan`, viewport evidence, and complete Screenshot points.
> For simplicity, only 4 representative test cases are shown; real situations would have 8-10.

## Quick Feature Test Usage

If the change only touches the send button, input disabled state, or one reply rendering case, Coordinator can choose Quick Feature Test:

- Browser Use opens `/chat` and records the actual viewport.
- Send one message and observe streaming / completed state.
- Collect screenshot, console/dialog/network summary.
- Output compact finding classification without forcing full spec / Inspector.

The rest of this file shows the Full Flow Test form for AI chatbot acceptance.

## Coverage Summary

| Path type | Number of test cases | Covered behavior |
|---------|------|----------------|
| Main path | 2 | B1, B2 |
| Alternative path | 0 | — |
| Exception path | 2 | B4 (interruption), B5 (empty message) |
| Invariant verification | 1 | **TC-005**: INV-S1 + INV-C3 (XSS security) |

## Resource Dependency Matrix

| Shared resource | Destructive test case | Dependent test case | Has teardown recovery | Remarks |
|---------|---------|--------|------------------|----|
| messages table | TC-001, TC-002, TC-003, TC-005 (all add new messages) | None (each TC validates independently) | ✓ Each TC teardown deletes its own created records | Closed loop |
| LLM mock | All test cases (consume mock quota) | All test cases | ✓ mock has unlimited responses, no consumption | Closed loop |
| (TC-004 no side effects — not in this table) | — | — | — | — |

## Scenario Pattern Coverage Self-Check

### Pattern 1: Conversational UI

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Textarea clears after sending message | ✓ | TC-001 |
| User bubble + assistant bubble display simultaneously | ✓ | TC-001 (LLM screenshot judgment) |
| Disable resend during streaming | ✓ | TC-001 |
| Reject empty message | ✓ | TC-004 |

### Pattern 2: Asynchronous / Streaming output

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Stream's done event properly terminates | ✓ | TC-001 |
| Error handling during stream interruption | ✓ | TC-003 |
| Streaming character-by-character visual effect | OOS | spec §3.4b engineering boundary (LLM screenshot cannot determine precisely) |

### Pattern 3: LLM agent decision-making

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| LLM output stored in messages table | ✓ | TC-001 (SQL verify) |
| system prompt not leaked to client | ✓ | TC-005 (INV-S2 test) |
| Factual correctness of LLM responses | OOS | spec §3.4a business boundary (owned by content review team) |

### Pattern 4: Front-end rendering fidelity (critical pattern — must use Screenshot Review)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Markdown bold / heading rendering | ✓ | TC-002 (LLM screenshot judgment) |
| Markdown list rendering | ✓ | TC-002 |
| **HTML escape security (`<script>` input does not execute)** | ✓ | **TC-005 (INV-S1 + INV-C3 combined verification)** |
| **Attribute injection protection (`<img onerror>`)** | ✓ | **TC-005** |
| emoji display without boxes / question marks | ⚠ | Not tested separately this period; suggest adding emoji-specific TC next period |
| Long text does not overflow bubble | ⚠ | Same as above |
| Timezone display matches user region | OOS | This chatbot does not display timestamps |
| Error message visual (red / warning color) | ✓ | TC-003 (LLM screenshot judgment) |

### Pattern 5: State transition

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| idle → streaming → completed | ✓ | TC-001 (send button text change) |
| streaming → error transition | ✓ | TC-003 |
| Retry after error returns to idle | ✓ | TC-003 end |

### Pattern 6: Exception paths (general)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Network interruption | ⚠ | spec §3.4b engineering boundary (cannot truly simulate, use mock instead) |
| LLM service 5xx | ✓ | TC-003 (mock returns error event) |
| Input validation (empty message) | ✓ | TC-004 |

## Codex Execution Contract

- **Default viewport**: desktop 1280x800. Screenshots must record actual viewport; Codex small-window screenshots are only `small-codex-viewport evidence`.
- **Browser Use**: preferred for sending messages, observing streaming UI, error prompts, and empty-message button state.
- **Browser Use + Screenshot Review**: Markdown, bubble layout, long text wrapping, error color, responsive checks.
- **Playwright Script**: SSE waits, repeatable flow, trace, DOM/SQL/API assertions.
- **Computer Use**: only for downloads, desktop popups, or native file picker; not needed by default.
- **Supabase Verify**: auxiliary messages/auth/session/state verification only if the project uses Supabase.
- **API/Security Supplemental**: XSS, system prompt leakage, and direct illegal requests; normal message sending still starts from browser UI.

## Test Cases

### TC-001: User sends plain message, sees complete streaming reply

- **Path type**: Main path
- **References**: B1, INV-C1, INV-C2
- **Method applied**: Equivalence Partitioning - valid input representative
- **Destructive**: yes (adds new messages records)
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport target**: desktop 1280x800

<!--
- Data dimension: verify messages table new records, textarea clears (Playwright precise)
- Visual dimension: verify user bubble + assistant bubble display simultaneously, send button changes to "Generating..." during streaming (LLM screenshot judgment)
Both are needed → Browser Use / Screenshot Review / Playwright combination
-->

**Screenshot points**

```yaml
- after_step: 4  # streaming just started (after SSE start event, delta still accumulating)
  save_to: screenshots/TC-001-streaming.png
  llm_judges:
    - "Does the page display both user bubble (right) and assistant bubble (left) simultaneously?"
    - "Does the send button text change to 'Generating...' and appear in disabled gray state?"
    - "Has the textarea been cleared?"

- after_step: 5  # after streaming ends
  save_to: screenshots/TC-001-completed.png
  llm_judges:
    - "Does the assistant bubble display the complete reply content (no truncation)?"
    - "Is the send button restored to 'Send' text and clickable state?"
    - "Is the overall bubble layout normal with no text overflow?"
```

**Preconditions**

- Browser on `/chat` page, textarea is empty
- LLM mock configured to return fixed reply: "Bacterial pneumonia is a lung infection caused by bacteria..." (complete 200-character reply)

**Setup actions**

1. Call `POST /test/reset-messages` (clear messages table)
2. Call `POST /test/configure-llm-mock?response=fixture://pneumonia-answer.txt`
3. Browser navigate to `/chat`

**Steps**

1. Browser input in textarea "What is bacterial pneumonia?"
2. Click send button
3. Wait for SSE start event (URL monitor `/api/chat/stream`)
4. **Screenshot point 1**: during streaming (approximately 200ms after start event)
5. Wait for SSE done event (max 30 seconds) — **Screenshot point 2**: after streaming ends

**Expected**

- textarea is cleared
- assistant bubble displays complete reply "Bacterial pneumonia is a lung infection caused by bacteria..."
- SQL: `SELECT count(*) FROM messages WHERE session_id=current` = 2 (one user + one assistant)
- SQL: user message content = "What is bacterial pneumonia?", assistant message content = complete reply from mock configuration
- Screenshot judgment results per Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

**Invariant checks (auto-applied)**: INV-C1, INV-C2, INV-S1, INV-S2

---

### TC-002: Send Markdown message, front-end renders correctly

- **Path type**: Main path
- **References**: B2, INV-S1, INV-X1
- **Method applied**: Scenario pattern "Front-end rendering fidelity" direct test
- **Destructive**: yes
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport target**: desktop 1280x800

<!--
This TC is a **typical representative of a Codex tool combination** ——
Backend must verify stored string is raw Markdown (data);
Front-end must verify Markdown truly renders as bold / heading / list (visual).
Pure Playwright checking for <strong> elements can verify "did it render", but cannot capture "is the font actually bold" — must use LLM to view screenshot.
-->

**Screenshot points**

```yaml
- after_step: 5  # streaming ends, complete rendering
  save_to: screenshots/TC-002-markdown.png
  llm_judges:
    - "Is **emphasis point 1** in the user bubble truly rendered as bold (font visibly bolder than body text)?"
    - "Is the # large heading in the user bubble rendered as large heading (font size noticeably larger than body, no # character visible)?"
    - "Are list items 1. and 2. rendered as ordered list (with numbers + indentation)?"
    - "Is the overall bubble layout normal with reasonable spacing between Markdown elements?"
```

**Preconditions**: Same as TC-001

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?response="Received your list"` (simple reply, this TC focuses on user input rendering)
3. Browser navigate to `/chat`

**Steps**

1. In textarea input:
   ```
   Please answer with a list:
   1. **emphasis point 1**
   2. # large heading
   ```
2. Click send button
3. Wait for streaming to end
4. **Screenshot point**: compare and judge rendering results

**Expected**

- SQL: user message content **stored as-is** as Markdown string (including `**` `#` `1.` `2.` and other literal characters) ——
  this is a key assertion of INV-S1, backend performs no escaping
- Front-end DOM: user bubble contains `<strong>` element `<h1>` element `<ol><li>` list
- Screenshot judgment: per Screenshot points (LLM visual confirmation of rendering fidelity)

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`

---

### TC-003: Streaming response error mid-stream, display error message

- **Path type**: Exception path
- **References**: B4
- **Method applied**: State Transition - streaming → error
- **Destructive**: yes
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script
- **Viewport target**: desktop 1280x800

<!--
- Data dimension: verify SSE error event backend recording, message status becomes error (SQL)
- Visual dimension: error message styling (red), button restore styling (LLM view screenshot)
→ Browser Use / Screenshot Review / Playwright combination
-->

**Screenshot points**

```yaml
- after_step: 5  # page state after streaming interruption
  save_to: screenshots/TC-003-error.png
  llm_judges:
    - "Does the page display red or warning-colored error message text 'Connection interrupted, please retry'?"
    - "Is the partially received assistant content still visible (not disappeared)?"
    - "Is the send button restored to 'Send' state and clickable?"
```

**Preconditions**: Same as TC-001

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?mode=error_after_2_chunks`
   (mock configuration: after sending 2 deltas, return error event)
3. Browser navigate to `/chat`

**Steps**

1. In textarea input "Test this"
2. Click send
3. Wait for 2nd delta event
4. mock returns error event (triggered automatically, no Operator action needed)
5. **Screenshot point**: after error message appears

**Expected**

- Error message "Connection interrupted, please retry" is visible
- Partially received assistant content (2 chunks) remains visible
- Send button restores to "Send" text, clickable again
- SQL: assistant message status = 'error'
- Screenshot judgment results per Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

---

### TC-004: Empty message send rejected (pure front-end validation)

- **Path type**: Exception path
- **References**: B5
- **Method applied**: Boundary Value - length=0
- **Destructive**: no
- **Codex-tool-plan**: Browser Use + Screenshot Review
- **Viewport target**: desktop 1280x800

<!--
- Test points are purely visual/interactive layer (send button disabled, placeholder hint), no backend data transmission
- No need for Playwright, Browser Use + Screenshot Review is more intuitive
-->

**Screenshot points**

```yaml
- after_step: 1  # after entering /chat page
  save_to: screenshots/TC-004-empty-textarea.png
  llm_judges:
    - "Does textarea display placeholder hint text (light gray)?"
    - "Is the send button in disabled gray state?"

- after_step: 2  # after typing spaces
  save_to: screenshots/TC-004-whitespace.png
  llm_judges:
    - "Is textarea still recognized as 'empty'? (send button still disabled)"
    - "If user continues typing spaces, does the button remain disabled?"
```

**Preconditions**: Browser on `/chat`, textarea is empty

**Setup actions**

1. Browser navigate to `/chat` (no message sent)

**Steps**

1. Observe initial textarea state (empty + display placeholder + button disabled)
2. In textarea input "   " (3 spaces) — verify button still disabled (after trim, it's empty)
3. Try clicking send button — **because it's disabled, should have no effect** (not "rejected by front-end validation")

**Expected**

- Step 1: screenshot judgment shows textarea displays placeholder, button disabled
- Step 2: screenshot judgment shows button still disabled (spaces after trim are empty, per B5 logic)
- Step 3: click has **no effect at all** ——
  - No network request sent (Developer Tools Network panel shows no new request, can be judged by LLM screenshot or Playwright interception)
  - No UI change (no loading state, no error message, no new bubble)
- SQL: messages table has no new records

**Note**: This TC tests "button disabled + click has no effect", not "button clickable + front-end rejection" ——
both prevent empty message send, but **user experience differs**, spec B5 strictly chooses the former (see the "logic basis" explanation at the end of spec B5).

**Teardown actions**

1. None (this TC has not destroyed any state)

---

### TC-005: XSS injection test (render layer sanitize verification)

- **Path type**: Invariant verification
- **References**: INV-S1, INV-C3
- **Method applied**: Security test — injection attack vector
- **Destructive**: yes (adds new messages records with malicious strings)
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script + API/Security Supplemental
- **Viewport target**: desktop 1280x800

<!--
- Data dimension: verify INV-S1 backend stores `<script>` string as-is (SQL query content)
- Visual dimension: verify INV-C3 render layer sanitize, page **displays as literal string** and alert **does not pop** (LLM screenshot + monitor dialog event)

This is a standard example of Codex tool combination capturing "DOM passes ≠ visual passes" and "storage vs rendering layered defense".
-->

**Screenshot points**

```yaml
- after_step: 4  # streaming ends, message rendered
  save_to: screenshots/TC-005-xss-rendered.png
  llm_judges:
    - "In the user bubble, is `<script>alert(1)</script>` displayed as **literal string** (i.e., you can see `<` `>` characters, not parsed as HTML tag and disappear)?"
    - "Are there **no** alert dialog boxes popped up on the page? (should be none)"
    - "If user bubble does not show `<script>` characters, it means HTML tag was parsed — this is a visual signal of XSS vulnerability"
```

**Preconditions**

- Browser on `/chat`, no ongoing streams
- LLM mock returns normal reply (this TC focuses on **user input rendering**, not testing LLM output)

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?response="Received"`
3. Browser navigate to `/chat`
4. **Playwright monitor `dialog` event** ——any alert/confirm/prompt popup should be captured (`page.on('dialog', ...)`)

**Steps**

1. In textarea input malicious string: `<script>alert(1)</script>` followed by `<img src=x onerror=alert(2)>`
2. Click send button
3. Wait for SSE stream to end (LLM reply "Received" is also streaming)
4. **Screenshot point**: after message rendering completes

**Expected**

- **Backend assertion (INV-S1)**:
  - SQL: `SELECT content FROM messages WHERE role='user' ORDER BY id DESC LIMIT 1`
  - Return string **exactly equal to** input (include `<script>` `<img>` and other raw characters, no escaping, no replacement)
- **Front-end DOM assertion (INV-C3 first layer)**:
  - User bubble DOM should **not** contain `<script>` element (markdown-it treats as literal text)
  - User bubble DOM should **not** contain `<img onerror>` element (markdown-it treats as literal text)
  - User bubble's textContent contains `<script>alert(1)</script>` string (shows it was rendered as literal)
- **Runtime assertion (INV-C3 second layer — critical)**:
  - **Playwright dialog event listener** should **not be triggered** (no alert/confirm/prompt popup during entire TC)
  - Browser console has **no** `alert` call record
- **Visual judgment**: per Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

**Expected result explanation**

- If **all PASSED**: storage and rendering layered defense both effective, XSS unreachable
- If **SQL passes but DOM contains `<script>` element**: INV-S1 OK, **INV-C3 fails** — markdown-it did not disable HTML mode,
  this is a real XSS vulnerability, can be exploited in production
- If **dialog event is triggered**: already XSS attacked, severe P0 security bug

---

## Boundary Value Coverage

| Field | Boundary value | Corresponding TC | Remarks |
|----|------|------|----|
| message.length = 0 | Empty string | TC-004 | Should be rejected |
| message.length contains only spaces | "   " | TC-004 | Equivalent to empty |
| message.length = 1 | Single character | (merged into TC-001) | Simplified |
| message.length = 4000 | Near upper limit | (not listed) | Simplified |

### Skipped boundaries

- `message.length = 4001` (exceeded length rejected): not tested separately, merged into "input validation"
- Reason: This spec focuses on dialogue core, extreme lengths tested separately by backend validation component

## Decision Table Coverage

| Input valid | Network normal | LLM available | behavior | Corresponding TC |
|--------|--------|--------|--------|------|
| ✅ | ✅ | ✅ | B1/B2 | TC-001, TC-002 |
| ❌ (empty) | * | * | B5 | TC-004 |
| ✅ | ❌ | * | B4 | TC-003 (simulated via mock) |

## Inspector Feedback Log

(This example assumes Inspector gave 0 P0 items, 2 P1 items. Specific feedback content simplified and omitted.)

## Out of Scope (from Spec)

### Business boundary (copied from spec §3.4a)

- History session switching
- User login and permissions
- Clinical/factual correctness of LLM responses

### Engineering boundary (copied from spec §3.4b)

- Streaming render character-by-character typewriter visual effect
- Real network interruption simulation (use mock instead)
