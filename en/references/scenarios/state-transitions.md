# State Transitions

## Applicable Scope

Any "system switch between different states" functionality:

- Order lifecycle (pending payment / paid / shipped / received / completed)
- Token lifecycle (generated / sent / used / expired / revoked)
- Approval flow (draft / pending approval / approved / rejected / withdrawn)
- Resource status (idle / in-use / releasing / fault)
- Task status (pending / in-progress / completed / cancelled)
- User account status (normal / locked / deactivated / suspended)
- Deployment / release process

**Key distinguishing factor**: **functionality involves clear state machine**—states finite, transitions have rules,
certain state determines what can and cannot do.

## Mandatory Checklist

Detailed test method see `methodologies/state-transition.md`. Here list key points:

### State Reachability

Each state must have TC able to enter:

- Starting from initial state, through legal transition path reach each state
- State with more than one reachable path (such as cancelled can enter from pending or from paid),
  **test each path**

### Legal Transition Test

Each legal transition listed in spec must have TC test.

### Illegal Transition Rejection (key, commonly missed)

**This is most easily missed category of test**:

- Paid order **cannot** return to "pending payment"
- Received order **cannot** return to "shipped"
- Cancelled order **cannot** pay again
- Used token **cannot** use again
- Rejected approval **cannot** directly enter "approved"

Each illegal transition should be rejected by server, return clear error (409 / 403 / business code).

### Island States and Dead States

- **Island state**: starting from initial state, through any legal transition cannot reach → spec design problem
- **Dead state** (trap): after reaching no transition can leave → terminal state is expected,
  but intermediate state should not be dead state

### State Transition Trigger Condition

- **Normal trigger**: user operation / system event / scheduled task
- **Trigger condition not satisfied**: such as "try ship, but order not paid" → should be rejected
- **Concurrent trigger**: two users simultaneously try change same state → only one succeed

### State Query Consistency

- State displayed when list query vs state in detail query → must consistent
- State field in database / cache / UI three places synchronization

## Key Reminders

**Illegal transition test is P0 missed test "disaster area"**—developers intuitively "user won't operate like this",
but attacker will trigger illegal transition through API direct call or race condition.

**Test "paid order cannot pay again" like**—many payment systems have this kind of bug,
attacker replay payment request cause duplicate deduction / duplicate shipment.

**State machine design itself check** (Inspector suggest for human):
- Island state (enter but cannot exit)
- Dead state (after reaching cannot continue)
- Unclear state naming (active / pending / processing three similar)

## Common Overlaps

Usually appears together with these patterns:
- CRUD list and detail (order etc. resources with state)
- Multi-tenant / permission matrix (permission of state change)
- Async / streaming output (state change may trigger streaming notification)

## Not Applicable Cases

- Stateless pure query functionality (no state machine)
- Single-state functionality (always only one state)
- Functionality with unfixed state transition rules (such as free edit document)
