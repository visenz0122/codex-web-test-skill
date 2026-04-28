# Decision Table

## Core Concept

When multiple conditions **combine** to affect result, list all combinations in table format, each row is one test case.
Applicable: **"if A and B and C then X" logic in business rules**.

Testing each condition independently cannot cover condition interactions —
"logged in can use" and "non-empty cart can use" combined **do not necessarily equal** "logged in AND non-empty cart" can use.
Bugs often hide in condition conjunction.

## Application Steps (for Inspector)

1. Get condition combination table from spec hints.decision_table
2. Check each row has corresponding test case
3. Check if Cartographer reasonably "collapsed" equivalent rows (explained below)
4. Check for implicit branches handled in code but not listed in spec

## Full Coverage vs Collapsed Coverage

N boolean conditions theoretically have 2^N rows. Cartographer **can collapse** equivalent rows, but must explain:

- **Collapsible**: once certain condition value is determined, others don't affect result
  - E.g. when `not logged in`, inventory and cart status both irrelevant (all redirect to login)
  - Can collapse all `not logged in` sub-combinations into 1 row
- **Not collapsible**: each condition independently affects result
  - Must cover every combination

**Inspector allows collapsing but requires explicit justification**. If Cartographer skips combinations without explaining, Inspector raises P1.

## Example: Add to Cart

**Conditions**:
- C1: user logged in
- C2: product in stock
- C3: cart not full

**Full decision table (8 rows)**:

| C1 | C2 | C3 | Expected behavior |
|----|----|----|------------|
| ✅ | ✅ | ✅ | B1: add success |
| ✅ | ✅ | ❌ | B2: "cart full" |
| ✅ | ❌ | ✅ | B3: "no stock" |
| ✅ | ❌ | ❌ | ? (stock first or full first?) |
| ❌ | * | * | B4: redirect login (collapsible) |

→ 5 rows after collapse: 4 combinations logged in + 1 row not logged in

## Inspector Feedback Example

```
P0-001: Decision table branch missing
- Methodology: Decision Table
- Issue: spec decision table 5 rows, test cases only cover 3
- Affected: missing (✅,❌,❌) and (✅,❌,✅)
- Suggested fix: add corresponding TCs, or explain in test document "logged-in no-stock two sub-branches equivalent" rationale

P1-001: Priority unclear
- Methodology: Decision Table
- Issue: when C2 (no stock) and C3 (cart full) both false, neither spec nor cases say which takes priority
- Suggested fix: confirm business priority with human then add TC, or mark "pending business confirmation"
```

## Severity Judgment

- **P0**: rows explicitly listed in spec decision_table not fully covered
- **P1**: implicit decision table inferred from behavior preconditions has gaps
- **P2**: collapsing reasonableness debatable

## Common Mistakes

- ❌ merge multiple conditions into one TC (failure attribution unclear)
- ❌ collapse without explaining
- ❌ miss how contradictory conditions handle "impossible combinations"
- ❌ more test cases than table rows (same combination tested multiple times, waste)

## Not Applicable

- Single condition determines result (no table needed)
- Multiple conditions independent with no interaction on result (e.g. "dark mode" and "language" independent dimensions, no interaction)
