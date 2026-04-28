# Dialog-Style UI

## Applicable Scope

"Input field + send + message history" pattern:

- Chat / customer service window
- AI assistant / chatbot
- Comment + reply
- Instant messaging (IM)
- Forum / post discussion
- AI agent conversation interface

**Key distinguishing factor**: user repeatedly sends messages through input field, system output and message history displayed together.
Characteristics are "multi-turn, has history, strong interaction".

## Mandatory Checklist

### Input Boundaries (text accepted by input field)

Test what content the input field accepts:

- **Normal text**: Chinese, English, mixed Chinese-English
- **Emoji / special symbols**: 🎉, various emoji combinations
- **Punctuation**: full-width punctuation, half-width punctuation, mixed
- **Zero-width / invisible characters**: U+200B, U+FEFF etc.
- **Ultra-long text**: paste entire article (check truncation or rejection behavior)
- **Whitespace**: pure spaces, pure line breaks, Tab character
- **Very short**: 1 character, single punctuation

### IME Input Method Status (Chinese / Japanese / Korean)

This is **most easily overlooked** category:

- **IME incomplete state**: pressing Enter in candidate word floating window, will it mistakenly send pinyin / kana incomplete state
- **Pressing Backspace during IME candidate selection**: is behavior as expected
- **Pasting content with IME status from other applications**

### Send Behavior

- **Enter to send vs Shift+Enter to newline**: is behavior as expected and consistent with placeholder text
- **Double-click send button**: prevent double-send, send only once
- **Press Enter twice in succession**: prevent double-send, send only once
- **Click send when network disconnected**: enter unsent queue? directly error?

### Multi-turn Context

- **Second turn referencing first turn**: using "it", "just now that", pronouns, can system parse correctly (especially for LLM agent)
- **Truncation strategy when message history is ultra-long**: is critical information lost
- **Scroll / performance of ultra-long conversation**: is UI still smooth when history messages many

### Midway Modification

- **Paste large block of text halfway through input**: is it correctly accepted
- **Switch to other tab halfway through input then come back**: is input field content retained
- **Browser refresh halfway through input**: is draft recovered (if this feature exists)
- **Modify unsent content**: delete part / rewrite

### Session Recovery

- **Switch tab away then come back**: is streaming output resumed / resumed
- **Browser closed then reopened**: is history still there (depends on server storage)
- **Session expires midway**: user inputting halfway when session expires, how to handle

### Undo / Edit sent message (if exists)

- **Undo time window**: how long after send can undo
- **Version display after edit**: before edit vs after edit, how does UI distinguish
- **Reference of edited message**: when already-replied message edited, does reference still point to original content

### Injection-related (when conversation content will be stored or reflected)

- **HTML tag**: is input `<script>` escaped
- **Markdown XSS payload**: `[click](javascript:alert(1))` etc.
- **Protocol string forgery**: input `__SYSTEM__:` / `__CONFIRMED__:` business protocol strings
- **URL injection**: input malicious URL

## Key Reminders

**"Equivalence class" of dialog-style UI is completely different from login form**.
- Login's equivalence class revolves around "whether account exists / whether password correct"
- Dialog's equivalence class revolves around "input character type / input timing / input length"

Don't copy login's EP thinking to dialog—will write large number of meaningless "Chinese / English / number" equivalence class test cases.

**IME status is very difficult to precisely trigger under automated testing tools**—most browser automation tools (Playwright, Claude in Chrome)
cannot simulate IME incomplete state. If test case must test this, usually needs to mark manual_upload (let human manually test once).

**Multi-turn context is core ability test of LLM agent**—don't only test single Q&A.

## Common Overlaps

Usually appears together with these patterns:
- Async / streaming output (dialog-style UI almost always has streaming)
- LLM agent decision (if AI conversation)
- User authentication / session management (conversation history bound to user)
- Multi-tenant / permission matrix (can only see own conversation history)
