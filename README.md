# spec-test.skill

> A skill that helps small teams and individual developers run rigorous end-to-end tests on web applications, using a specification-based testing methodology.
>
> 一个 skill,帮助小团队和个人开发者用规约驱动测试(specification-based testing)的方法对 web 应用做严谨的端到端(E2E)测试。

---

## English

### What this skill does

`spec-driven-test` turns "write some E2E tests" into a disciplined three-stage workflow run by three cooperating Claude agents, with two human review gates in the middle:

1. **Cartographer** reads your code and produces a written **spec** of the feature under test, then translates that spec into concrete **test cases**.
2. **Inspector** reviews those test cases against established testing methodologies (boundary value analysis, equivalence partitioning, decision tables, state transition, use case testing, Right-BICEP) and a checklist of common scenario patterns, returning P0 / P1 / P2 graded feedback.
3. **Operator** drives a real browser (Playwright or Claude in Chrome) to execute every test case and produce an evidence-backed execution report with screenshots.

Two human review checkpoints (one after the spec, one after the test cases) keep a person in the loop on the things that matter — *is the spec actually right?* and *are these the tests we want to run?* — without making humans do the busywork.

### Why it exists

E2E testing is the layer most often skipped by small teams and individual developers because writing good tests by hand is slow, and "vibe-coded" tests miss the unhappy paths. This skill is designed to give a single developer the rigor of a dedicated QA process: structured specs, methodology-driven test design, real-browser execution, and a reproducible report — without needing a separate QA team.

### Two language editions

This repository ships the skill in two editions. They are content-equivalent — pick whichever language your team works in.

| Edition | Path | Use when |
|---|---|---|
| **Chinese (中文)** | [`zh/`](./zh) | Your team writes specs and reviews in Chinese, or your codebase comments are mostly Chinese. |
| **English** | [`en/`](./en) | Your team works in English, or you want to share the skill with international collaborators. |

Each edition contains the full skill: `SKILL.md`, `references/` (the agent rulebooks, methodology references, and scenario patterns), `templates/`, and `examples/`.

### How to install

To use this skill in Claude Code or Cowork, copy the edition you want into your skills folder. For example:

```sh
cp -r en /path/to/your/skills/spec-driven-test
```

Or zip the edition's folder into a `.skill` bundle and upload via the Cowork skill installer.

### Contributing — feedback and improvements are very welcome

This skill is a living document. **If you have a reasonable suggestion, we will adopt it.** That includes — but is not limited to:

- Bugs you hit while running the workflow on a real project
- Wording that is unclear, ambiguous, or wrong
- Missing scenario patterns (e.g. you tested a feature whose pattern wasn't covered)
- Methodology references that are inaccurate or could be clearer
- Translation issues in either edition (English ↔ Chinese parity)
- New examples drawn from real projects
- Improvements to the templates

**How to contribute:**

- **Report a usage issue or bug**: open a GitHub Issue. Tell us what you were testing, which agent you were running, what happened, and what you expected. Logs or transcript snippets help a lot.
- **Suggest an improvement**: open an Issue with the `enhancement` label, or open a Pull Request directly.
- **Submit a translation fix**: PRs welcome — please update *both* `zh/` and `en/` so the two editions stay in sync.
- **Add a real-world example**: PRs welcome under `zh/examples/` and `en/examples/`.

We're a small project. Reasonable feedback and PRs from anyone are appreciated and will be taken seriously.

### License & questions

If you have a usage question that isn't a bug, please still open an Issue — odds are someone else has the same question.

---

## 中文

### 这个 skill 是做什么的

`spec-driven-test` 把"写点 E2E 测试"这件事拆成一套严谨的三阶段流程,由三个 agent 协作完成,中间还有两道人类 review 把关:

1. **Cartographer(制图师)** 读你的代码,产出被测功能的**规约**(spec),再把规约翻译成具体的**测试用例**。
2. **Inspector(检查员)** 用一套测试方法论(边界值分析、等价类划分、决策表、状态迁移、用例测试、Right-BICEP)和场景模式清单审查测试用例,输出 P0 / P1 / P2 分级反馈。
3. **Operator(执行员)** 在真实浏览器里(Playwright 或 Claude in Chrome)跑每一条测试用例,产出附带截图证据的执行报告。

两道人类 review(一道在规约后,一道在用例后)把"规约是不是对的"和"这些用例是不是我们想要的"这种关键判断留给人,但所有繁琐工作都交给 agent 做。

### 为什么要有这个 skill

E2E 测试是小团队和个人开发者最容易跳过的一层——手写好测试太慢,"凭感觉测一下"又会漏掉异常路径。这个 skill 想让一个独立开发者也能享有一个完整 QA 流程的严谨度:结构化规约、方法论驱动的用例设计、真实浏览器执行、可复现的报告——而不需要专门搭一支 QA 团队。

### 两个语言版本

这个仓库提供中英两个内容等价的版本,按你团队的工作语言选一个就行。

| 版本 | 路径 | 适用场景 |
|---|---|---|
| **中文** | [`zh/`](./zh) | 团队用中文写规约和评审,或代码注释多数是中文。 |
| **English** | [`en/`](./en) | 团队用英文工作,或者要把 skill 分享给国际协作者。 |

每个版本都是完整 skill:`SKILL.md`、`references/`(三个 agent 各自的规则手册、方法论、场景模式参考)、`templates/`、`examples/`。

### 怎么安装

要在 Claude Code 或 Cowork 里用这个 skill,把对应版本目录复制到你的 skills 目录,例如:

```sh
cp -r zh /path/to/your/skills/spec-driven-test
```

或者把对应版本目录打成 `.skill` zip 包,通过 Cowork 的 skill 安装界面上传。

### 贡献 —— 任何合理意见都会采纳

这个 skill 是活文档。**只要是合理的反馈和建议,我们都会认真考虑并采纳。** 包括但不限于:

- 你在真实项目里跑这套流程时踩到的 bug
- 表述不清楚、有歧义或者直接写错的地方
- 缺失的场景模式(比如你测了某个功能,发现现有模式没覆盖到)
- 方法论参考有不准确或可以更清晰的地方
- 中英两个版本之间的翻译不一致
- 来自真实项目的新示例
- 模板的改进建议

**怎么贡献:**

- **反馈使用问题或 bug**:提 GitHub Issue。告诉我们你在测什么、当时跑的是哪个 agent、发生了什么、你期望发生什么。能附日志或对话片段最好。
- **提改进建议**:开一个 Issue 标 `enhancement`,或者直接发 Pull Request。
- **修翻译**:欢迎 PR——请同时改 `zh/` 和 `en/`,保持两个版本同步。
- **加真实案例**:欢迎 PR 到 `zh/examples/` 和 `en/examples/`。

这是个小项目。来自任何人的合理反馈和 PR 都会被认真对待。

### 用法问题

如果你有使用上的疑问,不是 bug,也请开 Issue——大概率别人也有同样的问题。
