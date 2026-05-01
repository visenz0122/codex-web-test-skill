# 人类 Review 清单

这个 skill 流程里有两道**强制的人类 review**。
这份文档是给人类用户用的辅助清单——不是给 agent 看的。
agent 在到达 review 节点时,可以**展示这份清单的相关部分给用户**,帮助用户高效完成 review。

---

## Contents

- 第一道:规约 Review(阶段 1 完成后)
- 第二道:测试用例 Review(Inspector 反馈完成后)
- 暂停点的"通过"信号

---

## 第一道:规约 Review(阶段 1 完成后)

### 你在审什么

Cartographer 刚把代码翻译成了规约。你审的是:**规约描述的行为是否和实际产品一致**?

### Review 清单

**逻辑依据(优先看)**

规约里所有涉及代码归纳的字段(behaviors expected、invariants、boundaries、state machine)都有"逻辑依据"子字段。
**先读依据再看结论**——这能让你 30 秒审完一项,且能抓 LLM 的抽象错误。

- [ ] 每条 invariant / behavior expected / boundary / state machine 是否都有"逻辑依据"?(没有就要求补)
- [ ] 依据描述代码控制流(分支、条件)是否清晰?(不应是"代码逻辑保证此 invariant"这种空洞说法)
- [ ] 依据中的"可达性"判断是否正确?(如声称"fallback 不可达",你能否验证代码里 ALL_TOOLS 内容)
- [ ] **结论是否能从依据自然推出?**(经典误用:依据写"5 个分支,fallback 不可达",但结论用了 fallback 文案)
- [ ] 见到"结论修正"的标注不要慌——这说明 Cartographer 做了自我审查,反而是质量信号

**Interface 段**

- [ ] 路由列表里有没有遗漏或多余的路由?
- [ ] API endpoints 有没有遗漏或写错?
- [ ] 这些 routes 和 APIs 确实属于本功能,不是 Cartographer 误抓了无关代码?

**Behaviors 段**

- [ ] 每个 behavior 的"用户意图 → 系统行为"是否符合实际产品行为?
- [ ] 有没有重要的 behavior 漏写?
- [ ] preconditions 是不是合理(用户真的需要这个前置才能触发)?
- [ ] expected 的最终状态描述,是否和实际产品行为一致?

**Invariants 段(关键)**

- [ ] 安全 invariants 是否完备?(密码不在 URL / 日志里、token 安全生成等)
- [ ] **特别注意 cross_cutting_invariants 中的"等价行为"**——这通常是代码里看不见的安全设计,Cartographer 推断对了吗?有没有遗漏?
- [ ] 业务 invariants 是否完备?(数据一致性、计算正确性等)

**Hints 段**

- [ ] Boundary values 列出的字段是否都是相关的?有没有代码里有限制但 hints 里没列?
- [ ] Decision table 的条件组合是否符合业务实际?
- [ ] Out of scope 中的内容是否合理(确实是本期不测)?

**Source 标注和冲突标注**

- [ ] 所有易冲突字段(测试账号、API 路径、UI 文案、边界值)是否都有 *(来源: 文件:行号)* 标注?
- [ ] 见到 ⚠️ 冲突警告时,**重点确认**——Cartographer 发现了"代码 vs 文档"的不一致,需要你拍板用哪个

**Scenario Patterns 标注**

规约的 `## 4. Scenario Patterns` 字段标注了本功能匹配哪些场景模式。
**这个标注的准确性直接影响阶段 2 生成什么用例**——错标或漏标会导致后续覆盖度偏差。

- [ ] Cartographer 标的场景模式是否符合本功能的实际特征?
- [ ] 每个匹配的模式都有具体的"匹配理由"吗?(不是"涉及对话"这种模糊话)
- [ ] **有没有漏标的模式?** 简单对照常见模式:
  - 涉及登录态 / token → 用户认证 / 会话管理
  - 多角色 / 资源隔离 → 多租户 / 权限矩阵
  - 流式输出 / SSE / 长轮询 → 异步 / 流式输出
  - 后端调 LLM → LLM agent 决策
  - 文件上传/下载 → 文件上传 / 下载
  - 几乎任何功能 → 异常路径(通用)
- [ ] "不匹配但容易误判"的模式说明合理吗?

漏标比错标更危险——错标你通常能看出来,漏标会让阶段 2 不为该模式生成用例,而你很难感觉到"少了"。

### 发现问题怎么办

- 告诉 agent "改第 X 段的 Y 描述",agent 会修改后再交给你
- 不是改完一处就进下一阶段;**所有问题改完了再说"通过"**
- 明确说"通过"后 agent 才进入阶段 2(用例生成)。常见的确认词:"通过"、"OK"、"继续"、"approved"、"proceed"

### 不熟悉某些技术细节怎么办

- "Verifiable via" 字段(server_state 怎么验证)看不懂可以问 agent 解释
- 边界值列表里某些具体数字不确定的可以让 agent 标注"代码出处行号"再确认
- 不确定 invariants 是太严格还是太松,可以直接说,让 agent 调整

---

## 第二道:测试用例 Review(Inspector 反馈完成后)

### 你在审什么

Cartographer 已经基于规约生成了用例,Inspector 也审了一轮。你审的是:

1. **完整性**:用例是否覆盖了实际页面上所有重要控件和交互?
2. **Cartographer 的 rationale 是否合理**:对 Inspector 提的 P1 但 Cartographer 决定不修的项,理由是否站得住?
3. **场景模式自检表的真实性**:Cartographer 标的 ✓ / ⚠ / ✗ 对应的理由和代码依据是否可信?

### Review 清单

**Scenario Pattern Coverage Self-Check**

打开用例文档的 `## Scenario Pattern Coverage Self-Check` 段。**对每个匹配模式的每一项**:

- [ ] **✓ 项**:打开它声称对应的 TC——这个 TC 是不是真的覆盖了这个清单项?(不是"碰巧用到")
- [ ] **⚠ 项**:理由是否具体?是否能让你独立判断"这个理由站得住"?
  - 好理由:"工具 X 不支持精确触发 IME 半成品状态,需要 Playwright 补"——具体可验证
  - 差理由:"不重要"、"本期不测"——驳回,要求重写
- [ ] **✗ 项**:代码依据是否具体引用文件:行号 + 控制流逻辑?
  - 好依据:"router.js:88 用 POST body,不经过 URL,该清单项不可能发生"——可对照代码验证
  - 差依据:"代码不支持"——驳回,要求具体位置
- [ ] 你能否对照代码直接验证 ✗ 项的依据?如果能,**抽查 1-2 个**确认一下

> 人类比 Inspector 更擅长这道审查——**因为你能看代码**。
> Inspector 只能审查"理由是否逻辑自洽",不能验证"代码事实是否真如此"。

**完整性(页面 vs 用例)**

打开实际页面,对照用例文档:

- [ ] 页面上每个**输入框**是否都有对应的用例?
- [ ] 页面上每个**按钮**是否都有对应的点击用例?
- [ ] 页面上每个**链接 / 跳转**是否都有对应的用例?
- [ ] **状态转换**(如已登录/未登录、加载中/加载完)的不同视图是否都覆盖?
- [ ] 错误提示信息(各种失败情况下的 toast / banner)是否都有用例覆盖?

> 这部分 Inspector 做不了——Inspector 不看实际页面,只看用例和规约。
> 你是唯一能做"页面 vs 用例"对比的角色。

**Codex 工具计划和 viewport**

打开每个重要 TC 的 `Codex-tool-plan` / `Viewport target` / `Evidence to collect`:

- [ ] 普通网页功能是否优先用 Browser Use,而不是用 Computer Use 代替网页点击?
- [ ] 需要可复跑的大型链路是否有 Playwright Script 或 trace 计划?
- [ ] Computer Use 是否只用于系统文件选择器、下载目录、原生弹窗、跨 App?
- [ ] Supabase Verify 是否只用于 setup / verify / teardown,没有作为普通功能 trigger?
- [ ] 安全绕过 UI 的测试是否单独标为 API/Security Supplemental?
- [ ] 所有视觉/布局截图是否记录 viewport?
- [ ] 如果截图来自 Codex 小窗口,是否标注 `small-codex-viewport evidence`?
- [ ] 是否有把小窗口下的折叠导航/表格换行误判为 desktop bug 的风险?

如果桌面布局很重要,但当前证据来自小窗口,要求 agent 增加 desktop viewport 复测或把结论降级为"needs manual review"。

**Rationale 合理性(看 Inspector Feedback Log)**

打开用例文档的 `Inspector Feedback Log` 段,逐条检查:

- [ ] 每条"不采纳"的 P0/P1,是否有 rationale?
- [ ] rationale 是否**具体**(不是"不需要"、"价值不高"这种敷衍)?
- [ ] rationale 中引用的事实你能否确认(如"代码用了 ORM")?(不能确认就让 agent 提供证据)
- [ ] 你是否同意 Cartographer 的判断?

**主/备/异常路径覆盖**

看用例文档顶部的 Coverage Summary 表:

- [ ] 主路径数量合理(每个 behavior 一般 1 条)
- [ ] 异常路径足够(网络错误、权限错误、资源错误都有覆盖吗?)
- [ ] 备选路径没漏(比如登录有 SSO 选项,SSO 用例不能少)

### 发现问题怎么办

如果发现完整性问题:
- 告诉 agent "页面有 X 控件没覆盖,加一个用例"
- agent 会补上后再次提交确认

如果发现某条 Cartographer 的 rationale 不合理:
- 告诉 agent "我不接受 P1-X 的不修 rationale,理由是 Y"
- agent 会要么修这个用例,要么重写 rationale

**所有问题都通过后**,明确说"通过"、"go run tests"等,让 agent 进入 Operator 阶段。

---

## 暂停点的"通过"信号

整个 skill 流程中有几处 agent 必须暂停等你的点:

| 暂停点 | agent 在等什么 | 你说什么继续 |
|------|------|------|
| 规约 review 后 | Cartographer 等你审规约 | "通过" / "OK" / "继续" 或类似 |
| Inspector 反馈后 | Cartographer 等你审用例 | 同上 |
| Operator 跑完后 | Operator 等你看报告 | 通常是最终,不需要"继续" |

如果你说"修改 X、Y 段"等,agent 会修改后再次提交,**等你下一次确认**——不会自动跑下去。
