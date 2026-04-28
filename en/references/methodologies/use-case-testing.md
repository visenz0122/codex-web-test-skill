# Use Case Testing

## Core Concept

Decompose feature into user-perspective "use cases", each describing complete business flow.
Each use case needs tests for three path types:

- **Main Flow**: user's most common successful path
- **Alternate Flow**: same objective, different implementation
- **Exception Flow**: failure, timeout, resource shortage, etc.

This is **mandatory self-check for Cartographer** when generating test cases
(corresponding to responsibility b embedded in SKILL.md), Inspector reviews completeness of this coverage.

## Application Steps (for Inspector)

1. For each behavior or use case in spec, check test count for three path types
2. All three have at least 1 → pass
3. Missing exception paths → almost certainly P0 (missing exception paths most common bug source)
4. Missing alternate paths → P1 or P2 depending

## Three Path Type Distinction

**Main path**:
- Most direct success flow
- Most frequent user path
- Usually 1 use case corresponds to 1 main path

**Alternate path**:
- Different success methods (same objective, different route)
- Example: login can use account/password, SSO, magic link — 3 alternates

**Exception path**:
- All failure reasons
- Timeout, network error, permission denied, resource exhausted
- Example: login fails due to wrong password, locked account, server 500, network down, CAPTCHA fail

## Example: Login Feature

**Main path**:
- Registered user enters correct password → login success

**Alternate paths**:
- SSO login (Google / GitHub)
- Magic link (email login)
- Two-factor auth then login

**Exception paths**:
- Password wrong
- Account not exist
- Account locked
- Rate limit
- Network disconnect
- Backend 500
- CAPTCHA fail

→ at least 11 test cases. Fewer means Inspector will comment.

## Inspector Feedback Example

```
P0-001: Exception path coverage insufficient
- Methodology: Use Case Testing
- Issue: test cases only cover password wrong, miss account locked, rate limit, network anomaly
- Affected: spec behavior B4 (rate limit), B5 (account locked) exist but no TCs
- Suggested fix: add TC covering each exception path

P1-001: Alternate path not tested
- Methodology: Use Case Testing
- Issue: spec mentions Google login support, but TCs only test password login
- Suggested fix: add TC for SSO login, or explicitly declare in out_of_scope
```

## Severity Judgment

- **P0**: main path missing (almost impossible but P0 if occurs)
- **P0**: core exception paths (permission/resource/data integrity related) missing
- **P1**: alternate path missing (user experience affected, but feature usable)
- **P2**: rare exception (network jitter) not tested

## Common Mistakes

- ❌ only test main path (typical happy path bias)
- ❌ treat "input validation fail" as exhausting exception paths (only input-related)
- ❌ ignore server exceptions (500, timeout)
- ❌ merge success of alternate path into main path (lose separate verification)
