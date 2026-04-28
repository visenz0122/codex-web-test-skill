# User Authentication / Session Management

## Applicable Scope

Any functionality involving "user identity establishment, maintenance, termination":

- Login (password / SSO / magic link / two-factor authentication)
- Logout (single-device / all-device)
- Remember login (persistent cookie / refresh token)
- Cross-tab sync / cross-device sync
- Session expiration, token refresh
- Account lockout, unlock

**Key distinguishing factor**: the core of functionality is changing or maintaining "user login state".

## Mandatory Checklist

### Login Main Path

- Registered user + correct password → login successful
- SSO login (if any Google / GitHub)
- Magic link login (if any)
- Two-factor authentication flow (if any)

### Login Failure Path

Test each failure reason independently:

- Wrong password
- Account does not exist
- Account is locked
- Rate limiting triggered
- CAPTCHA failure (if any)
- Network exception
- Backend 500

### Session Lifecycle

- Just logged in: cookie set correctly, HttpOnly + Secure + SameSite
- About to expire: does refresh mechanism trigger
- Already expired: how to handle when user operates
- Forcibly logged out: admin kicks person, all sessions invalid after password change

### Cross-tab / Cross-device Sync

- A tab logs out, does B tab sync logout
- Multiple devices logged in simultaneously: do they kick each other (depends on business design)
- A device changes password, does B device's session become invalid

### Security Invariants

- **Token flag**: HttpOnly, Secure, SameSite all set?
- **Login state leakage**: does URL contain token, does localStorage contain password, does log contain password?
- **Session fixation attack**: does session id change before and after login
- **Brute force protection**: failure count limit for same IP / same account
- **Password safety**: is storage hashed, is transmission HTTPS
- **Email enumeration protection**: do "wrong password" and "account does not exist" responses match (status code, message, response time)

### Logout

- Proactive logout: cookie cleared, server-side session revoked
- Multi-device logout: do other sessions of same account become invalid
- After logout access requires login page: correctly redirect to login page

## Key Reminders

**Email enumeration protection** is one of most commonly overlooked security test points. Developers intuitively write different prompts for "wrong password" and "account does not exist"—this precisely leaks whether email is registered. Inspector should be sensitive when seeing B2 / B3 responses inconsistent.

**Session sync issues** are easy to overlook during testing—usually requires two browsers or two tabs operating simultaneously to discover, human testing easily skips this step.

## Not Applicable Cases

- Page that merely displays login state (read-only user info) → use "profile / profile management" pattern
- Permission checking (after logged in, can do something) → use "multi-tenant / permission matrix" pattern


