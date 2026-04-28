# Human Review Checklist

This skill workflow has two **mandatory human reviews**.
This document is an auxiliary checklist for human users — not for agents.
When agents reach review nodes, they can **show relevant parts of this checklist to users**, helping users complete review efficiently.

---

## Contents

- First: Spec Review(after Phase 1 completion)
- Second: Test Case Review(after Inspector feedback completion)
- "Pass" signals at pause points

---

## First: Spec Review(after Phase 1 completion)

### What you are reviewing

Cartographer just translated code into a spec. You are reviewing: **Does the spec behavior description match the actual product?**

### Review Checklist

**Logical Rationale(review first)**

All fields in spec involving code generalization(behaviors expected, invariants, boundaries, state machine) have a "logical rationale" sub-field.
**Read the rationale first before looking at conclusion** — this lets you review one item in 30 seconds and catch LLM abstraction errors.

- [ ] Does each invariant / behavior expected / boundary / state machine have a "logical rationale"?(Request supplement if missing)
- [ ] Does the rationale description of code control flow(branches, conditions) clear?(shouldn't be hollow statements like "code logic guarantees this invariant")
- [ ] Is the "reachability" judgment in rationale correct?(such as claiming "fallback unreachable", can you verify content of ALL_TOOLS in code)
- [ ] **Can the conclusion naturally follow from the rationale?**(Classic misuse: rationale writes "5 branches, fallback unreachable", but conclusion uses fallback text)
- [ ] Don't panic seeing "conclusion correction" annotation — this shows Cartographer did self-review, actually a quality signal

**Interface section**

- [ ] In route list, any omissions or extras?
- [ ] Any API endpoints omitted or written wrong?
- [ ] Do these routes and APIs really belong to this feature, or did Cartographer accidentally capture unrelated code?

**Behaviors section**

- [ ] Does each behavior's "user intent → system behavior" match actual product behavior?
- [ ] Any important behaviors omitted?
- [ ] Are preconditions reasonable(does the user really need this precondition to trigger)?
- [ ] Does the expected final state description match actual product behavior?

**Invariants section(critical)**

- [ ] Are security invariants complete?(password not in URL / logs, token safely generated etc.)
- [ ] **Pay special attention to "equivalent behavior" in cross_cutting_invariants** — this usually hidden security design in code, did Cartographer infer correctly? Any omissions?
- [ ] Are business invariants complete?(data consistency, calculation correctness etc.)

**Hints section**

- [ ] Are boundary values listed in fields all relevant? Any code restrictions not listed in hints?
- [ ] Do decision table condition combinations match business reality?
- [ ] Is content in Out of Scope reasonable(really not testing this round)?

**Source annotation and conflict annotation**

- [ ] Do all conflict-prone fields(test accounts, API paths, UI text, boundary values) have *(source: file:line number)* annotation?
- [ ] When seeing ⚠️ conflict warning, **focus confirmation** — Cartographer found "code vs documentation" inconsistency, needs you to decide which to use

**Scenario Patterns annotation**

The `## 4. Scenario Patterns` field in spec annotates which scenario patterns this feature matches.
**The accuracy of this annotation directly affects what test cases Phase 2 generates** — wrong annotation or omission causes subsequent coverage deviation.

- [ ] Do scenario patterns Cartographer marked match actual characteristics of this feature?
- [ ] Does each matching pattern have concrete "matching rationale"?(not vague like "involves conversation")
- [ ] **Are there any omitted patterns?** Simple check against common patterns:
  - Involves login state / token → User authentication / Session management
  - Multiple roles / resource isolation → Multi-tenant / Permission matrix
  - Streaming output / SSE / long polling → Async / Streaming output
  - Backend calls LLM → LLM agent decision
  - File upload/download → File upload / Download
  - Almost any feature → Exception path(generic)
- [ ] Is explanation for "not matching but easy to misjudge" patterns reasonable?

Omitted annotation is more dangerous than wrong annotation — you can usually catch wrong annotation, but omission makes Phase 2 not generate test cases for that pattern, which is hard to notice.

### What to do if problems found

- Tell agent "change Y description in section X", agent will modify and resubmit
- Don't move to next phase after one fix; **fix all issues before saying "pass"**
- Only after explicit "pass" does agent move to Phase 2(test case generation). Common confirmation words: "pass", "OK", "continue", "approved", "proceed"

### What if unfamiliar with some technical details

- "Verifiable via" field(how to verify server_state) can ask agent to explain if unclear
- Specific numbers in boundary value list uncertain can have agent annotate "code source line number" for confirmation
- Unsure if invariants are too strict or too loose, can directly say and have agent adjust

---

## Second: Test Case Review(after Inspector feedback completion)

### What you are reviewing

Cartographer has generated test cases based on spec, Inspector has reviewed once. You are reviewing:

1. **Completeness**: Do test cases cover all important controls and interactions on actual page?
2. **Reasonableness of Cartographer's rationale**: For P1 items where Cartographer decided not to fix, is the rationale sound?
3. **Authenticity of scenario pattern self-check**: Are ✓ / ⚠ / ✗ marked by Cartographer with credible reasoning and code evidence?

### Review Checklist

**Scenario Pattern Coverage Self-Check**

Open the `## Scenario Pattern Coverage Self-Check` section in test case document. **For each item in each matching pattern**:

- [ ] **✓ items**: Open the TC it claims to correspond to — does this TC really cover this checklist item?(not "happens to use it")
- [ ] **⚠ items**: Is the reason concrete? Can it let you independently judge "this reason holds up"?
  - Good reason: "Tool X doesn't support precisely triggering IME half-finished state, needs Playwright supplement" — concrete and verifiable
  - Bad reason: "not important", "not testing this round" — reject, request rewrite
- [ ] **✗ items**: Does code rationale concretely reference file:line number + control flow logic?
  - Good rationale: "router.js:88 uses POST body, doesn't go through URL, this checklist item impossible" — can verify against code
  - Bad rationale: "code doesn't support" — reject, request specific location
- [ ] Can you directly verify ✗ items' rationale against code? If yes, **spot-check 1-2** to confirm

> Humans are better at this review than Inspector — **because you can read code**.
> Inspector can only review "whether reasoning is logically self-consistent", can't verify "whether code facts are really so".

**Completeness(page vs test cases)**

Open actual page, cross-check with test case document:

- [ ] Does each **input field** on page have corresponding test case?
- [ ] Does each **button** on page have corresponding click test case?
- [ ] Does each **link / navigation** on page have corresponding test case?
- [ ] Are different views for **state transitions**(such as logged in/not logged in, loading/loaded) all covered?
- [ ] Are error message prompts(toast / banner in various failure cases) all covered by test cases?

> This part Inspector can't do — Inspector doesn't see actual page, only test cases and spec.
> You are the only role that can do "page vs test cases" comparison.

**Rationale reasonableness(check Inspector Feedback Log)**

Open the `Inspector Feedback Log` section in test case document, check each:

- [ ] Does each "not adopted" P0/P1 have rationale?
- [ ] Is rationale **concrete**(not "unnecessary", "low value" kind of lip service)?
- [ ] Can you confirm facts referenced in rationale(such as "code uses ORM")?(If not, have agent provide evidence)
- [ ] Do you agree with Cartographer's judgment?

**Main/Alternative/Exception path coverage**

Check Coverage Summary table at top of test case document:

- [ ] Main path count is reasonable(generally 1 per behavior)
- [ ] Exception paths sufficient(network error, permission error, resource error all covered?)
- [ ] Alternative paths not missed(such as login has SSO option, SSO test case can't be missing)

### What to do if problems found

If completeness issues found:
- Tell agent "page has X control not covered, add a test case"
- agent will supplement and resubmit for confirmation

If certain Cartographer rationale found unreasonable:
- Tell agent "I don't accept rationale for not fixing P1-X, reason is Y"
- agent will either fix the test case or rewrite rationale

**After all issues pass**, explicitly say "pass", "go run tests" etc., let agent move to Operator phase.

---

## "Pass" signals at pause points

There are several points in the skill workflow where agent must pause and wait for you:

| Pause point | Agent is waiting for | What you say to continue |
|------|------|------|
| After spec review | Cartographer waiting for you to review spec | "pass" / "OK" / "continue" or similar |
| After Inspector feedback | Cartographer waiting for you to review test cases | Same as above |
| After Operator runs | Operator waiting for you to see report | Usually final, no need to "continue" |

If you say "modify X, Y section" etc., agent will modify and resubmit, **waits for your next confirmation** — won't automatically proceed.
