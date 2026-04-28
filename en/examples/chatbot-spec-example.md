# Feature: AI Chatbot Core Dialogue

> This is the **core example** of spec-driven-test skill — showcasing a lightweight chatbot spec,
> covering the most common scenario pattern combinations (conversational UI + asynchronous streaming + LLM agent decision-making + front-end rendering fidelity).
>
> Hypothetical product: a simplified AI assistant chatbot where users input questions, backend calls LLM,
> SSE streams back replies, front-end Markdown renders. **No login, no history sessions** — keeping it lightweight.

## 1. Interface

### 1.1 Routes

- `/chat` — chatbot dialogue home page

### 1.2 API Endpoints

- `POST /api/chat/stream` — request `{ message: string }`, response SSE stream
  - SSE event types: `start` / `delta` / `done` / `error`
  - delta event payload: `{ chunk: string }` —— accumulates into complete reply
- `GET /api/chat/messages?session_id=X` — query history messages of a session (for test verification)

## 2. Constraints (MUST)

### 2.1 Behaviors

#### B1: User sends plain message, receives complete streaming reply

**Preconditions**

- Client state: on `/chat` page, textarea is empty, **send button is disabled** (because textarea is empty)
- Server state: LLM service available

**Trigger**

- Intent: input message in textarea (button becomes enabled at this point) → click send (or press Enter)
- With: `message="What is bacterial pneumonia?"`

**Expected (eventually)**

- Client state after:
  - URL still `/chat`
  - textarea cleared, **send button back to disabled state** (because empty again after clearing)
- Server state after:
  - new user message record added to messages table (role=user, content=raw input)
  - new assistant reply record added (role=assistant, content=complete reply)
  - Verifiable via: `GET /api/chat/messages?session_id=X`
- UI observable:
  - user message bubble displays raw input "What is bacterial pneumonia?"
  - assistant bubble appears progressively (streaming), finally shows complete reply
  - during streaming, send button text changes to "Generating..." and becomes disabled
  - after streaming ends, send button restored (if textarea still empty, then disabled; if textarea has content, then enabled)

#### B2: User sends Markdown format message, front-end renders correctly

**Preconditions**: Same as B1

**Trigger**

- Intent: send message containing Markdown markers
- With: `message="Please answer with a list:\n1. **emphasis point 1**\n2. # large heading"`

**Expected (eventually)**

- In user message bubble: **emphasis point 1** renders as bold `<strong>` element; # large heading renders as `<h1>`
- list items render as `<ol>` / `<li>`
- backend stores **raw Markdown string** (not HTML)
  *(source: src/handlers/chat.js:42 — content field stores user input directly, no preprocessing)*

#### B3: assistant streaming reply contains Markdown, renders in real-time

**Preconditions**: Same as B1

**Trigger**

- Intent: send a question that would make LLM reply with Markdown
- With: `message="List 3 types of cold medicine"` (assuming LLM replies with list)

**Expected (eventually)**

- assistant bubble content appears progressively with SSE delta
- **after each delta arrives**, Markdown renders incrementally — not waiting for stream end to render all at once
  *(source: src/components/Bubble.vue:88 — markdown-it called in real-time in watch(content))*
- when streaming ends, all Markdown elements render correctly

#### B4: Network interruption displays error message, stream does not hang

**Preconditions**: Same as B1

**Trigger**

- Intent: send message, but SSE stream is interrupted mid-way (or backend returns error event)

**Expected (eventually)**

- assistant bubble displays partially received content
- red error message "Connection interrupted, please retry" appears below bubble
- send button restored to "Send" and clickable (not stuck at "Generating...")
- Server state: assistant message in messages table marked as `status=error` (does not affect subsequent TC)

#### B5: When textarea is empty, send button disabled does not respond

**Preconditions**: on `/chat` page, textarea is empty (or contains only whitespace), **send button disabled**

**Trigger**

- Intent: try clicking send button (because disabled, actually no response — this is what's being tested)
- With: textarea content is empty string / only spaces / only newlines

**Expected (eventually)**

- no API request initiated (no SSE connection, no network traffic)
- send button remains disabled visual state (gray / not clickable)
- textarea displays placeholder hint text
- messages table has no new records

**Logic basis** *(source: src/components/ChatInput.vue:25)*: button disabled attribute bound to
`computed(() => textarea.value.trim().length === 0)`. after trim is empty → disabled.
This means **frontend layer completely prevents submission**, backend will not receive empty message request.
**Note**: there is no "button clickable + backend rejection" alternative implementation — this spec strictly follows "frontend disabled" semantics.

### 2.2 Invariants

#### Client-side invariants

- **INV-C1**: textarea **prohibits resubmission during streaming response** (prevent race)
  - Applies to: B1, B2, B3
- **INV-C2**: **after streaming state is entered** (when any behavior triggers SSE start event),
  user message bubble and assistant bubble **must be visible simultaneously** — cannot show only one side
  - Applicable scope: all behaviors entering streaming state (B1 / B2 / B3 / B4 all covered,
    whether stream done normally or error interrupted)
  - **Logic basis**: src/components/ChatList.vue:35 — when sending, both user and assistant messages pushed to list simultaneously,
    assistant initial content is empty, delta events append. both records enter list at push time,
    subsequent states (streaming/completed/error) never remove either one alone
- **INV-C3**: **render layer must sanitize all content** — markdown-it must be configured `html: false`
  to disable HTML mode, or use equivalent sanitize like DOMPurify; **absolutely cannot** directly `v-html` / `innerHTML` inject raw content
  - Applies to: globally (any place rendering messages.content)
  - **Verifiable via**: injection test — send `<script>alert(1)</script>` and similar input, verify page **displays as literal string**
    and alert **not triggered** (use Playwright monitor dialog event to confirm no dialog box pops)
  - **Logic basis**: src/components/Bubble.vue:88 calls `markdownIt({ html: false }).render(props.content)`,
    `html: false` option makes markdown-it treat `<script>` and other HTML tags as literal text without parsing
  - **Reachability**: all content goes through this render path, no branching
  - **Relationship with INV-S1**: INV-S1 explicitly "storage does not escape" — this is intentional design decision (preserve raw string for export / API consumption),
    but **brings XSS risk must be closed by INV-C3 at render layer defense**. both invariants must be satisfied simultaneously,
    either alone insufficient for security: only S1 → storage clean but render leaks XSS; only C3 → render clean but attack string can be
    taken from other paths (API, export files) and cause XSS on undefended client

#### Server-side invariants

- **INV-S1**: any user input (including malicious HTML / script) **stored as-is in messages table**, no escaping
  - Applies to: globally
  - **Logic basis**: chat.js:42 directly INSERT content, no sanitize call
  - **Reachability**: no branching, all input goes through this path
  - **Companion defense**: storage without escaping brings XSS risk — must pair with **INV-C3** (render layer sanitize) for closed-loop defense
- **INV-S2**: assistant reply **cannot contain sensitive system prompt words** (e.g., LLM system prompt content)
  - Applies to: B1, B2, B3
  - **Logic basis**: src/services/llm.js:60 — system prompt in messages[0] when calling LLM, does not return to client with stream

#### Cross-cutting invariants

- **INV-X1**: Markdown elements rendered by front-end **must be derived from raw content string** —
  cannot add any "frontend-injected" content outside content
  - Applies to: B2, B3
  - **Logic basis**: Bubble.vue renders props.content with markdown-it, no other data source mixed in

## 3. Hints (SHOULD)

### 3.1 Boundary Values

- Field `message.length`:
  - 0: empty message, should be rejected (B5)
  - 1: minimum valid input
  - 4000: near common LLM context limit
  - 4001: exceeds limit, backend should reject and return error
- Field `message.encoding` (test input character types):
  - pure ASCII / CJK / emoji / zero-width characters / RTL text / mixed

### 3.2 Decision Table

| Input valid | Network normal | LLM service available | Expected behavior |
|--------|--------|------------|------------|
| ✅ | ✅ | ✅ | B1/B2/B3: normal streaming reply |
| ❌ (empty) | * | * | B5: button disabled, no request initiated |
| ✅ | ❌ (interrupted) | * | B4: stream terminates + UI recovers interactive (no checkpoint recovery) |
| ✅ | ✅ | ❌ (LLM 5xx) | similar to B4: error message + UI recovers interactive |

### 3.3 State Machine

applicable to "single conversation stream" lifecycle:

- States: [idle, streaming, completed, error]
- Transitions:
  - idle → streaming: triggered by B1/B2/B3 trigger
  - streaming → completed: received done event
  - streaming → error: received error event / network disconnected / timeout
  - completed → idle: user clears textarea to prepare next message
  - error → idle: user clicks retry or starts new message
- **Logic basis** *(source: src/composables/useChat.ts)*: status field driven by SSE event type,
  start → streaming, delta keeps state, done → completed, error → error

### 3.4 Out of Scope

#### 3.4a Business boundary (truly not needed to test)

- History session switching (outside this spec scope, session management is independent feature)
- User login and permissions (this spec does not involve)
- Clinical/factual correctness of LLM responses (owned by content review team, not E2E scope)

#### 3.4b Engineering boundary (should test but cannot this period)

- **Streaming character-by-character typewriter visual effect**
  - Reason not to test: tool capability — LLM viewing screenshot cannot precisely determine "whether characters appear one by one" (can only see final or one moment state)
  - Known risk: broken typewriter effect worsens user experience (becomes one-time flash), but does not affect functionality
  - Alternative: insert 1-2 screenshots during TC to judge "at mid-stream, indeed only partial content displayed"
  - Recommended remediation path: use Playwright to record video, human sample review

- **Real network interruption simulation**
  - Reason not to test: tool capability — Claude in Chrome not convenient for network interruption simulation
  - Known risk: B4 (network disconnect message) may behave inconsistently in production vs test
  - Alternative: use mock backend return error event instead of real network disconnect
  - Recommended remediation path: next period use Playwright's `route.abort()` for real testing

### 3.5 Setup Strategy

per "full process test mode" — this spec starts testing from blank state, each TC prepares data independently.

before entering test starting point, Operator should:

1. Browser navigate to `/chat` (no login state dependency)
2. Call `POST /test/reset-messages` (clear history messages of test user, avoid TC pollution)

#### 3.5b Environment isolation and Mock requirements

- External dependencies must mock:
  - **LLM service**: replace with mock LLM, return predictable replies
    - Configuration: in test environment set `LLM_PROVIDER=mock`, `mock_responses` point to fixture file
    - otherwise real LLM returns different content each time, assertions cannot be stable
- Shared test resource isolation:
  - messages table uses independent schema (`test_messages`), reset before each test round
- unavoidable irreversible operations: none (after LLM mock, all operations repeatable)

## 4. Scenario Patterns

- matching scenario patterns:
  - **Conversational UI** (textarea + history bubbles + send button)
  - **Asynchronous / Streaming output** (SSE delta events render progressively)
  - **LLM agent decision-making** (backend calls LLM to generate replies)
  - **Front-end rendering fidelity** (Markdown / emoji / long text truncation / error message styling all need Agent to view screenshots)
  - **State transitions** (idle → streaming → completed/error)
  - **Exception paths (general)** (B4 network interruption, B5 empty message)

- non-matching but easily misidentified patterns:
  - non-matching "user authentication / session management" — this chatbot has no login (simplified)
  - non-matching "CRUD list and detail" — single message does not constitute CRUD list
  - non-matching "file upload / download" — this chatbot does not support file attachment

## 5. Meta

- Generated by: Cartographer (example)
- Code commit: example-commit-hash
- Generated at: 2026-04-28T10:00:00Z
- Reviewed by human: yes
- Notes: this is a manually written example to demonstrate skill paradigm, showcasing **lightweight chatbot spec**.
  corresponding test case example see `chatbot-cases-example.md`, execution report example see `chatbot-execution-report-example.md`.
