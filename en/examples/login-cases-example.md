# Test Cases: User Login

> This is a test case example corresponding to `login-spec-example.md`.
> Showcases key fields of test case document: Resource Dependency Matrix / Scenario Pattern Coverage Self-Check /
> Codex-tool-plan / viewport evidence / Screenshot points / Destructive.
> For simplicity, only 5 representative TCs are shown; real situations would have 10+.

## Quick Feature Test Usage

If the request is only "verify the login button submits" or "check the error message appears", Coordinator can choose Quick Feature Test:

- Browser Use opens `/login` and records the actual viewport.
- Run one success or failure login path.
- Collect screenshot, console/dialog summary, and compact failure classification.
- Do not force full spec / Inspector documents.

The rest of this file shows the Full Flow Test form.

## Coverage Summary

| Path type | Number of test cases | Covered behavior |
|---------|------|----------------|
| Main path | 1 | B1 |
| Alternative path | 0 | — |
| Exception path | 3 | B2, B3, B4 |
| Invariant verification | 1 | INV-X1, INV-S1 |

## Resource Dependency Matrix

| Shared resource | Destructive test case | Dependent test case | Has teardown recovery | Remarks |
|---------|---------|--------|------------------|----|
| user_test (alice@example.com) | TC-004 (state becomes locked) | TC-001, TC-002, TC-003 | ✓ TC-004 teardown resets locked_until=NULL | Closed loop |
| sessions table | TC-001 (new session) | TC-005 (verify INV) | ✓ TC-001 teardown deletes that session | Closed loop |
| rate_limit counter | TC-002, TC-003 (failed count +1) | TC-004 (reaches 5 times lock) | ⚠ Count accumulation is expected behavior (intentional accumulation across TCs) | TC sequence 002→003→004 must be strict |

Matrix shows **intentional cumulative dependency** between TC-002 / TC-003 / TC-004 ——
to test rate limiting, need failures accumulated to 5. This "intentional dependency" should be clearly explained in test case document notes, does not count as circular dependency.

## Scenario Pattern Coverage Self-Check

### Pattern 1: Form input type (marked in spec §4)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Required field empty | ✓ | TC-empty field (not listed, simplified) |
| Equivalence class (valid input representative) | ✓ | TC-001 |
| Equivalence class (invalid input representative: email format error) | ⚠ | Tool capability — front-end HTML5 type=email validation blocks submission, backend never receives invalid email |
| Boundary value (password length 8 / 64) | ⚠ | Not tested this period — see §3.4b engineering boundary (password strength real-time feedback) |
| XSS injection test (`<script>` input) | ✗ | Not listed in spec §3.4a; but INV-S2 indirectly covers (response does not expose internal errors) |
| Form disabled state visual toggle | ✓ | TC-004 (after account locked, button turns gray, requires Browser Use + Screenshot Review) |

### Pattern 2: User authentication / session management (marked in spec §4)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| session cookie exists after normal login | ✓ | TC-001 |
| Cookie security flags (HttpOnly + Secure) | ✓ | TC-001 (INV-C3 verification) |
| Wrong password does not create session | ✓ | TC-002 |
| Rate limiting (lock after N failures) | ✓ | TC-004 |
| Email enumeration attack protection (response indistinguishable) | ✓ | TC-005 (test INV-X1) |
| Logout clears session | OOS | Outside spec §3.4a scope (this spec only tests login, not logout) |

### Pattern 3: Front-end rendering fidelity (marked in spec §4)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Error message text rendering | ✓ | TC-002, TC-003 (LLM screenshot judges error message style) |
| Button disabled visual toggle | ✓ | TC-004 (LLM screenshot judges button turns gray) |
| Input placeholder text | ⚠ | Not related to core login functionality, not tested separately |
| Third-party login buttons (Apple / Google) | OOS | Spec §3.4a business boundary (no SSO this period) |

### Pattern 4: Exception paths (general) (marked in spec §4)

| Self-check item | Status | Corresponding TC / Reason |
|---------|----|----|
| Network disconnect message | ⚠ | Tool capability — this period tool not convenient for network interruption simulation; consider Playwright offline mode |
| Server 5xx error | ⚠ | Same as above, requires mock |
| Rate limit (429) response handling | ✓ | TC-004 |

## Codex Execution Contract

- **Default viewport**: desktop 1280x800. If a Codex small-window screenshot is used for auxiliary observation, report it as `small-codex-viewport evidence` and do not use it as direct desktop layout-failure evidence.
- **Browser Use**: default for login form interaction, error message observation, and disabled button state.
- **Playwright Script**: stable reruns and data assertions for successful login, cookies, sessions, and rate-limit counters.
- **Browser Use + Screenshot Review**: error style, disabled button visual state, form layout.
- **Computer Use**: not needed in this example unless native file picker, download folder, or desktop popup appears.
- **Supabase Verify**: auxiliary sessions / rate_limit server_state verify only if the project uses Supabase.
- **API/Security Supplemental**: email enumeration and illegal-state security supplements; never replaces normal login UI trigger.

## Test Cases

### TC-001: Registered user logs in with correct password successfully

- **Path type**: Main path
- **References**: B1, INV-C1, INV-C3
- **Method applied**: Equivalence Partitioning - valid input representative
- **Destructive**: yes
- **Codex-tool-plan**: Playwright Script + Supabase Verify
- **Viewport target**: desktop 1280x800

<!-- Main path mainly asserts URL / cookie / SQL data correctness → Playwright Script, with Supabase Verify only for server_state when applicable -->

**Preconditions**

- Client state: no session cookie, URL is `/login`
- Server state: alice@example.com exists, password hash matches Test1234!

**Setup actions**

1. Call `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. Browser clear cookies + localStorage, navigate to `/login`

**Steps**

1. Browser input `alice@example.com` in email field
2. Input `Test1234!` in password field
3. Click "Login" button

**Expected**

- Final URL matches `/dashboard`
- Page displays "Welcome, Alice"
- SQL: `SELECT count(*) FROM sessions WHERE user_email='alice@example.com'` = 1
- **Cookie verification** (via Playwright `context.cookies()`):
  - cookie name `session_token` exists
  - `cookie.httpOnly === true` (HttpOnly flag effective)
  - `cookie.secure === true` (Secure flag effective)
  - **do not use** `document.cookie` verification — HttpOnly cookie cannot be read in JS anyway (see INV-C3 notes)

**Teardown actions**

1. SQL: `DELETE FROM sessions WHERE user_email='alice@example.com'`
2. Reset this user's last_login_at (avoid polluting next TC)

**Invariant checks (auto-applied)**: INV-C1, INV-C2, INV-C3, INV-S1, INV-S3

---

### TC-002: Registered user logs in with wrong password, sees error message

- **Path type**: Exception path
- **References**: B2, INV-X1
- **Method applied**: Equivalence Partitioning - wrong password representative
- **Destructive**: yes (failed counter +1)
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport target**: desktop 1280x800

<!-- Verify backend "sessions not increased" (data) and front-end "error message style" (visual) → Browser Use / Screenshot Review / Playwright combination -->

**Screenshot points**

```yaml
- after_step: 3  # after clicking login button, error message appears
  save_to: screenshots/TC-002-error-message.png
  llm_judges:
    - "Does page display clear error message text 'Invalid email or password'?"
    - "Does error message use red or warning color, distinct from body text?"
    - "Is login form still visible, is password field cleared?"
```

**Preconditions**

- Server state: alice@example.com exists, failed count < 4

**Setup actions**

1. `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. `POST /test/reset-rate-limit?email=alice@example.com`
3. Browser clear cookies, navigate to `/login`

**Steps**

1. Input `alice@example.com` in email field
2. Input `WrongPassword` in password field
3. Click "Login" button

**Expected**

- URL still `/login` (not redirected)
- no session cookie
- page displays "Invalid email or password"
- SQL: `SELECT count(*) FROM sessions WHERE user_email='alice@example.com'` = 0
- API: `GET /test/rate-limit?email=alice@example.com` returns `{ failed_count: 1 }`
- screenshot judgment per Screenshot points

**Teardown actions**

1. `POST /test/reset-rate-limit?email=alice@example.com` (clear failed count)

---

### TC-003: Unregistered email login, response indistinguishable from TC-002

- **Path type**: Invariant verification
- **References**: B3, INV-X1
- **Method applied**: Test equivalent behavior invariant
- **Destructive**: yes (failed counter +1)
- **Codex-tool-plan**: Playwright Script + API/Security Supplemental
- **Viewport target**: desktop 1280x800

<!-- Pure data assertion: verify response_status / body / time same as TC-002 → Playwright + API/Security Supplemental -->

**Preconditions**

- Server state: ghost@example.com **does not exist**

**Setup actions**

1. `POST /test/ensure-user-not-exists?email=ghost@example.com`
2. Browser clear cookies, navigate to `/login`

**Steps**

1. Input `ghost@example.com` in email field
2. Input `AnyPassword` in password field
3. Click "Login" button, **record response time**

**Expected**

- URL still `/login`
- page displays "Invalid email or password" (exactly same text as TC-002)
- API: `POST /api/auth/login` response status = 401 (same as TC-002)
- API: response body = `{"error": "Invalid credentials"}` (same as TC-002)
- **response time vs TC-002 difference < 100ms** (prevent timing attack)
- SQL: application log contains `ghost@example.com` attempt record (level=info)

**Teardown actions**

1. None (user doesn't exist anyway, no recovery needed)

---

### TC-004: After 5 failures, account locked, button turns gray

- **Path type**: Exception path
- **References**: B4
- **Method applied**: Boundary Value Analysis - boundary 5
- **Destructive**: yes (user state becomes locked)
- **Codex-tool-plan**: Browser Use + Screenshot Review + Playwright Script
- **Viewport target**: desktop 1280x800

<!-- Verify backend locked_until field (data) and button visual disabled state (rendering) → Playwright + Screenshot Review -->

**Screenshot points**

```yaml
- after_step: 4  # after 5th failure response arrives, lock state displays
  save_to: screenshots/TC-004-locked.png
  llm_judges:
    - "Does page display 'Account locked, please try again after 15 minutes'?"
    - "Is login button turned gray disabled state (visually noticeably lighter than normal state)?"
    - "When hovering over button, is it still not clickable? (expected not clickable)"
```

**Preconditions**

- failed counter = 4 (already failed 4 times, one more failure triggers lock — see spec B4 revised edition)

**Setup actions**

1. `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. `POST /test/set-rate-limit?email=alice@example.com&failed_count=4`
3. Browser clear cookies, navigate to `/login`

**Steps**

1. Input `alice@example.com` in email field
2. Input `WrongPassword` in password field
3. Click "Login" button (this is the user's 5th failure — 4 previous + this one)
4. Wait for response — this response should trigger lock (not "click one more time", this submission itself)

**Expected**

- page displays "Account locked, please try again after 15 minutes" (**not** "Invalid email or password")
- Login button `disabled` attribute is true
- API: `GET /test/user-status?email=alice@example.com` returns `{ locked_until: <future timestamp> }`,
  and `locked_until > now`
- API: `GET /test/rate-limit?email=alice@example.com` returns `{ failed_count: 5 }` (just reached threshold)
- screenshot judgment per Screenshot points

**Teardown actions**

1. SQL: `UPDATE users SET locked_until=NULL WHERE email='alice@example.com'`
2. `POST /test/reset-rate-limit?email=alice@example.com`

---

### TC-005: Verify email enumeration protection (INV-X1 cross-case comparison)

- **Path type**: Invariant verification
- **References**: INV-X1
- **Method applied**: Right-BICEP - Cross-check
- **Destructive**: no (only compare results of TC-002 and TC-003)
- **Codex-tool-plan**: Playwright Script + API/Security Supplemental
- **Viewport target**: desktop 1280x800

<!-- Cross-TC compare response consistency, pure data → Playwright + API/Security Supplemental -->

**Preconditions**

- TC-002 and TC-003 already run, have response data to compare

**Setup actions**

1. Load TC-002 response records (status / body / time)
2. Load TC-003 response records

**Steps**

1. Compare status of two responses: should be exactly equal
2. Compare response.body: should be exactly equal
3. Compare response_time: should differ < 100ms

**Expected**

- Two responses completely indistinguishable in status / body / time three dimensions
- This is core assertion of INV-X1

**Teardown actions**

1. None

---

## Boundary Value Coverage

| Field | Boundary value | Corresponding TC | Remarks |
|----|------|------|----|
| password.length = 0 | Empty string | (not listed, simplified) | Should be rejected by front-end |
| password.length = 8 | Minimum valid length | TC-001 indirectly covered | Test1234! length 9 |
| failed_count = 5 | Lock threshold | TC-004 | Key |

### Skipped boundaries

- `password.length = 65` and `1000`: not tested separately, merged into "password length limit" test (simplified)
- Reason: this spec focuses on "login core", password length boundary tested separately by password validation component

## Decision Table Coverage

Reference spec §3.2, 5-row decision table:

| User exists | Password correct | Already locked | Expected behavior | Corresponding TC |
|--------|--------|------|------------|------|
| ✅ | ✅ | ❌ | B1: login successful | TC-001 |
| ✅ | ❌ | ❌ | B2: wrong password message | TC-002 |
| ❌ | * | ❌ | B3: invalid email or password | TC-003 |
| ✅ | * | ✅ | B4: account locked | TC-004 |
| ❌ | * | ✅ | B4: account locked (defensive) | (not tested, theoretically impossible) |

## Inspector Feedback Log

(This example assumes Inspector Round 1 gave 0 P0 items, 3 P1 items, 1 P2 item.
In real usage, this section lists Inspector feedback and Cartographer handling. Simplified and omitted here.)

## Out of Scope (from Spec)

### Business boundary (copied from spec §3.4a)

- SMS two-factor authentication / SSO login / Remember me / email service reachability

### Engineering boundary (copied from spec §3.4b)

- Password strength real-time feedback visual change
