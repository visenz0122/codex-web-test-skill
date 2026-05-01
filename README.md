# Codex Web Test Skill

> A Codex skill for testing web applications with real browser evidence: quick feature checks when you just need confidence, and full spec-driven acceptance flows when the work matters.
>
> 一个面向 Codex 的网页功能测试 skill:小改动走快速真实浏览器验证,重要链路走规约驱动的完整验收测试。

## Why This Exists

Small teams and solo developers often skip proper E2E testing because writing good cases, setting up data, running browsers, and collecting evidence all take time. Codex can help, but only if the testing workflow is explicit about scope, tools, viewport, evidence, and post-test classification.

**Codex Web Test Skill** turns "test this feature" into a practical QA workflow inside Codex:

- Use **Browser Use** for real UI interaction.
- Use **Playwright Script** when a flow needs stable reruns, traces, or batch assertions.
- Use **Screenshot Review** for layout, Markdown, responsive, and rendering fidelity.
- Use **Computer Use** only for OS-level actions such as native file pickers, download folders, or desktop dialogs.
- Use **Supabase Verify** only as setup/schema/server-state support, not as the subject of the test.
- Separate product bugs from test script bugs, environment issues, tool limits, data pollution, and manual-review items.

## Two Test Modes

### Quick Feature Test

Use this when you changed one page, one button, one form, or one interaction and want fast confidence.

Typical flow:

1. Coordinator chooses Quick mode.
2. Codex reads only the necessary code/context.
3. Browser Use opens the target URL.
4. Codex records viewport, screenshots, console/dialog/network evidence.
5. Codex returns a compact result with findings and retest advice.

No full spec, no Inspector, no heavy ceremony.

### Full Flow Test

Use this for acceptance testing, multi-page flows, permission/data-heavy behavior, AI chatbot flows, or regression that should be repeatable.

Typical flow:

1. **Coordinator / Test Lead** chooses scope, mode, tools, viewport, evidence, and test-data policy.
2. **Cartographer** reads the code and writes the behavior spec.
3. Human reviews the spec.
4. Cartographer generates test cases with `Codex-tool-plan`, viewport targets, evidence points, setup, and teardown.
5. **Inspector** reviews the cases independently against testing methodology and Codex-specific constraints.
6. Human reviews the final cases.
7. **Operator** executes through Browser Use / Playwright / Screenshot Review / Computer Use / Supabase Verify as appropriate.
8. Coordinator writes the final review and classifies findings.

## What Makes It Codex-First

This is not a generic E2E prompt. It is tuned for how Codex actually works:

- **Viewport discipline**: desktop screenshots default to `1280x800` or `1440x900`; small Codex-window screenshots are marked as `small-codex-viewport evidence` and cannot be used as direct desktop-layout failure proof.
- **Tool routing**: Browser Use is preferred for web UI actions; Computer Use is reserved for browser-outside work.
- **Evidence-first reporting**: screenshots, console, dialogs, network, traces, server-state checks, and limitations are recorded explicitly.
- **Quick vs Full split**: simple feature testing stays lightweight; large acceptance flows keep full spec/test-case rigor.
- **Post-test classification**: findings are grouped into `product bug`, `test script bug`, `environment/setup issue`, `tool limitation`, `data pollution`, and `needs manual review`.

## Install

Choose the language edition you want and copy it into your Codex skills folder.

One-command local install:

```sh
scripts/install-local.sh zh
```

Chinese edition:

```sh
cp -R zh ~/.codex/skills/codex-web-test
```

English edition:

```sh
cp -R en ~/.codex/skills/codex-web-test
```

If your Codex home is customized:

```sh
cp -R zh "$CODEX_HOME/skills/codex-web-test"
```

Restart Codex or start a new Codex session so the updated skill list is loaded.

## Usage

Quick test:

```text
用 codex-web-test 测一下登录按钮，重点看错误提示和 console。
```

Full flow:

```text
用 codex-web-test 对 AI chatbot 做完整验收测试，包含 Markdown 渲染、流式输出、错误状态、截图证据和最终反馈分类。
```

Viewport-sensitive test:

```text
用 codex-web-test 检查这个页面桌面布局，必须用 1280x800 或 1440x900 的 viewport 截图，Codex 小窗口截图只能作为辅助证据。
```

## Repository Layout

```text
.
├── zh/                     # Chinese skill edition
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   ├── references/
│   ├── templates/
│   └── examples/
├── en/                     # English skill edition
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   ├── references/
│   ├── templates/
│   └── examples/
├── scripts/
│   ├── install-local.sh      # install zh/en edition into ~/.codex/skills
│   └── validate.sh           # static repository checks
└── README.md
```

Each edition is a complete Codex skill. Copy either `zh/` or `en/` into your Codex skills folder.

## Included Templates

- `spec-template.md`: behavior spec with Codex runtime info, target URL, dev-server command, test-data source, and viewport assumptions.
- `test-cases-template.md`: test cases with `Codex-tool-plan`, viewport targets, screenshot points, evidence plan, setup, teardown, and optional legacy `Operator-mode` compatibility.
- `execution-report-template.md`: execution report with viewport evidence, Playwright traces, Screenshot Review, console/dialog/network summary, failure classification, and Coordinator Final Review.
- `quick-test-report-template.md`: lightweight report for single-feature tests.
- `judge-output-template.md`: Inspector feedback format.

## Good Fits

- Login, signup, session, permission, and role-based flows.
- CRUD workflows where frontend display and backend state both matter.
- AI chatbot / agent interfaces with streaming, Markdown, tool calls, or prompt-safety checks.
- File upload/download flows where Browser Use and Computer Use need clear boundaries.
- Visual/rendering checks where small Codex window screenshots could otherwise cause false layout conclusions.

## Not A Fit

- Unit tests.
- Load/performance testing.
- Pixel-perfect visual regression testing.
- Security audits that require a dedicated professional security methodology.
- Pure API testing where no browser user path exists.

## Contributing

Issues and pull requests are welcome. Useful contributions include:

- New scenario patterns from real projects.
- Clearer tool-boundary rules for Browser Use, Playwright, Computer Use, Supabase, or API/security supplements.
- Better examples for common web app flows.
- Translation fixes between Chinese and English editions.
- Template improvements that make reports easier to act on.

When changing behavior, please update both `zh/` and `en/` editions when possible, then run:

```sh
scripts/validate.sh
```

## 中文简介

**Codex Web Test Skill** 是一个给 Codex 使用的网页测试 skill。它把"测一下这个功能"拆成两种模式:

- **Quick Feature Test**:适合按钮、页面、表单、局部交互、smoke test。默认用 Browser Use 做真实浏览器验证,记录 viewport、截图、console/dialog/network 证据,输出紧凑问题清单。
- **Full Flow Test**:适合完整验收、大型链路、权限/数据密集功能、AI chatbot、可复跑回归。它会生成规约、测试用例、Inspector 审查、Operator 执行报告和 Coordinator Final Review。

这个 skill 特别强调:

- Browser Use 是网页功能测试默认首选。
- Playwright Script 用于稳定复跑、trace、批量断言。
- Computer Use 只用于文件选择器、下载目录、桌面弹窗等浏览器外动作。
- Supabase Verify 只作为 setup/schema/server_state 辅助。
- 每张截图必须记录 viewport;Codex 小窗口截图不能直接当作桌面布局失败证据。

安装中文版本:

```sh
scripts/install-local.sh zh
```
