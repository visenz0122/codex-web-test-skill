# Scenario Patterns (Index)

## What is this

Methodologies (EP/BVA/Decision Table etc.) tell you **"how thorough to test"** — they're measurement standards for coverage.
But EP for login is completely different from EP for dialog — **different scenarios have different check points**.

Scenario pattern library is **"this class of feature should especially test what" checklist**, orthogonal to methodologies, jointly determining test coverage.

## How to Use

### Cartographer Phase 1 End

Identify which scenario patterns feature matches, write in spec's `## 4. Scenario Patterns` field.
Each pattern can stack (dialog LLM agent typically matches 4-5).

### Cartographer Phase 2

For each matched pattern, **open corresponding file** read mandatory checklist, **judge each item**:

- ✓ applicable and tested → self-check table ✓ + corresponding TC
- ⚠ applicable but not tested → self-check table ⚠ + specific rationale
- ✗ not applicable (impossible at code level) → self-check table ✗ + code basis

### Inspector

Don't "independently create checklist", **review Cartographer's self-check table** (completeness, reasoning specifics, code consistency).

See `references/inspector.md` step 1.5.

## Pattern Overview

First version 11 patterns (extensible):

| Pattern | One-sentence description | File |
|---|---|---|
| Form Input | "Fill form + submit" type: login, signup, profile submit, password reset | `form-input.md` |
| User Authentication / Session | User identity establishment, maintenance, termination | `auth-and-session.md` |
| User Profile / Profile Management | Read display user profile + edit save | `profile-management.md` |
| CRUD List & Detail | Resource management: articles / orders / products / tasks / comments | `crud-list-detail.md` |
| Multi-tenant / Permission Matrix | User, role, resource isolation | `multi-tenant-permissions.md` |
| Dialog UI | Chat box, customer service window, AI agent dialog, comment reply | `dialog-ui.md` |
| Async / Streaming Output | Request → wait → progressive: SSE, WebSocket, streaming LLM | `async-streaming.md` |
| LLM Agent Decision | Backend calls LLM for decision, generation, dialog, tool call | `llm-agent-decisions.md` |
| File Upload / Download | File input or file output | `file-upload-download.md` |
| State Transition | System switches between states: orders, token lifecycle, approval flow | `state-transitions.md` |
| **Frontend Rendering Fidelity** | **Backend data correct but frontend render wrong** (Markdown / timezone / emoji / encoding / number format) | `frontend-rendering-fidelity.md` |
| Exception Paths (Universal) | Any feature should ask: network, 5xx, rate limit, timeout | `exception-paths.md` |

## Identification Tips

Read spec Behaviors, ask yourself:

- "Input fields + submit" action? → form input
- Involves login state / token / session? → user authentication / session management
- "Read + edit save" user profile? → user profile / profile management
- List / detail / CRUD? → CRUD list & detail
- Multiple roles / resource isolation? → multi-tenant / permission matrix
- Chat / comment / input box + message history? → dialog UI
- Backend streaming / SSE / WebSocket / long polling? → async / streaming
- Backend calls LLM for decision / generation / dialog? → LLM agent decision
- File upload / download? → file upload / download
- Explicit state machine? → state transition
- **Display backend data to user (any form: text / time / number / Markdown / rich text) → frontend rendering fidelity** (almost always add)
- **Any non-static-only feature → exception paths (universal)** (almost always add)

Can stack. Dialog LLM agent typically matches: dialog UI + async streaming + LLM agent decision + frontend rendering fidelity + exception paths.

## Add New Pattern

If in practice discover new scenario type (e.g. "real-time collaborative editing", "blockchain transaction", "image recognition"), add by:

1. Pick concise name (2-4 words)
2. Create new `.md` file in `scenarios/` directory
3. File structure per existing pattern files: applicable scope / mandatory checklist / key tips
4. Add one row in this `index.md` table
5. No need change anything else — Cartographer and Inspector auto-read latest version in this directory
