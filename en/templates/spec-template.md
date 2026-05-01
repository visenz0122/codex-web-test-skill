<!--
================================================================================
Specification Template

Fill instructions:
- This template is the target format for Cartographer to generate specs
- All <!-- comments --> are fill-in instructions for Cartographer; delete them when generating the final spec
- Chapter structure is fixed; do not add or merge chapters
- If a section has no content, write "(none)" instead of deleting the section
- Write the entire spec in Markdown, LLM-friendly and human-readable

Source annotation rules (mandatory for easily conflicting fields):
- Fields prone to "code vs documentation conflict" (test accounts, API paths, key copy, boundary values, etc.)
  must be annotated with Source in italics after the fact
- Format: fact  *(source: file:line-number)*
- If conflicts found between multiple sources for the same fact, use higher authority level, but explicitly declare
  the conflict in the spec, format: *(source: A;⚠ conflicts with B, A is authoritative)*
- See "Information Source Authority Level" principle in cartographer.md
================================================================================
-->

# Feature: <feature name>

<!--
Use short noun phrase for feature name, not action. Examples:
- Good: "Password Reset", "Shopping Cart Checkout", "User Login"
- Bad: "Implement user login capability", "Making a login feature"
-->

## 0. Codex Test Context

<!--
Record runtime assumptions before the behavioral spec so Operator can reproduce the environment.
-->

- **Test mode**: Quick Feature Test / Full Flow Test
- **Target URL**: <http://localhost:... or deployed URL>
- **Dev server command**: <e.g. npm run dev / already running / unknown>
- **Frontend entry**: <path or unknown>
- **Backend entry**: <path or unknown>
- **Test data source**: <seed script / fixture / Supabase / existing local DB / none>
- **Allowed test data actions**: <create test account / reset table / no writes / ask first>
- **Default viewport assumption**: <desktop 1280x800 / desktop 1440x900 / mobile / not layout-sensitive>
- **Codex tools expected**: <Browser Use / Playwright Script / Screenshot Review / Computer Use / Supabase Verify / API/Security Supplemental>

## 1. Interface

<!--
Interface is Layer 1: facts read statically from code.
This section content must be 100% verifiable, no LLM inference or guessing.
-->

### 1.1 Routes

<!--
List all frontend routes involved in this feature.
Format: `path` — brief description
Source annotation for paths: router file in code
-->

- `/path` — description  *(source: src/router.js:42)*
- `/path/:param?query=value` — description  *(source: src/router.js:67)*

### 1.2 API Endpoints

<!--
List all backend API endpoints involved in this feature.
Format: METHOD `path` — request and response summary
Do not write full schema (that's for developers), key fields are enough.
-->

- `POST /api/...` — request `{ field1, field2 }`, response `200 | 4xx`  *(source: src/api/auth.js:15)*

## 2. Constraints (MUST)

<!--
Constraints are the "MUST" parts of Layers 2+3.
Cartographer generates + human reviews + Inspector checks these parts — they are hard requirements.
-->

### 2.1 Behaviors

<!--
Each behavior is a complete, verifiable causal fragment.
- ID numbered sequentially as B1, B2, ...
- trigger written at "user intent level", not step level
- expected expresses final stable state with "eventually"
- preconditions split into client_state / server_state
- State classification principle:
  * client_state = state in browser (cookie / localStorage / URL)
  * server_state = state on server (database / cache / counters)
  * UI text is not client_state, goes in expected.ui_observable
-->

#### B1: <one-sentence description of this behavior>

**Preconditions**

- Client state:
  - <e.g. user not logged in, no session cookie>
- Server state:
  - <e.g. test account alice@example.com exists, password hash is known value>  *(source: migrations/seed.sql:12)*
  - <if conflict example>: test account admin / Test1234!  *(source: seed.sql:5;⚠ conflicts with README.md's admin/password123, SQL is authoritative)*

**Trigger**

- Intent: <user's high-level intent, e.g. "submit login form">
- With:
  - Text inputs: <e.g. `email=test@x.com, password=Test1234` (if no text input, write "(none)")>
  - File inputs: <optional, only fill when feature involves file upload, "(none)" if not>

<!--
File inputs field format (one file per row):

| Field name | File description | Purpose |
|---|---|---|
| avatar | Normal PNG image, ~500KB, 256x256 | Test basic upload success path |
| document | Damaged PDF (header correct but content corrupted) | Test damaged file handling |

Note:
- Only describe what file should be like, not actual path
- Actual file used is decided in Cartographer phase 2.5 by the user (provide path / manual upload / Agent generate)
- Decision result written in test case document, not in spec
-->

**Expected (eventually)**

- Client state after:
  - <e.g. cookie session_token exists>
  - <e.g. URL becomes /dashboard>
- Server state after:
  - <e.g. user_activity table has new login record>
  - Verifiable via: <e.g. test endpoint / DB query / log inspection>
- UI observable:
  - Visible text: <e.g. "Welcome, X">  *(source: locales/zh-CN.json:14)*
  - Visible elements: <e.g. logout button visible>
- Not observable:
  - <e.g. should not show "Login failed" text>

**Logical basis** (derivation basis of this behavior, see cartographer.md principle 8):

- <2-4 sentences describing code control flow. E.g.
  "loginHandler verifies password, then:
  1) inserts user_id in sessions table,
  2) sets Set-Cookie response header,
  3) returns redirect to /dashboard.
  All three steps in same transaction, any failure rolls back.">
- **Reachability**: <e.g. normal path has only one route, exception branches covered by B2/B3>
- **Conclusion correction** (if applicable): <e.g. found during logical basis writing that an expected field was wrong, explain and correct here>

#### B2: ...

<!-- Repeat above format -->

### 2.2 Invariants

<!--
Invariants are eternal constraints across behaviors, not tied to specific actions.
Three categories:
- Client-side: always true on browser side (e.g. password not in URL)
- Server-side: always true on server side (e.g. password not in logs)
- Cross-cutting: spans both sides (e.g. some behaviors indistinguishable to outside)

Each invariant must be verifiable; vague wording (e.g. "system should be secure") not allowed.
-->

#### Client-side invariants

- INV-C1: <e.g. at any time, password field value does not appear in URL>
  *(source: src/router.js:88)*
  - Applies to: B1, B2, ... (or "all")
  - **Logical basis**: <e.g. login form onSubmit uses POST body submit, never goes through URL parameters.
    Check all router.push calls use path not query-containing objects>
  - **Reachability**: <e.g. no fallback paths, all paths never put password in URL>

#### Server-side invariants

- INV-S1: <e.g. at any time, password field value does not appear in logs>
  *(source: src/middleware/logger.js:42)*
  - Applies to: all
  - Verifiable via: <e.g. grep application logs>
  - **Logical basis**: <e.g. logger middleware calls sanitize() before logging request body,
    sanitize removes values of fields: password, token, secret>
  - **Reachability**: <e.g. all logging paths go through this middleware, no bypass paths>

#### Cross-cutting invariants

<!--
Special use to express "equivalent behaviors" — certain behaviors indistinguishable externally.
This prevents Inspector from mistakenly reporting "intentional security design" as bug.
-->

- INV-X1: <e.g. B1 and B2 indistinguishable in response_status / response_body / ui_text dimensions>
  *(source: src/api/auth.js:30-50)*
  - Rationale: <e.g. prevent user email enumeration attack>
  - **Logical basis**: <e.g. auth.js returns status=401 + message="Invalid credentials"
    in both email-not-exists and password-wrong cases, timing kept consistent via dummy bcrypt call (timing attack prevention)>
  - **Reachability**: <e.g. both branches reachable, no fallback>

## 3. Hints (SHOULD)

<!--
Hints for Cartographer itself (when generating test cases later) and Inspector.
Not hard constraints, but Cartographer should use as much as possible; Inspector uses to check coverage.
-->

### 3.1 Boundary Values

<!--
Key boundary values, listed explicitly.
Don't list all possible boundaries (that's Inspector's job with methodology).
Only list fields with magic numbers or limits in code.
-->

- Field `<field>`: boundary values `[v1, v2, v3, v4]`, expected behavior <corresponds to which behavior>  *(source: src/validators.js:23)*
  - **Logical basis**: <e.g. validators.js has code `password.length >= 8 && password.length <= 32`,
    uses >= and <=, so 8 passes, 32 passes, 7 fails, 33 fails.
    Two-value method for boundaries [7, 8, 32, 33]>
  - **Reachability**: <e.g. both >= and <= executed, no fallback>

### 3.2 Decision Table

<!--
When multiple conditions combine affecting results, list decision table.
No need to exhaust all combinations, only list branches developer actually handles.
-->

| Condition 1 | Condition 2 | Condition 3 | Expected behavior |
|---|---|---|---|
| ✅ | ✅ | ✅ | B1 |
| ✅ | ❌ | ✅ | B3 |
| ❌ | - | - | B5 |

### 3.3 State Machine

<!--
Only applies to stateful processes (orders, approvals, token lifecycle).
Stateless features write "(none)".
-->

- States: [created, sent, used, expired]
- Transitions:
  - created → sent: triggered by B1
  - sent → used: triggered by B5
  - sent → expired: triggered by time passage
- **Logical basis**: <e.g. tokens table has status field (enum: created/sent/used/expired).
  Code in token-service.ts:
  - createToken inserts with status='created'
  - sendToken changes status from created to sent
  - useToken checks status='sent' and expire_at>now, changes to status='used'
  - cleanup task changes status='sent' and expire_at<now to expired>
- **Reachability**: <e.g. created→sent necessary path, sent has two mutually exclusive reachable exits (used/expired),
  no other states; no illegal transitions (code uses enum + state validation)>

### 3.4 Out of Scope

<!--
Out of Scope **must split into two categories** — prevents "hard to test, so skip" avoidance pattern.
Fundamental difference:
- Business boundary: truly not needed to test (product decision / third-party / not in scope)
- Engineering boundary: should test but cannot this phase (tool limitation / automation gap / assertion granularity)

Each item must give "classification basis + reason not to test + (engineering boundary also) known risk + alternative").
One-line cop-outs like "teaching prototype" or "complex to implement" not allowed — Inspector will ask for specifics.

In focused test mode, dependent features (login, register, etc.) go in 3.4a business boundary.
-->

#### 3.4a Out of Scope - Business Boundary (intentionally not tested, reasonable business rationale)

<!--
These items truly not needed to test — product decision / third-party component / out of scope / covered by independent team/spec.
Inspector will not object to content of these items.
-->

Each item format:

- <item name>
  - **Category**: business boundary
  - **Reason not to test**: <specific explanation why>

Examples:

- Internationalization (i18n)
  - **Category**: business boundary
  - **Reason not to test**: product supports Chinese UI only this phase, no i18n switching logic, code has no corresponding paths
- SMS verification code recovery
  - **Category**: business boundary
  - **Reason not to test**: not in this phase, product backlog in Q3
- DICOM rendering details
  - **Category**: business boundary
  - **Reason not to test**: third-party component OHIF / Cornerstone responsible, outside our code control
- User login (focused test mode only)
  - **Category**: business boundary
  - **Reason not to test**: covered by independent spec, this spec assumes login state established (see §3.5 Setup Strategy)

#### 3.4b Out of Scope - Engineering Boundary (should test but current phase cannot)

<!--
These items should test but cannot — acknowledge the gap.
Cartographer putting items here **must honestly admit it's a gap**, and propose "alternative" or "future remedy".
Inspector has intervention right on these: can raise P1 suggestion (like "suggest manual_upload flag"
or "suggest future standalone project", or "suggest add invariant to indirectly reduce risk").
Humans reviewing should focus on this section — every item listed is "known gap".
-->

Each item format:

- <item name>
  - **Category**: engineering boundary
  - **Reason not to test**: <specific explanation why cannot test this phase> (must be tool capability /
    automation limitation / assertion granularity issue, not "business doesn't need" — that's business boundary)
  - **Known risk**: <what production consequences if not tested>
  - **Alternative approach** (for now): <what currently reduces risk> (can write "(none)")
  - **Suggested remedy path** (optional): <how to fix in future — like manual review, independent specialist testing, different tool>

Examples:

- LLM response semantic correctness / hallucination detection
  - **Category**: engineering boundary
  - **Reason not to test**: asserting this requires medical expert review of each LLM output, impossible to automate in E2E;
    LLM-as-judge current availability insufficient
  - **Known risk**: hallucination may mislead users in production (give wrong diagnosis recommendation)
  - **Alternative approach**: reduced risk via INV-S3 (sensitive fields not in database) + system prompt disclaimers
  - **Suggested remedy path**: future LLM-as-judge automation + sampling human review

- SSE long connection stability project
  - **Category**: engineering boundary
  - **Reason not to test**: Browser Use cannot precisely simulate "network drops X seconds then recovers" complex timing scenarios
  - **Known risk**: users in network instability scenario may lose / hang streaming output / no error message
  - **Alternative approach**: basic exception path covered via TC-XX (simulate one complete disconnect)
  - **Suggested remedy path**: Playwright + offline mode standalone project

### 3.5 Setup Strategy

<!--
Only fill in "focused test mode". Full-flow test mode write "(none, start from blank state)".

Describe how Operator enters test starting point with minimal setup. Principle: simpler the better.
Choose prerequisite method by priority (see cartographer.md phase 1 key principle section 6):
1. setup endpoint
2. load saved browser state
3. user provides valid token
4. actually run login once (least recommended)

Each step must fail independently: prerequisite failure ≠ test failure.
When Operator hits prerequisite failure, must abort testing, mark "setup failure".
-->

- Before entering test starting point, Operator should:
  1. <e.g. call `POST /test/login-as?email=alice@example.com` to get session cookie>
  2. <e.g. confirm browser cookie session_token exists>
  3. <e.g. navigate to test target page `/chat`>
- When prerequisite fails: Operator aborts entire test, marks "setup failure" in report —
  this failure is not a bug in feature being tested

#### 3.5b Environment isolation and Mock requirements

<!--
For irreversible operations (send email, call external API, trigger webhook, modify external payment status, etc.),
cannot rely on teardown to recover — must use mock in test environment instead.

This section lists mocks needed for this test suite; Operator confirms mocks ready before test startup.
-->

- Must-mock external dependencies:
  - <e.g. email service (SendGrid / SES) → use local Mailhog instead, SMTP forward to localhost:1025>
  - <e.g. payment gateway (Stripe) → use Stripe test mode + test cards>
  - <e.g. third-party webhook → configure as `localhost:8080/webhook-receiver`>
- Shared test resources (avoid TC interference):
  - <e.g. each test user isolated independently (user_test_for_TC_001, user_test_for_TC_002, ...)>
  - <e.g. test schema separate, reset before each run (`DROP SCHEMA test; CREATE SCHEMA test;`)>
- Unavoidable irreversible operations (declare known defects):
  - See spec §3.4b engineering boundary

## 4. Scenario Patterns

<!--
Scenario patterns this feature matches (stackable, typically 2-4).
Complete pattern library in references/scenarios/ (each pattern separate file, index in scenarios/index.md).

Cartographer phase 1 end must fill — this field determines which mandatory checklists to apply in phase 2.
Human review should focus on: are these patterns accurate, any missed pattern matches?
-->

- Matching scenario patterns:
  - <e.g. dialog UI (because Behaviors contain input fields + history message rendering)>
  - <e.g. async/streaming output (because LLM reply is streaming)>
  - <e.g. LLM agent decision (because backend calls LLM for generation)>
  - <e.g. multi-tenant/permissions matrix (because has admin/user/guest three roles)>
  - <e.g. exception paths (universal)>
- Patterns not matching but easily mistaken (optional):
  - <e.g. not matching "state transition" — this chat feature has no explicit state machine>

## 5. Meta

<!--
Traceability information for human review and later follow-up.
-->

- Generated by: Cartographer
- Code commit: <git commit hash>
- Generated at: <ISO 8601 timestamp>
- Reviewed by human: <yes/no/pending>
