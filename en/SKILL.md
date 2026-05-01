---
name: codex-web-test
description: Codex-first skill for web feature tests, E2E tests, and acceptance tests. Use when the user asks to test/check/verify a web feature, inspect a page, run Browser Use/Computer Use testing, or mentions codex-web-test / spec-driven-test. Use Quick Feature Test for small checks and Full Flow Test for acceptance or large flows. Emphasizes Browser Use / Playwright Script / Computer Use boundaries, viewport evidence, screenshots/console evidence, setup/teardown, and post-test finding classification.
---

# Codex Web Test

Codex-first web feature testing skill.

It keeps the rigor of specification-based testing, but does not force every request through the heavy flow:
- **Quick Feature Test**: single-feature verification with Browser Use, viewport records, screenshots, console/dialog evidence, and compact feedback.
- **Full Flow Test**: large-flow or acceptance testing coordinated by Coordinator, with Cartographer specs/cases, independent Inspector review, Operator execution, and Coordinator final review.

---

## On-Demand Loading Navigation (Read This Before Executing Skill)

This is a file-based skill—you **do not need to read all reference files at once**. Load corresponding sections by role and phase to significantly save tokens.

**Identify your role and only read the corresponding main file**:

- **Coordinator / Test Lead role** → Read `references/coordinator.md`
  + Read first for any testing request
  + Choose Quick Feature Test or Full Flow Test
  + Route Codex tools, manage viewport evidence, and classify final findings
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

## Codex Test Modes

### Quick Feature Test

Use for one button, page, form, local interaction, or smoke test after a change. Do not force full spec / test cases / Inspector.

```
User specifies feature
        ↓
Coordinator chooses Quick
        ↓
Read necessary code + confirm service/URL
        ↓
Browser Use opens page + records viewport
        ↓
Run real user path + collect screenshot/console/dialog evidence
        ↓
Coordinator outputs finding classification + retest advice
```

### Full Flow Test

Use for large tasks, complex flows, acceptance, permissions/data/agent workflows, or repeatable regression.

## Overall Workflow

```
User specifies what feature to test
        ↓
┌───────────────────────────────────────┐
│ Coordinator                            │
│ Choose Full + confirm scope/tools/     │
│ viewport/data                          │
└───────────────────────────────────────┘
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
│ Execute test cases with Codex tools    │
│ Output execution report                │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Coordinator Final Review               │
│ Classify bugs / environment / tool     │
│ limits / retest advice                 │
└───────────────────────────────────────┘
```

---

## Four Role Responsibilities

| Agent | Role | What to See | What Not to See |
|------|-----|------|--------|
| **Coordinator / Test Lead** | Coordinator | User goal + project state + tool capability + final report | Does not replace Operator's browser execution |
| **Cartographer** | Cartographer | Code + specs + test cases + Inspector feedback | (no restrictions) |
| **Inspector** | Inspector | Specs + test cases + methodologies | **do not see code** |
| **Operator** | Operator (simulating real user) | Test cases + actual browser state | **do not make correctness judgments + Steps do not shortcut via API** |

**Operator critical constraints**: trigger (the action that triggers the tested feature) **must** be completed through the browser UI, not via API / SSE / SQL shortcuts—otherwise E2E testing degrades to API testing. Only Setup / Teardown / verifying server_state are allowed to use API/DB shortcuts (since these are not the tested functionality itself). See `references/operator.md` Core Principle 1 for details.

Each agent's detailed guidance is in the corresponding reference file:

- Enter Coordinator role → Read `references/coordinator.md`
- Enter Cartographer role → Read `references/cartographer.md`
- Enter Inspector role → Read `references/inspector.md`
- Enter Operator role → Read `references/operator.md`

---

## Codex Tool Plan

Every Full Flow Test case must include `Codex-tool-plan`. The old `Operator-mode: A/B/C` field is legacy compatibility only and cannot replace the tool plan.

| Tool / plan item | Use for | Do not use for |
|----|----|----|
| **Browser Use** | Default for web UI feature testing: click, type, navigate, observe page state, collect screenshots, console/dialog evidence | Replacing Playwright repeatable regression scripts when stable reruns are needed |
| **Playwright Script** | Large flows, repeatable regression, trace, batch assertions, DOM/API/DB verification around UI-triggered behavior | Replacing user-trigger actions with direct API calls |
| **Browser Use + Screenshot Review** | Visual layout, Markdown/rendering fidelity, responsive checks, screenshot-based evidence | Declaring desktop layout bugs from small Codex window screenshots |
| **Computer Use** | OS-level or outside-browser actions: native file picker, download folder, desktop popup, cross-app movement | Clicking normal web buttons inside the page |
| **Supabase Verify** | Setup, schema discovery, test data creation, server_state verification when the project uses Supabase | Becoming the subject of the skill or replacing UI triggers |
| **API/Security Supplemental** | Authorization bypass, illegal state transition, XSS/API-level security supplement | Ordinary E2E trigger steps |

### Viewport Discipline

- Screenshot evidence must record viewport width/height and test intent.
- Desktop layout tests default to `1280x800` or `1440x900`.
- A Codex small-window screenshot cannot be used as direct desktop layout-failure evidence; mark it as `small-codex-viewport evidence`.
- Responsive conclusions must separate desktop / tablet / mobile evidence.

### Required TC Fields

- **`Codex-tool-plan`**: primary tool, supplemental tools, evidence to collect, and rationale.
- **`Viewport target`**: desktop/tablet/mobile size or "not layout-sensitive".
- **`Evidence to collect`**: screenshot, console, dialog, network, trace, server_state.
- **`Screenshot points`**: only when visual/rendering evidence is required.
- **`Operator-mode`**: optional legacy field; if present, it must not conflict with `Codex-tool-plan`.

Inspector reviews whether `Codex-tool-plan`, viewport evidence, and screenshot points are internally consistent. See `references/operator.md` and `templates/test-cases-template.md`.

---

## Agent Instance Isolation Rules (execution-time architecture)

The Full Flow roles are not just logical roles. **Inspector should run in an independent agent instance**,
which is the execution-layer guarantee for review independence.

### Inspector Must Run in Independent Agent Instance (mandatory)

**Reason**: Inspector's core value is "independent review of Cartographer's judgment"—
but if Inspector and Cartographer run in the same conversation,
Inspector has already "seen code / knows Cartographer's thinking process", **its independence is compromised**—
it will unconsciously defend Cartographer's design, significantly reducing review quality.

**Mandatory requirement**: After Cartographer phase 2 completes (and phase 3 revision completes), **must** tell the user to start an independent instance to run Inspector, **do not allow** directly switching roles in the original conversation.

**How to start an independent instance** (choose based on deployment environment):

| Environment | Recommended | Backup |
|------|--------|--------|
| **Codex / Claude Code** | Use subagent / Task tool to start new agent when the environment allows | Let user start new conversation |
| **API Call** | Initiate new conversation, system prompt guides entering Inspector role | — |
| **Claude.ai / Claude Desktop** | Let user start new conversation (regular users don't have subagent capability) | — |

**Input checklist for Inspector instance**:
1. Spec document (Cartographer phase 1 output + final version after human review)
2. Test case document (Cartographer phase 2 output + final version after phase 2.5 file decision completes)
3. Install codex-web-test skill, system will guide entering Inspector role

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

When a user requests testing a specific web feature, the agent enters **Coordinator / Test Lead** first:

1. Decide whether this is **Quick Feature Test** or **Full Flow Test**.
2. Clarify the feature name and scope (e.g., "user login", "password reset").
3. Confirm code location, target URL, dev-server command, viewport target, and allowed test data actions.
4. Select the Codex tool plan: Browser Use, Playwright Script, Screenshot Review, Computer Use, Supabase Verify, and/or API/Security Supplemental.

If any of the above is unclear, ask the user. Don't immediately start reading code.

Coordinator details are in `references/coordinator.md`; Full Flow Cartographer phase 0 is in `references/cartographer.md`.

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

**12. Codex-tool-plan**—
each Full Flow TC records the intended tool mix: Browser Use for web UI, Playwright Script for repeatable regression and traces, Screenshot Review for visual evidence, Computer Use only for OS-level actions, Supabase Verify only as setup/server_state support, and API/Security Supplemental for security probes.
See "Codex Tool Plan" above + `references/operator.md`.

**13. Viewport Discipline**—
each screenshot records viewport and intent. Desktop layout evidence defaults to `1280x800` or `1440x900`; small Codex-window screenshots must be marked as limited evidence.
See `references/coordinator.md` and `templates/execution-report-template.md`.

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

**Complex feature examples (chatbot, core)**—demonstrates Full Flow Test with Browser Use, Playwright Script, Screenshot Review, viewport evidence, and Coordinator Final Review:
- `examples/chatbot-spec-example.md` — Lightweight chatbot spec (dialog-style UI + async streaming + LLM agent + frontend rendering fidelity multi-mode overlay)
- `examples/chatbot-cases-example.md` — Corresponding test cases (`Codex-tool-plan`, viewport, complete Screenshot points)
- `examples/chatbot-execution-report-example.md` — Execution report example (viewport evidence + Playwright trace + Screenshot Review + Coordinator Final Review)

**Strongly recommended**: When Cartographer writes TCs involving frontend rendering fidelity in phase 2, **must read chatbot-cases-example.md**—
TC-002 inside is the standard example of combining Playwright Script with Screenshot Review.

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
