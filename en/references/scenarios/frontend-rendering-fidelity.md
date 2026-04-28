# Frontend Rendering Fidelity

## Applicable Scope

Any functionality involving "backend data → frontend display". **Key distinguishing factor**: functionality has "data rendered by frontend for user to see" action.

Specific scenarios:

- Any functionality displaying user input (messages, comments, articles, usernames, etc.)
- Any functionality displaying backend timestamps (creation time, update time, activity calendar)
- Any functionality displaying numbers / currency (amount, count, percentage, statistical charts)
- Any functionality displaying Markdown / rich text / HTML content
- Any functionality displaying multilingual characters / emoji / special symbols
- Any functionality that truncates / highlights / summarizes long text
- Any functionality displaying files / images / links
- Any "real-time formatting" functionality ("3 minutes ago", "just now", "yesterday" relative time)

**Core problem**: in these scenarios, correct backend data ≠ correct user view—frontend rendering layer may lose, escape, format incorrectly.
Backend engineers testing backend API cannot see this kind of bug; frontend engineers testing UI easily miss detail differences; **only E2E testing seeing both sides can catch it**.

## Mandatory Checklist

### Markdown / Rich Text Rendering

- Bold / italic / underline: `**bold**` / `*italic*` whether generates `<strong>` / `<em>` element
- Heading: `# H1` to `###### H6` whether generates corresponding level heading
- List: ordered / unordered list / nested list whether correctly indented
- Code block: code wrapped in ` ``` ` whether has syntax highlighting / monospace font
- Inline code: `` `code` `` whether generates `<code>` element
- Link: `[text](url)` whether generates clickable `<a>` tag + target correct
- Image: `![alt](src)` whether generates `<img>` + alt text accessible
- Table: Markdown table whether rendered as HTML table
- Quote block: `> quote` whether generates `<blockquote>`
- Divider: `---` whether generates `<hr>`

### HTML Escape Safety

- **Script injection protection**: input `<script>alert(1)</script>` should display as literal string, **not** execute
- **Attribute injection protection**: input `<img src=x onerror=alert(1)>` should be filtered or escaped
- **Link protocol whitelist**: dangerous protocols like `javascript:` / `data:` whether rejected
- **Preserve HTML entity**: user input `&amp;` should display as `&` (not `&amp;` literal), provided this is expected behavior

### Time / Timezone

- **UTC → local timezone**: backend stores UTC, does frontend display according to user timezone correctly
- **DST switch**: is time display correct on daylight saving time switch day
- **Cross-date boundary**: when backend timestamp near local midnight, is date correct (not display previous/next day)
- **Relative time** ("3 minutes ago" / "just now" / "yesterday"): is calculation logic correct, are critical points accurate
- **Time format** (YYYY-MM-DD HH:mm vs YYYY/MM/DD etc.): does it match user locale setting

### Numbers / Currency

- **Thousands separator**: 1234567 → "1,234,567" whether effective
- **Decimal precision**: 12.3456 display how many digits? does retained digits match expectation (finance usually 2)
- **Number truncation / rounding**: 1234.567 display as "1234.57" or "1234.56"? is precision lost
- **Currency symbol**: "¥" / "$" / "€" whether correct, position (before / after) whether correct
- **Large number abbreviation**: 1000000 display as "1M" / "100万" etc.
- **Percentage**: 0.1234 display as "12.34%" or "0.1234%"
- **Scientific notation**: extreme large / small number handling

### Character Encoding

- **emoji**: 🎉 whether correctly displayed (not ?? or block)
- **emoji combination**: 👨‍👩‍👧‍👦 (family emoji, ZWJ sequence) whether complete, not split into multiple characters
- **CJK characters**: Chinese Japanese Korean characters whether display normally
- **Special symbols**: ① ② ③, superscript/subscript, mathematical symbols
- **Zero-width characters** (U+200B etc.): whether correctly handled (display as zero-width / or filtered)
- **Right-to-left text** (Arabic / Hebrew): whether direction correct
- **Combining characters** (such as ñ = n + combining tilde): whether correctly displayed

### Long Text Handling

- **Truncation display**: is ultra-long string correctly truncated (not exceed container width)
- **Ellipsis position**: is truncation mark "..." at suitable position (end / middle / smart)
- **Access complete version after truncation**: can click / hover / expand to see full content
- **Multi-line wrapping**: do long words / URLs stretch container
- **CSS overflow**: scroll / hidden / ellipsis whether match expectation

### Data Formatting Conversion Functions (prone to bugs)

- **JSON.stringify / parse**: nested object / array / null handling
- **Boolean display**: true/false display as "yes/no" / "✓/✗" / "true/false"—whether consistent
- **Empty value handling**: null / undefined / empty string display as "—" / "(empty)" / blank—whether consistent
- **Array / object rendering**: array [1,2,3] display as "1, 2, 3" or "[1,2,3]" or display per item

### Real-time Calculation / Dynamic Fields

- **Counter update**: when list new add/delete, does top counter (like "total X items") sync update
- **Statistic field**: total / average / ratio etc. real-time calculation whether accurate
- **Status badge**: when data status changes, does UI badge sync switch
- **Progress bar**: when value changes, do percentage / progress bar / color sync

## How to Test (must combine backend verify + Agent screenshot judgment)

**Core principle**: **both frontend and backend must be observed and compared simultaneously**. Single-side assertion cannot catch this kind of bug.

### Recommended Operator-mode: C (Hybrid Mode)

TCs matching this scenario pattern **almost all should mark Operator-mode: C**—
because rendering fidelity simultaneously needs "backend data correctness" (Playwright precise SQL/API assertion) and "frontend rendering visual judgment" (LLM read screenshot semantic understanding).
Pure Playwright using DOM selector to check `<strong>` / `<h1>` element can catch part of bugs, but **cannot catch these**:

- Is emoji displayed as block / question mark (emoji character in DOM, but actual rendering failed, font not supported)
- Time text "2026-04-26 18:00" looks right, but **does not match current user timezone** (DOM cannot determine "right or not")
- Does number thousands separator conform to user locale setting (`12,345.67` vs `12.345,67`, DOM all string)
- Markdown rendered but style lost (`<strong>` element exists but font not bold, because CSS ineffective)
- Long text overflow bubble boundary (DOM complete, but visually text penetrated UI container)
- RTL text direction, CJK character spacing, emoji combination characters (👨‍👩‍👧‍👦) split character etc.

**These all need Agent read screenshot to judge**—LLM visual understanding good at this kind of "looks right or not" semantic problem.

### Test Case Expected + Screenshot Points Format

```yaml
TC-XXX: test send Markdown message rendering

Operator-mode: C  # hybrid mode

Steps:
  1. Browser input "**important**\n# title" in textarea
  2. Click send button
  3. Wait for SSE stream to complete

Screenshot points:
  - after_step: 3  # after SSE stream complete
    save_to: screenshots/TC-XXX-after-send.png
    llm_judges:
      - "Is **important** in bubble rendered as bold (font obviously thicker than body text)?"
      - "Is # title in bubble rendered as large header (font obviously larger than body text)?"
      - "Is overall bubble layout normal, text completely visible (no overflow, no truncation)?"

Expected:
  - Backend fact (SQL): messages.content = "**important**\n# title" (raw Markdown string)
  - Frontend rendering (browser): .bubble[data-id=X] contains <strong> and <h1> element
  - Visual assertion: see llm_judges in Screenshot points
```

### Agent Screenshot Judgment Working Mechanism

Refer to SKILL.md "Operator Hybrid Execution Mode" and `references/operator.md` §2.C:

1. **Playwright phase**: Cartographer generates Playwright script, Operator runs business workflow,
   after step specified in `Screenshot points` call `await page.screenshot({path: '...'})` to save screenshot
2. **LLM post-processing**: after Playwright completes, Operator (LLM) reads saved screenshot,
   output judgment (✅ / ❌ + brief description) for each `llm_judges` question
3. **Merged report**: Playwright trace + LLM screenshot judgment both written to execution-report,
   **any failure = TC combined FAILED**

### llm_judges Writing Requirement

Each judgment question must **be concrete and independently answerable**—LLM after reading screenshot can directly give ✅ / ❌:

| ❌ Abstract question (LLM cannot answer accurately) | ✅ Concrete question (LLM can directly judge) |
|---|---|
| "Is rendering correct?" | "Is **important** in bubble rendered as bold font?" |
| "Is UI reasonable?" | "Is overall bubble layout normal, no text overflow?" |
| "Does it look right?" | "Does timestamp display match 'YYYY-MM-DD HH:mm' format?" |
| "Is Markdown rendered?" | "Does # title generate large header element (font obviously larger than body text)?" |

The more concrete judgment question written, the more accurate LLM judgment—**do not write abstract meta-question**.

### Execution Report Recording Method

Execution report (`templates/execution-report-template.md`) has two dedicated sections:

- **Playwright trace summary**: record Playwright part PASSED / FAILED assertion + trace.zip path
- **LLM screenshot judgment**: per screenshot + per llm_judges question ✅/❌ + description
- **Frontend-backend data comparison** (optional): backend value vs frontend rendering value + whether consistent (further assist attribution)

## Key Reminders

**This kind of bug especially hard to catch in production**—backend testing cannot see, frontend unit testing easily miss boundary cases (emoji, timezone switch, long text).
**E2E testing is most should catch this kind of bug level**, so this scenario pattern must proactively apply.

**Agent screenshot judgment is irreplaceable**—most items of this scenario pattern mandatory checklist **can only be judged by LLM reading screenshot**.
DOM selector query `<strong>` / `<h1>` element can catch "is it rendered" level bugs, but cannot catch "is it rendered correctly"—
- Is font bold (CSS ineffective but DOM element exists, Playwright passes)
- Is emoji displayed as block (DOM is emoji character, font not supported)
- Does time display conform to user timezone (DOM is string, Playwright cannot determine "correct or not")
- Does long text overflow bubble (DOM complete, but visually penetrated container)

**So TC matching this scenario pattern almost inevitably is Operator-mode: C**—Playwright runs business workflow for backend assertion,
Agent reads screenshot for visual judgment. See above "How to Test" section.

**Do not assume "frontend framework handles these"**—React / Vue does not auto-render Markdown, not auto-convert timezone,
not auto-format thousands separator, these all application-layer logic, **may all have bugs**.

**Test data must include boundaries**:
- String test use emoji, zero-width character, ultra-long text, HTML tag character
- Timestamp test use near midnight, DST switch day, cross-year
- Number test use 0, negative, extreme large, decimal, Infinity
- Test not only "happy path", must test "weird stuff users actually input"

## Common Overlaps

Usually appears together with these patterns:
- **Dialog-style UI** (message rendering, Markdown, timestamp display almost always need test)
- **CRUD list and detail** (list item display, detail field rendering)
- **Profile / profile management** (username, avatar alt, registration time display)
- **LLM agent decision** (LLM output Markdown / code block rendering)
- **State transition** (status badge, status text switch)

Almost all "display data to user" functionality should match this pattern—
like "exception path (universal)", this is a **almost always add** pattern.

## Not Applicable Cases

- Pure input functionality, no data echo (such as pure write API, backend confirmation enough)
- Pure static display page (no dynamic data, content hard-coded in code)
- Pure client_state operation (such as switch tab midway in form, no server data display)
