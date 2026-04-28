---
name: spec-driven-test
description: Use specification-based testing methodology for end-to-end testing of web applications. Use this skill when users request "test this feature", "check this feature completeness", "do E2E testing on this project", "test this web app with an agent", or directly mention spec-driven-test / specification-based testing. This skill also applies to scenarios where users want to automatically generate test specs and test cases from code, then execute tests through browser automation. Even if users don't explicitly mention "spec" or "test case", if they want to systematically and automatically test a specific feature of a web project, this skill should be used.
---

# Spec-Driven Test

Use specification-based testing methodology for end-to-end testing of web applications.
The entire process is completed through collaboration of three agents: **Cartographer** reads code to generate specs and test cases, **Inspector** reviews test cases using methodologies, **Operator** executes tests in real browsers. Two rounds of human review ensure quality.

---

## On-Demand Loading Navigation (Read This Before Executing Skill)

This is a file-based skill—you **do not need to read all reference files at once**. Load corresponding sections by role and phase to significantly save tokens.

**Identify your role and only read the corresponding main file**:

- **Cartographer role** → Read `references/cartographer.md` (read sections by phase, see TOC at top of file)
  + Phases 0 / 1 / 2 / 2.5 / 3—only read the current phase section
  + After identifying matching scenario patterns at end of phase 1, **only read the matching** `references/scenarios/<corresponding-file>.md`, don't read all
  + When writing specs read `templates/spec-template.md`, when writing test cases read `templates/test-cases-template.md`
- **Inspector role** → Read `references/inspector.md` (read sections by step, see TOC at top of file)
  + Workflow §1 / 1.5 / 1.6 / 1.7 / 1.8 / 2 / 2.5 / 3 / 4
  + When selecting methodologies, **only read the matching** `references/methodologies/<corresponding-file>.md`, don't read all
  + For output format read `templates/judge-output-template.md`
- **Operator role** → Read `references/operator.md`, when producing reports read `templates/execution-report-template.md`

**Human review phase** → Read `references/human-review-checklists.md`

**Reading SKILL.md itself is just the entry point**—it's navigation, not detailed rules.
The real working rules are in each agent's reference file. **Load as needed** to control tokens.

---

## Overall Workflow

```
User specifies what feature to test
        ↓
┌───────────────────────────────────────┐
│ Cartographer Phase 0                  │
│ Confirm test scope + collect optional  │
│ information (ground truth, UI          │
│ screenshots, Operator tools)           │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer Phase 1                  │
│ Read code → generate specs            │
│ Annotate matching "scenario patterns"  │
└───────────────────────────────────────┘
        ↓
   ╔═══════════════╗
   ║  Human Review ║  ← First gate: confirm spec accuracy
   ╚═══════════════╝
        ↓
┌───────────────────────────────────────┐
│ Cartographer Phase 2                  │
│ Specs → test cases                    │
│ Fill scenario pattern self-check       │
│ checklist + Resource Dependency        │
│ Matrix                                │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer Phase 2.5 (if needed)    │
│ Decide file input strategy per file    │
│ (only when any TC has file_inputs)    │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Inspector                             │
│ Review test cases using methodologies  │
│ + self-check checklists               │
│ Output P0/P1/P2 severity feedback     │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer Phase 3                  │
│ Decide whether to fix each feedback    │
│ (fill rationale)                       │
└───────────────────────────────────────┘
        ↓
   ╔═══════════════╗
   ║  Human Review ║  ← Second gate: confirm test cases runnable
   ╚═══════════════╝
        ↓
┌───────────────────────────────────────┐
│ Operator                              │
│ Execute test cases in real browser    │
│ Output execution report                │
└───────────────────────────────────────┘
```

---

## Three Agent Responsibilities

| Agent | Role | What to See | What Not to See |
|------|-----|------|--------|
| **Cartographer** | Cartographer | Code + specs + test cases + Inspector feedback | (no restrictions) |
| **Inspector** | Inspector | Specs + test cases + methodologies | **do not see code** |
| **Operator** | Operator (simulating real user) | Test cases + actual browser state | **do not make correctness judgments + Steps do not shortcut via API** |

**Operator critical constraints**: trigger (the action that triggers the tested feature) **must** be completed through the browser UI, not via API / SSE / SQL shortcuts—otherwise E2E testing degrades to API testing. Only Setup / Teardown / verifying server_state are allowed to use API/DB shortcuts (since these are not the tested functionality itself). See `references/operator.md` Core Principle 1 for details.

Each agent's detailed guidance is in the corresponding reference file:

- Enter Cartographer role → Read `references/cartographer.md`
- Enter Inspector role → Read `references/inspector.md`
- Enter Operator role → Read `references/operator.md`

---

## Operator Hybrid Execution Mode (Playwright + LLM Screenshot Judgment)

### Core Concept

Operator adopts **hybrid execution mode** by default—neither pure LLM real-time browser operation nor pure Playwright scripts.
The two tools cooperate with division of labor, **letting each tool do what it does best**:

| Tool | Excels at | Does Not Excel at |
|----|--------|--------|
| **Playwright** | Input/output layer (data in data out), DOM assertions, SQL/API verification, replayable, extremely low token cost | Visual/UX judgment, "does it look right" semantic understanding |
| **LLM viewing screenshots** (computer-use) | Visual judgment, UI design/UX, Markdown/emoji/font rendering fidelity | Precise data assertions, loop execution, replayable |

Hybrid mode logic: **Playwright runs business workflow + leaves screenshots at key moments + LLM post-processes reading screenshots for visual judgment**.
This is approach X (Playwright leaves screenshots + LLM post-processes), **not** approach Y (scenario runs twice).

### Three TC Types (Operator-mode field)

When Cartographer writes each TC in phase 2, **must** mark the `Operator-mode` field, choose one of three:

| Mode | Applicable Scenario | Execution Method |
|----|--------|--------|
| **A: LLM browser** (Claude in Chrome / browser-use) | Test visual / rendering / UX / exploratory | LLM operates browser in real-time + reads screenshots for judgment |
| **B: Playwright** | Test input/output / data flow / business logic / regression | Generate .spec.ts script, Playwright engine executes |
| **C: Hybrid** (default recommended) | Both need data correctness and visual verification (e.g., chatbot message rendering, Markdown processing) | Playwright runs business workflow + leaves screenshots at key moments, LLM post-processes reading screenshots for judgment |

**Determining factors**:
- Test point is "data transmission correctness" → B
- Test point is "visual/rendering/UX" → A
- Test point needs both data and visual → C (most chatbot / CRUD / profile functionalities are C)

### Hybrid Mode C Execution Flow

```
TC-005: Send Markdown message, verify rendering + backend storage

Phase 1 (Playwright auto-execution):
  1. Browser navigates to /app/agent
  2. Enter "**important**\n# title" in textarea
  3. Click send button
  4. Wait for SSE stream to complete
  5. 📸 Take screenshot and save to screenshots/TC-005-after-send.png  ← screenshot node
  6. SQL verify: SELECT content FROM messages → should be "**important**\n# title"

Phase 2 (LLM post-processing):
  - Read screenshots/TC-005-after-send.png
  - Visual judgment: is "important" in the bubble bold? is "# title" a large header?
  - Output screenshot judgment results to execution-report

Merged Report:
  - Playwright trace: All Steps PASSED
  - LLM screenshot judgment: Bold ✅, Title ✅
  - Combined status: PASSED
```

### Two New Required Fields in TC (in test-cases-template.md)

- **`Operator-mode`**: A / B / C
- **`Screenshot points`** (only for mode A and C): list at which steps to take screenshots, and what LLM should judge for each screenshot

Example:

```yaml
Operator-mode: C

Screenshot points:
  - after_step: 5  # after SSE stream complete
    save_to: screenshots/TC-005-after-send.png
    llm_judges:
      - "Is Markdown **important** in the bubble rendered as bold <strong> element?"
      - "Is # title in the bubble rendered as <h1> large header?"
      - "Is overall bubble layout normal (no misalignment, text not overflowing)?"
```

### Inspector Does Not Review Operator-mode Tool Selection

Inspector does not question Cartographer's choice of A/B/C—this is an engineering decision, not a spec/methodology issue.
Inspector only reviews:
- Whether TC filled in `Operator-mode` (not filled → P0)
- Whether mode A and C TCs filled in `Screenshot points` (not filled but expected involves visual assertions → P1)

See `references/operator.md` workflow, and `templates/test-cases-template.md` field format.

---

## Agent Instance Isolation Rules (execution-time architecture)

The skill's three roles are not just logical roles—**they should run in different agent instances**,
which is the execution-layer guarantee for isolating independence.

### Inspector Must Run in Independent Agent Instance (mandatory)

**Reason**: Inspector's core value is "independent review of Cartographer's judgment"—
but if Inspector and Cartographer run in the same conversation,
Inspector has already "seen code / knows Cartographer's thinking process", **its independence is compromised**—
it will unconsciously defend Cartographer's design, significantly reducing review quality.

**Mandatory requirement**: After Cartographer phase 2 completes (and phase 3 revision completes), **must** tell the user to start an independent instance to run Inspector, **do not allow** directly switching roles in the original conversation.

**How to start an independent instance** (choose based on deployment environment):

| Environment | Recommended | Backup |
|------|--------|--------|
| **Claude Code** | Use subagent / Task tool to start new agent | Let user start new conversation |
| **API Call** | Initiate new conversation, system prompt guides entering Inspector role | — |
| **Claude.ai / Claude Desktop** | Let user start new conversation (regular users don't have subagent capability) | — |

**Input checklist for Inspector instance**:
1. Spec document (Cartographer phase 1 output + final version after human review)
2. Test case document (Cartographer phase 2 output + final version after phase 2.5 file decision completes)
3. Install spec-driven-test skill, system will guide entering Inspector role

**Absolutely do not pass to Inspector**:
- ❌ Code (any source code files)
- ❌ Cartographer phase 1 / phase 2 thinking process / intermediate decisions
- ❌ Cartographer's reasoning for selecting certain methodologies

After Inspector completes, pass the feedback document back to original Cartographer conversation, Cartographer phase 3 processes the feedback.

### Operator Not Mandatory to be Independent (same conversation OK)

**Reason**: Operator's value is "faithful execution"—seeing the code actually helps it better handle async timing details.
Honesty is ensured by E2E perspective constraint (SKILL.md principle 11), doesn't need context isolation.

Actually, **letting Cartographer continue in the same conversation to run Operator after phase 3 completes, is reasonable**—
the problem setter executing the test understands the problem details best.

**But must still respect these boundaries**:
- Operator must strictly execute according to reviewed test cases (Steps must use browser UI, no API shortcuts)
- Operator does not "creatively" add tests or modify test cases—these exceed execution responsibilities

### No Isolation Required Within Phase

All Cartographer phases (0 / 1 / 2 / 2.5 / 3) are Cartographer role,
**run continuously in the same conversation**—no need to switch agent instances.
The two human reviews in between are isolation mechanisms, not agent switches.

### Workflow Illustration

```
agent A(Cartographer): phase 0 → phase 1 → phase 2 → phase 2.5 → phase 3 → ... → Operator(optionally same instance)
                                                                      ↑
                                                  feedback passes back ── ── ── ┘
                                                       ↑
agent B(Inspector, independent instance): review
                                          ↑
                    (specs + test cases passed in)
```

---

## Core Deliverables

The entire workflow produces 4 types of documents, all in Markdown format:

| Deliverable | Produced By | Template |
|------|------|------|
| Spec Document | Cartographer | `templates/spec-template.md` |
| Test Case Document | Cartographer | `templates/test-cases-template.md` |
| Inspector Feedback | Inspector | `templates/judge-output-template.md` |
| Execution Report | Operator | `templates/execution-report-template.md` |

Complete working example in `examples/login-spec-example.md`.

---

## Starting This Skill

When a user requests testing a specific web feature, the agent enters **Cartographer Phase 0**:

1. **What feature does the user want to test**—clarify the specific feature name (e.g., "user login", "password reset")
2. **Where is the code**—the user should indicate project location or relevant files
3. **How to access the test environment**—has the user already started the project? How to use browser tools? (this affects Operator phase)

If any of the above is unclear, ask the user. Don't immediately start reading code.

Complete phase 0 protocol in `references/cartographer.md`.

---

## Pause Points and "Approved" Signals

The entire workflow has 2 mandatory human review checkpoints where agents **must pause** to wait:

| Pause Point | Triggered When | Must Do | Approval Signal |
|------|------|------|------|
| **Spec review** | After Cartographer phase 1 completes | Show spec to user | User says: "spec OK" / "approved" |
| **Test case review** | After Cartographer phase 3 completes (feedback processed) | Show final test cases to user | User says: "test cases OK" / "ready to run" |

Browser and environment issues can be addressed when Operator phase starts. First review focuses on spec accuracy, second review focuses on test case quality.

Complete review checklist in `references/human-review-checklists.md`.

---

## Key Design Principles

11 core principles—**each expands in the main file**—below gives one-sentence summary + reference to main file.

**1. Isolation boundaries between agents are the soul of the skill**—Inspector doesn't see code, Operator doesn't make correctness judgments.
Independence details see above "Agent Instance Isolation Rules".

**2-4. Three-layer spec structure / client vs server state / behaviors at user intent level**—how to write specs. See
`templates/spec-template.md` field comments, and `references/cartographer.md` phase 1.

**5. Severity grading (P0/P1/P2)**—P0 mandatory, P1 default to fix (don't fix requires rationale), P2 optional.
See `references/inspector.md` workflow §3.

**6. Information source authority levels**—when multiple sources conflict, trust by P1-P7 (user ground truth > SQL > fixture > code > config > documentation > verbal),
when conflicting explicitly declare for human decision. See `references/cartographer.md` phase 1 point 7.

**7. Multimodal input via engineering methodology**—spec only describes "what kind of file is needed", phase 2.5 lets user choose per file (A path / B manual / C Agent generate).
See `references/cartographer.md` phase 2.5.

**8. Easily-abstracted fields must carry "logical rationale"**—LLM reading code easily misattributes fallback / exception handling / template strings as regular rules.
Have Cartographer write rationale first then conclusion when writing fields involving code generalization, Inspector reviews "whether rationale vs conclusion are internally consistent".
See `references/cartographer.md` phase 1 point 8.

**9. Scenario patterns + self-check + review self-checks**—methodologies (EP/BVA) are "rulers", scenario patterns are "mandatory checklists".
Cartographer phase 1 identifies matching patterns → phase 2 marks each checklist item ✓/⚠/✗ (must give rationale) → Inspector reviews this self-check table.
Complete pattern library in `references/scenarios/`, mechanism details in `references/cartographer.md` phase 2 point 1 + `references/inspector.md` §1.5.

**10. Destructive TC identification + Setup/Teardown**—TCs sharing resources polluting each other is classic deadlock.
Each TC marks Destructive: yes/no, destructive TCs must have Teardown, irreversible operations must mock.
Test case document adds Resource Dependency Matrix. See `references/cartographer.md` phase 2 point 6 + `references/inspector.md` §1.7.

**11. E2E perspective: Steps must be user perspective**—Steps write "browser input X / click Y", not "POST /api/...";
otherwise E2E degrades to API testing. Only Setup / Teardown / verify server_state allowed to use API/SQL.
See `references/cartographer.md` phase 2 point 7 + `references/operator.md` core principle 1 + `references/inspector.md` §1.8.

**12. Operator hybrid execution mode (Playwright + LLM screenshot judgment)**—
no forced single tool. Each TC marks `Operator-mode`: A(LLM browser, suitable for visual/UX)/ B(Playwright, suitable for data flow/regression)/ C(hybrid, default recommended—Playwright runs business workflow + leaves screenshots at key moments, LLM post-processes reading screenshots for rendering judgment).
Approach X: screenshots left during Playwright phase, LLM post-processes reading screenshots, **does not** rerun scenario.
See "Operator Hybrid Execution Mode" section above + `references/operator.md` workflow.

---

## Methodology Reference

Inspector **selects methodologies by feature characteristics** (not run all 6). Current skill provides following methodology documents:

**Classical spec-based testing methodologies**:
- `references/methodologies/equivalence-partitioning.md` — Equivalence partitioning (for input-data types)
- `references/methodologies/boundary-value-analysis.md` — Boundary value analysis (for input-data types)
- `references/methodologies/decision-table.md` — Decision table (for multi-condition combinations)
- `references/methodologies/state-transition.md` — State transition (for state machines)
- `references/methodologies/use-case-testing.md` — Use case testing (for complete workflows)

**Auxiliary checklists**:
- `references/methodologies/right-bicep.md` — Right-BICEP (auxiliary cross-validation, not as primary methodology)

Complete selection logic in `references/inspector.md` §2.

---

## Examples

`examples/` directory provides complete examples for Cartographer / Operator reference:

**Simple feature examples (login)**—demonstrates basic structure of specs + test cases:
- `examples/login-spec-example.md` — User login spec example (three-layer structure, §3.4 breakdown, §3.5 setup, logical rationale)
- `examples/login-cases-example.md` — Corresponding test case example (Resource Dependency Matrix, scenario pattern self-checks, 5 representative TCs)

**Complex feature examples (chatbot, core)**—demonstrates complete application of hybrid mode C:
- `examples/chatbot-spec-example.md` — Lightweight chatbot spec (dialog-style UI + async streaming + LLM agent + frontend rendering fidelity multi-mode overlay)
- `examples/chatbot-cases-example.md` — Corresponding test cases (Operator-mode A/B/C all used, complete Screenshot points)
- `examples/chatbot-execution-report-example.md` — Execution report example (Playwright trace summary + actual LLM screenshot judgment segment fill-in)

**Strongly recommended**: When Cartographer writes TCs involving frontend rendering fidelity in phase 2, **must read chatbot-cases-example.md**—
TC-002 inside is the standard example of hybrid mode C.

---

## Engineering Boundaries

This skill **does not** do (and how to handle):

- **Skill does not audit code correctness**—if code itself has bugs, the spec only describes "what buggy code does"; tests will run according to this and pass. This is by design: spec-driven testing tests "whether implementation matches spec", while "whether spec is correct" is human review responsibility.
- **Performance / load testing**—out of scope; specs describe behavior, not performance characteristics.
- **Security audit**—skill covers basic auth/authorization and input boundaries (XSS via length boundaries), but **cannot** replace professional security audit.
- **Visual regression**—skill verifies functional behavior, not pixel-level visual changes.

---

## Adding New Scenario Patterns

If actual use discovers a repeating scenario type not covered by current 11 patterns (e.g., "real-time collaborative editing", "blockchain transaction", "image recognition"), add new pattern following these steps:

1. Pick a concise name (2-4 characters)
2. Create new `.md` file in `references/scenarios/` (follow existing file structure as reference)
3. In the file list the mandatory checklist items for this pattern
4. Add a line to `references/scenarios/index.md` so Cartographer can discover it

This is low-cost extension—no need to modify Cartographer or Inspector main files, they read the latest directory version.

---

## Notes

This skill is a heavyweight tool, running complete E2E testing once may consume 100K-500K tokens (depending on feature complexity). Suitable for:

- Critical business workflows (login / payment / data create-delete)
- Security-related features (permissions / authentication / privacy)
- LLM agent systems (grounding / hallucination / tool invocation safety)

Not suitable for:

- Simple UI interaction testing (write directly with Playwright faster)
- Unit tests (use pytest / jest)
- Performance load testing (use dedicated tools)
- Exploratory testing (manual operation more efficient)

Before using ask yourself: is this feature worth spending 100K-500K tokens doing rigorous E2E testing?
