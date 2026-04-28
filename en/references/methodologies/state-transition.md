# State Transition

## Core Concept

Some features' essence is not "input maps to output", but "system switches between different **states**".
State transition testing specifically tests such features — **ensuring each state reachable, each legal transition correct, each illegal transition rejected**.

Difference from other methodologies:

- **EP/BVA** test input data
- **Decision Table** test condition combinations
- **State Transition** test system **"memory"** — what happened before determines what you can do now

## When to Use This Methodology

When spec's `## 3.3 State Machine` field is non-empty, must use this methodology.

Typical stateful features:

- **Order flow**: `pending → paid → shipped → delivered → completed`
- **Token lifecycle**: `generated → sent → used / expired / revoked`
- **Session state**: `not logged in → logged in → session expired → logged out`
- **Approval flow**: `draft → pending approval → approved / rejected`
- **Resource state**: `idle → in use → releasing → idle`

Stateless features (pure query, pure calculation) don't apply — skip this methodology entirely.

## Application Steps (for Inspector)

1. Extract **state list** and **transition list** from spec `hints.state_machine`
2. For each state, check **at least one TC can reach it**
3. For each legal transition, check **at least one TC tests it**
4. For each illegal transition (not listed in state machine), check **TC verifies it's rejected**
5. Check for **island states** (reachable but unreachable from, or unreachable from initial) and **dead states** (reachable but no exit)

## Example: Order State Machine

Spec `hints.state_machine`:

```
States: [pending, paid, shipped, delivered, cancelled]
Transitions:
  - pending → paid:        triggered by "user pays"
  - pending → cancelled:   triggered by "user cancels"
  - paid → shipped:        triggered by "merchant ships"
  - paid → cancelled:      triggered by "user requests refund"
  - shipped → delivered:   triggered by "courier signs"
```

### Check Type 1: State Reachability

Each state must have TC to enter:

| State | Entry path | Has TC? |
|---|---|---|
| pending | create order | ✅ |
| paid | pending → paid | ✅ |
| shipped | pending → paid → shipped | ✅ |
| delivered | full chain | ✅ |
| cancelled | pending → cancelled OR paid → cancelled | ✅ (note: test both paths) |

### Check Type 2: Legal Transition Tests

| Transition | Has TC? |
|---|---|
| pending → paid | ✅ |
| pending → cancelled | ✅ |
| paid → shipped | ✅ |
| paid → cancelled | ✅ |
| shipped → delivered | ✅ |

5 legal transitions, 5 TCs.

### Check Type 3: Illegal Transition Rejection

Transitions **not listed** in state machine should be rejected. Test specifically:

- `paid → pending` (paid order cannot return to pending)
- `delivered → shipped` (delivered cannot revert to shipped)
- `cancelled → paid` (cancelled order cannot be paid again)
- `shipped → cancelled` (can ship cancelled? — depends on business, if not allowed, test rejection)

**This is most commonly missed** — test cases usually only cover happy path, forget "system prevents illegal operations".

### Check Type 4: Island and Dead States

- **Island state**: starting from initial state, unreachable via any transition
  - E.g. state machine has `archived` but no transition leads to it → either add transition or delete state
- **Dead state** (trap state): reachable but no transition can exit
  - E.g. `delivered` is terminal — OK, that's expected
  - E.g. `paid` has no transition out → bug

## Inspector Feedback Example

```
P0-001: State reachability incomplete
- Methodology: State Transition
- Issue: spec state machine has 5 states, but cancelled reached only from pending, not from paid
- Affected: hints.state_machine transition paid → cancelled
- Suggested fix: add TC with precondition order already paid, trigger user requests refund, expected state becomes cancelled

P0-002: Illegal transition not tested
- Methodology: State Transition
- Issue: state machine implicitly "delivered order cannot revert to shipped", test completely lacks this protection
- Suggested fix: add TC with precondition delivered state, trigger ship API call, expected should be rejected (403 or 409)

P1-001: Island state
- Methodology: State Transition
- Issue: state machine lists archived state, no transition leads to it, unreachable
- Suggested fix: either add transition rule to reach archived in spec, or remove state from spec
```

## Severity Judgment

- **P0**: state reachability missing (listed in spec but TC cannot reach)
- **P0**: core illegal transition not tested (especially money, permission, data integrity related)
- **P1**: secondary illegal transition not tested
- **P1**: island or dead state (spec design issue, may not be test case issue — point out for human review)
- **P2**: state naming or transition description unclear

## Common Mistakes

- ❌ only test happy path state flow, forget illegal transitions
- ❌ terminal state (like delivered) mistaken for "dead state" — terminal is expected
- ❌ treat same state in different context as different states (e.g. "not logged in" vs "session expired" if system behavior identical, should merge)
- ❌ test "A → B" but forget "B → A" should be allowed (symmetry)

## Not Applicable

- Pure query/display feature (no state machine)
- Pure calculation (input determines output, no "memory")
- Pure routing jump (URL change, but system has no state)

If spec's `## 3.3 State Machine` field explicitly writes "(none)", skip this methodology entirely.
