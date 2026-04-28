# Feature: User Login

> This is an **example** showing what a spec designed per spec-driven-test skill paradigm looks like.
> Cartographer can reference this example structure when generating specs in phase 1.
> Note: this example assumes a fictional product, field values described are for demonstration only.

## 1. Interface

### 1.1 Routes

- `/login` — login page, unauthenticated access to other authenticated pages redirects here
- `/dashboard` — default page after login, requires authenticated access

### 1.2 API Endpoints

- `POST /api/auth/login` — request `{ email, password }`, response `200 | 401 | 429`
- `POST /api/auth/logout` — requires session cookie, response `200`
- `GET /api/auth/me` — probe endpoint, requires session cookie, response `200 { user_id, email } | 401`

## 2. Constraints (MUST)

### 2.1 Behaviors

#### B1: Registered user logs in with correct password successfully

**Preconditions**

- Client state:
  - no session cookie
  - current URL is `/login`
- Server state:
  - database users table contains user with email=`alice@example.com`, password hash matches `Test1234!`
  - that user status=`active`
  - rate limit counter: that email has failed logins < 5 in the past hour

**Trigger**

- Intent: submit login form
- With: `email=alice@example.com, password=Test1234!`

**Expected (eventually)**

- Client state after:
  - URL matches `/dashboard`
  - cookie `session_token` exists, HttpOnly=true, Secure=true
- Server state after:
  - database sessions table has new record for that user_id
  - that user's last_login_at field updated to current time
  - Verifiable via: `GET /api/auth/me` returns 200 + that user info
- UI observable:
  - Visible text: "Welcome, Alice"
  - Visible elements: logout button, user menu
- Not observable:
  - text "Login failed" / "Invalid credentials" / "Error" should not appear

#### B2: Registered user logs in with wrong password fails

**Preconditions**

- Client state:
  - no session cookie
  - current URL is `/login`
- Server state:
  - users table contains user with email=`alice@example.com`
  - rate limit counter: that email has failed logins < 5 in the past hour

**Trigger**

- Intent: submit login form
- With: `email=alice@example.com, password=WrongPassword`

**Expected (eventually)**

- Client state after:
  - URL still `/login` (not redirected)
  - no session cookie
- Server state after:
  - sessions table has no new record
  - failed login count for that email +1
  - Verifiable via: internal API `GET /test/rate-limit?email=alice@example.com` (test endpoint)
- UI observable:
  - Visible text: "Invalid email or password"
  - Visible elements: login form still visible
- Not observable:
  - should not distinguish between "email does not exist" and "password wrong" (see INV-X1)

#### B3: Unregistered email login, response identical to B2

**Preconditions**

- Client state:
  - no session cookie
- Server state:
  - users table **does not contain** user with email=`ghost@example.com`

**Trigger**

- Intent: submit login form
- With: `email=ghost@example.com, password=AnyPassword`

**Expected (eventually)**

- Client state after:
  - URL still `/login`
  - no session cookie
- Server state after:
  - sessions table has no new record
  - application log records that attempt (level=info)
  - Verifiable via: application log grep `ghost@example.com`
- UI observable:
  - Visible text: "Invalid email or password" (exactly same as B2)

#### B4: After 5 failures, that submission itself triggers account lock for 15 minutes

**Preconditions**

- Client state:
  - no session cookie
- Server state:
  - users table contains user with email=`alice@example.com`
  - rate limit counter: that email **already failed 4 times** (one more failure reaches threshold)

**Trigger**

- Intent: 5th submission of wrong password login (whether password right or wrong, triggers lock; to trigger, submit wrong password)
- With: `email=alice@example.com, password=WrongPassword`

**Expected (eventually)**

- Client state after:
  - URL still `/login`
- Server state after:
  - sessions table has no new record
  - **that submission itself triggers lock**: that email's `locked_until=now+15min` written to users table
  - failed count final value is 5
  - Verifiable via: `GET /test/user-status?email=alice@example.com` should return `{ locked_until: <future timestamp> }`
- UI observable:
  - Visible text: "Account locked, please try again after 15 minutes" (note: **not** "Invalid email or password")
  - login button turns gray and disabled
- **Logic basis** *(source: src/api/auth.js:55-72, src/services/rate-limit.js:20)*:
  rate-limit.js `recordFailure(email)` function **immediately judges after incrementing**:
  `if (newCount >= 5) { setLockedUntil(email, now+15min); }`.
  So it's "5th failure itself triggers lock", not "6th attempt rejected".
- **Reachability**: when failed count = 4, one more submission, regardless of password right or wrong (lock does not distinguish),
  goes through "increment to 5, then immediately lock" path

#### B5: After login, access /dashboard

**Preconditions**

- Client state:
  - cookie `session_token` valid (corresponding to alice@example.com)
- Server state:
  - sessions table contains that token

**Trigger**

- Intent: visit `/dashboard`

**Expected (eventually)**

- Client state after:
  - URL still `/dashboard` (no redirect)
- UI observable:
  - Visible text: "Welcome, Alice"
- Not observable:
  - should not redirect to `/login`

#### B6: Unauthenticated access to /dashboard redirects to login page

**Preconditions**

- Client state:
  - no session cookie

**Trigger**

- Intent: visit `/dashboard`

**Expected (eventually)**

- Client state after:
  - URL redirects to `/login?redirect=/dashboard`
- UI observable:
  - Visible text: login form visible

### 2.2 Invariants

#### Client-side invariants

- **INV-C1**: at any time, password field value does not appear in URL (query or path)
  - Applies to: all
- **INV-C2**: at any time, password field value does not appear in localStorage / sessionStorage
  - Applies to: all
- **INV-C3**: session cookie must have HttpOnly and Secure flags set
  - Applies to: B1
  - **Verifiable via**: use Playwright's `context.cookies()` or CDP's `Network.getCookies` to read cookie metadata,
    check returned object's `httpOnly` and `secure` fields are true.
  - **❌ do not use** `document.cookie` (browser JS API) verification — HttpOnly cookie by definition cannot be read by JS,
    using JS verification can only confirm "cannot read", but **cannot distinguish** "HttpOnly effective" from "cookie not set at all".
  - **Operator-mode hint**: this invariant almost requires Operator-mode B or C (needs Playwright cookies API access);
    pure mode A (LLM browser) not convenient for verification, can mark ⚠ in scenario pattern self-check + tool capability reason

#### Server-side invariants

- **INV-S1**: application log should never contain password plaintext at any time
  - Applies to: all
  - Verifiable via: monitor application log during testing, grep password string
- **INV-S2**: any login failure response should not expose internal error details (stack trace, SQL errors, etc.)
  - Applies to: B2, B3, B4
- **INV-S3**: database users table password field must be bcrypt hash, never plaintext
  - Applies to: globally
  - Verifiable via: `GET /test/users-schema` (test endpoint, returns field types only, not values)

#### Cross-cutting invariants

- **INV-X1**: B2 (wrong password) and B3 (user doesn't exist) **completely indistinguishable in**:
  - response_status (both same status)
  - response_body (both same message)
  - ui_text (both "Invalid email or password")
  - response_time (difference < 100ms, prevent timing attack)
  - **Constraint scope**: this indistinguishability constraint **only applies to client-observable dimensions** ——
    server-internal logs, monitoring metrics, internal audit records etc. **out of scope** (B3 "application log records that attempt" is legal server observation,
    does not violate INV-X1). Attackers cannot access this internal data, so log differences do not constitute email enumeration vulnerability.
  - **Rationale**: prevent email enumeration attack — attackers should not determine if email is registered from response
  *(source: src/api/auth.js:30-78)*
  - **Logic basis**: auth.js login handler, when user not found, calls dummy bcrypt.compare() to maintain consistent timing,
    then shares same returnUnauthorized() function with wrong password case returning
    `{ status: 401, message: "Invalid credentials" }`. two branches converge to same return point,
    response body completely identical.
  - **Reachability**: both branches reachable — attackers can trigger different branches by submitting different emails,
    but two branches' **external outputs** indistinguishable, which is what this invariant guarantees

## 3. Hints (SHOULD)

### 3.1 Boundary Values

- Field `password.length`: boundary values `[0, 1, 7, 8, 9, 63, 64, 65, 1000]`
  *(source: src/validators/password.js:12)*
  - 0 (empty): should be rejected, prompt password cannot be empty
  - 1, 7: below minimum length 8, should be rejected
  - 8, 9, 63, 64: in valid range 8-64, should pass (assume password itself is correct)
  - 65: exceeds maximum length, should be rejected
  - 1000: prevent DOS, should be rejected without server exception
  - **Logic basis**: code in validators/password.js:
    ```
    if (!password || password.length === 0) return 'EMPTY';
    if (password.length < 8) return 'TOO_SHORT';
    if (password.length > 64) return 'TOO_LONG';
    return 'OK';
    ```
    so 8 passes (`< 8` not true), 64 passes (`> 64` not true), 7 rejected, 65 rejected.
    1000 also goes through `> 64` branch rejected, listed separately to test DOS protection.
  - **Reachability**: all 4 branches reachable; no fallback (explicit `return 'OK'`)
- Field `rate_limit.failed_attempts_per_email`: boundary values `[4, 5, 6]`
  - 4: can still login, corresponds to B2
  - 5: just reached lock threshold, corresponds to B4
  - 6: already locked state, try again, still locked

### 3.2 Decision Table

| User exists | Password correct | Already locked | Expected behavior |
|--------|--------|------|------------|
| ✅ | ✅ | ❌ | B1: login successful |
| ✅ | ❌ | ❌ | B2: wrong password message |
| ❌ | * | ❌ | B3: invalid email or password (same as B2) |
| ✅ | * | ✅ | B4: account locked message |
| ❌ | * | ✅ | **unreachable** — see explanation below |

**Unreachable row explanation** (❌ user doesn't exist + ✅ already locked):

- **Logic basis**: locked state (`locked_until` field) **written on users table record** ——
  without user record, there is no object to lock. code-level `recordFailure(email)` goes through dummy path when user doesn't exist (see INV-X1), never enters `setLockedUntil` call.
- **Test impact**: **do not write test case for this row** — it's impossible at data model level,
  writing it would require "first create user, lock, then delete user" awkward setup, waste effort.
- **not "defensive"**: this row is not "code might have bug entering this state, so test it as fallback" ——
  data model itself excludes this state, testing it has no meaning.

### 3.3 State Machine

applicable to session lifecycle:

- States: [none, active, expired, revoked]
- Transitions:
  - none → active: triggered by B1 (successful login)
  - active → none: triggered by logout
  - active → expired: triggered by time passing (default 24h)
  - active → revoked: triggered by password change or admin forced logout
- **Logic basis** *(source: src/services/session.js)*: sessions table state expressed implicitly by expires_at field
  and revoked_at field:
  - none = no token record in database
  - active = record exists & expires_at > now & revoked_at IS NULL
  - expired = record exists & expires_at <= now
  - revoked = record exists & revoked_at IS NOT NULL
  
  code session.js calculates state per above conditions in middleware for each request; no explicit state field,
  no scheduled task transitions state — state is computed at query time.
- **Reachability**: all 4 states reachable. note expired and revoked are final states (database won't auto-clean,
  but application layer won't let them return to active); active → none via logout actually deletes sessions record,
  so strictly speaking not state transition but record disappears

### 3.4 Out of Scope

#### 3.4a Business boundary (truly not needed to test)

- SMS two-factor authentication (next period feature)
- SSO login (Google / GitHub, not this period — as shown in screenshot, Apple/Google login out of scope this period)
- Remember login (Remember me option, not this period)
- email service reachability itself (owned by email service team)

#### 3.4b Engineering boundary (should test but cannot this period)

- **Password strength real-time feedback visual change**
  - Reason not to test: tool capability — Claude in Chrome unable to precisely capture password strength color change with each keystroke
  - Known risk: users may not see weak password hint and create weak password
  - Alternative: use INV-S3 to ensure backend rejects weak password; no frontend real-time feedback testing
  - Recommended remediation path: next period use Playwright to assert color class toggle after each input

### 3.5 Setup Strategy

per "focused test mode" — this spec only tests login, **does not test registration flow** (assume users already exist).

before entering test starting point, Operator should:

1. Call `POST /test/setup-user?email=alice@example.com&password=Test1234!` (setup endpoint)
   create test user alice
2. confirm browser cookies cleared
3. navigate to `/login`

if setup fails: Operator stops entire test, mark "setup failure" — do not attempt to run subsequent test cases.

#### 3.5b Environment isolation and Mock requirements

- External dependencies must mock: none (this login functionality does not depend on external services)
- Shared test resource isolation:
  - reset sessions table before each test round (`DELETE FROM sessions WHERE user_email LIKE '%test%'`)
  - rate limit counter testing uses independent redis namespace (avoid polluting production counter)
- unavoidable irreversible operations: none

## 4. Scenario Patterns

- matching scenario patterns:
  - **Form input type** (Behaviors B1-B4 involve "fill email+password → submit")
  - **User authentication / session management** (core function: login establishes session, cookie setup, session protection)
  - **Front-end rendering fidelity** (error message "Invalid email or password", button disabled gray visual toggle requires Agent to view screenshot)
  - **Exception paths (general)** (B2/B3/B4 are failure paths, need to test network exception / rate limit / server exception)
- non-matching but easily misidentified patterns:
  - non-matching "conversational UI" — single form submission, not chat
  - non-matching "asynchronous / streaming output" — login response single synchronous return
  - non-matching "LLM agent decision-making" — backend is regular credential verification, no LLM
  - non-matching "file upload / download" — no file input

## 5. Meta

- Generated by: Cartographer (example)
- Code commit: example-commit-hash
- Generated at: 2026-04-26T10:00:00Z
- Reviewed by human: yes
- Notes: this is a manually written example to demonstrate skill paradigm, does not correspond to any actual product

