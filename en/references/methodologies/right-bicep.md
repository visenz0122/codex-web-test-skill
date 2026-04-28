# Right-BICEP

## Core Concept

From unit testing circles (Hunt & Thomas "Pragmatic Unit Testing"),
**not one of classic spec-based testing methodologies** — it's a supplementary checklist,
specifically to catch "tests appear passing but actually don't verify anything" situations.

Six letters:

- **R**ight — is the result correct?
- **B**oundary — boundary conditions considered?
- **I**nverse — can reverse operation verify?
- **C**ross-check — any alternate path to verify independently?
- **E**rror — error handling tested?
- **P**erformance — performance acceptable?

Note: **R/B/E overlap with classic methodologies** (EP/BVA/Use Case),
so Inspector using Right-BICEP **focuses only on I / C / P letters**.

## Selective Activation Conditions

Inspector **does not** apply Right-BICEP to all features. Activate only when spec meets conditions:

| Condition | Activate letter | Meaning |
|---|---|---|
| Behaviors contain write semantics (create/modify/delete/state change) | **I** | operation has side effects, needs reverse verification |
| Behaviors have non-empty server_state_after field | **C** | server has independently verifiable state |
| Spec invariants or hints mention time limit | **P** | performance expectation can assert |

**Three conditions can stack** — feature may simultaneously activate I + C (e.g. order feature).
**None of three conditions met** (pure display, pure frontend component, static page), **completely skip Right-BICEP**.

### Why Selective Activation

These three letters become noise in inapplicable scenarios:

- Pure query has no "reverse" concept — Inverse doesn't apply
- Single data source has no "another path" — Cross-check doesn't apply
- Background batch user can't perceive — Performance doesn't apply

Forcing it generates low-quality Inspector suggestions.

## Each Letter Check Method

### I — Inverse (reverse verification)

- After operation completes, can reverse operation verify?
- After signup → can we login with registered account?
- After delete → is it really gone from list?
- After add-to-cart → is product really in cart?

**This is most easily missed check**. Most tests only assert "operation returned success", don't verify "system actually entered expected state".

### C — Cross-check (cross verification)

- Same fact, can verify via another independent path?
- User changed avatar in UI → query via API, avatar URL should match
- User added product → login same account in another browser, cart should sync

**Cross-check catches UI vs data inconsistency, stale cache bugs**.

### P — Performance (performance)

- Does spec or business have response time expectation?
- Do test cases verify it?
- Example: login should complete < 2s, but test never checks time — P letter missing

## Inspector Feedback Example

```
P0-001: Inverse check completely missing
- Methodology: Right-BICEP (I)
- Issue: all signup TCs only assert "signup success page appears", no TC then tries login with registered account
- Suggested fix: add at least 1 TC that after signup immediately tries login, verifies account is usable

P1-001: Cross-check missing
- Methodology: Right-BICEP (C)
- Issue: user avatar update TC only checks UI avatar changed, doesn't verify via API or page refresh that server actually updated
- Suggested fix: add TC, after update call API to get user info, confirm avatar URL changed

P1-002: Performance expectation not verified
- Methodology: Right-BICEP (P)
- Issue: spec says "login should complete in 2 seconds", but all TCs have no time assertion
- Suggested fix: add duration < 2s assertion in login TCs
```

## Severity Judgment

- **P0**: activated letter's check **completely missing** (e.g. activated I but entire test set has no reverse verification)
- **P1**: activated letter's check **partially covered** (some TCs should but don't)
- **P2**: individual TC can add cross-check to enhance

## Don't Repeat

- R/B/E letter issues → should raise during EP/BVA/Use Case phase. Right-BICEP here **only for I/C/P**
- If activation conditions all unmet, skip Right-BICEP entirely, **don't list in Self-Check table**

## Quick Applicability Check

| Feature type | Activate? | Letters |
|---|---|---|
| signup/login/logout | ✅ | I + C (write + server state change) |
| add-to-cart/order/pay | ✅ | I + C + possibly P |
| user edit profile | ✅ | I + C |
| list query/pagination | maybe | only P (if performance expected) |
| detail page display | usually no | - |
| pure frontend interaction (tab toggle) | no | - |
| static display page | no | - |
