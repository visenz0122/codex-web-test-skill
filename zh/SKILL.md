---
name: codex-web-test
description: Codex 专用的网页功能测试和验收测试 skill。当用户说"测一下这个功能"、"检查这个页面"、"验证这个改动"、"做 E2E/验收测试"、"用 Browser Use/Computer Use 测网页"或提到 codex-web-test / spec-driven-test 时使用。小范围默认 Quick Feature Test;大型链路默认 Full Flow Test。强调 Browser Use / Playwright Script / Computer Use 边界、viewport 证据纪律、截图/console 证据、测试数据 setup/teardown 和测试后反馈分类。
---

# Codex Web Test

Codex-first 的 web 功能测试 skill。

它保留规约驱动测试的严谨性,但不再把所有请求都强行拉进重流程:
- **Quick Feature Test**:单功能快速验证,用 Browser Use 做真实浏览器测试,输出截图/console/问题反馈。
- **Full Flow Test**:大型链路或验收测试,由 Coordinator 统筹,Cartographer 生成规约和用例,Inspector 独立审查,Operator 执行,Coordinator 最后整理反馈。

核心目标:在 Codex 里把"测一下"变成可复现、有证据、能落地修复的功能测试结果。

---

## 按需加载导航(执行 skill 前先读这段)

这个 skill 是文件型 skill,你**不需要一次性读完所有 reference 文件**——按角色和阶段读对应章节,可大幅节省 token。

**确定你的角色,只读对应主文件**:

- **Coordinator / Test Lead 角色** → 读 `references/coordinator.md`
  + 进入任何测试请求时先读
  + 判断 Quick Feature Test 还是 Full Flow Test
  + 选择 Codex 工具组合,管理 viewport 证据,最后整理反馈
- **Cartographer 角色** → 读 `references/cartographer.md`(分阶段读章节,详见该文件顶部 TOC)
  + 阶段 0 / 1 / 2 / 2.5 / 3,只读当前阶段章节
  + 阶段 1 末尾识别匹配的场景模式后,**只读匹配的** `references/scenarios/<对应文件>.md`,不要全读
  + 写规约时读 `templates/spec-template.md`,写用例时读 `templates/test-cases-template.md`
- **Inspector 角色** → 读 `references/inspector.md`(分步骤读章节,详见该文件顶部 TOC)
  + 工作流程 §1 / 1.5 / 1.6 / 1.7 / 1.8 / 2 / 2.5 / 3 / 4
  + 选用方法论时**只读匹配的** `references/methodologies/<对应文件>.md`,不要全读
  + 输出格式时读 `templates/judge-output-template.md`
- **Operator 角色** → 读 `references/operator.md`,产出报告时读 `templates/execution-report-template.md`

**人类 review 阶段** → 读 `references/human-review-checklists.md`

**读 SKILL.md 本身只是入口**——它是导航,不是详细规则。
真正的工作规则在每个 agent 的 reference 文件里,**按需读取**才能控制 token。

---

## Codex 测试模式

### Quick Feature Test

适用于单功能、局部交互、刚改完功能后的快速验证。默认不生成完整 spec / test cases / Inspector 反馈。

```
用户指定功能
        ↓
Coordinator 判断为 Quick
        ↓
读必要代码 + 确认服务/URL
        ↓
Browser Use 打开页面 + 记录 viewport
        ↓
真实用户路径测试 + 截图/console/dialog 证据
        ↓
Coordinator 输出问题分类 + 复测建议
```

Quick 模式的价值是快、真实、有证据。不要为了一个按钮或一个页面引入 100K token 的重流程。

### Full Flow Test

适用于大型任务、复杂链路、交付前验收、权限/数据/Agent 流程、需要生成可复跑测试脚本的场景。

```
用户指定要测试的功能
        ↓
┌───────────────────────────────────────┐
│ Coordinator                            │
│ 判断 Full + 确认范围/工具/viewport/数据 │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer 阶段 0                    │
│ 确认测试范围 + 收集可选信息             │
│ (ground truth, UI 截图, Operator 工具) │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer 阶段 1                    │
│ 读代码 → 生成规约                      │
│ 标注匹配的"场景模式"                   │
└───────────────────────────────────────┘
        ↓
   ╔═══════════════╗
   ║  人类 Review  ║  ← 第一道:确认规约准确性
   ╚═══════════════╝
        ↓
┌───────────────────────────────────────┐
│ Cartographer 阶段 2                    │
│ 规约 → 测试用例                        │
│ 填场景模式自检表 + Resource Dependency │
│ Matrix                                │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer 阶段 2.5(如需要)         │
│ 逐文件决策文件输入策略                  │
│ (仅当任何 TC 有 file_inputs 时)        │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Inspector                             │
│ 用方法论 + 自检表审查用例              │
│ 输出 P0/P1/P2 分级反馈                │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Cartographer 阶段 3                    │
│ 决定每条反馈修不修(填 rationale)     │
└───────────────────────────────────────┘
        ↓
   ╔═══════════════╗
   ║  人类 Review  ║  ← 第二道:确认用例可跑
   ╚═══════════════╝
        ↓
┌───────────────────────────────────────┐
│ Operator                              │
│ 用 Codex 工具执行用例                  │
│ 输出执行报告                           │
└───────────────────────────────────────┘
        ↓
┌───────────────────────────────────────┐
│ Coordinator Final Review               │
│ 分类 bug / 环境 / 工具限制 / 复测建议    │
└───────────────────────────────────────┘
```

---

## 四个角色的职责

| Agent | 角色 | 看什么 | 不看什么 |
|------|-----|------|--------|
| **Coordinator / Test Lead** | 统筹者 | 用户目标 + 项目状态 + 工具能力 + 最终报告 | 不替代 Operator 做浏览器执行细节 |
| **Cartographer** | 制图师 | 代码 + 规约 + 用例 + Inspector 反馈 | (无限制) |
| **Inspector** | 检查员 | 规约 + 用例 + 方法论 | **不看代码** |
| **Operator** | 执行员(模拟真实用户) | 用例 + 浏览器实际状态 | **不做对错判断 + Steps 不走 API 捷径** |

**Operator 关键约束**:trigger(被测功能的触发动作)**必须**通过浏览器 UI 完成,
不允许走 API / SSE / SQL 等捷径——否则 E2E 测试退化为 API 测试。
仅 Setup / Teardown / 验证 server_state 时允许走 API/DB(因为不是被测功能本身)。
详见 `references/operator.md` 核心原则 1。

每个 agent 的详细指引在对应的 reference 文件里:

- 进入 Coordinator 角色 → 读 `references/coordinator.md`
- 进入 Cartographer 角色 → 读 `references/cartographer.md`
- 进入 Inspector 角色 → 读 `references/inspector.md`
- 进入 Operator 角色 → 读 `references/operator.md`

---

## Codex 工具执行计划(Codex-tool-plan)

### 核心理念

Codex 里做功能测试时,工具选择本身就是测试设计的一部分。
每个 Full Flow Test 的 TC 必须填写 `Codex-tool-plan`;旧版 `Operator-mode: A/B/C` 仅作为兼容字段保留。

| 工具计划 | 适用场景 | 执行方式 |
|----|--------|--------|
| **Browser Use** | 浏览器内功能测试、真实用户路径、DOM/console/dialog 观察 | Codex in-app browser 中点击、输入、截图、读 DOM 和 console |
| **Browser Use + Screenshot Review** | 视觉、布局、Markdown、响应式、UX 语义判断 | Browser Use 执行 + 截图 + LLM 后处理判断 |
| **Playwright Script** | 大型测试、稳定复跑、trace、批量断言 | 生成 `.spec.ts`,Steps 仍走 UI,API 只做 setup/verify/teardown |
| **Computer Use** | OS 级或浏览器外动作:系统文件选择器、下载目录、原生弹窗、跨 App | 只补 Browser Use 做不到的动作,不代替网页点击 |
| **Supabase Verify** | schema/table/migration/Edge Function 探测或 server_state verify | 辅助验证,不作为功能 trigger |
| **API/Security Supplemental** | 越权、绕过 UI、非法状态转移、安全补充 | 与普通 E2E 用例分开标注,避免污染 E2E 原则 |

默认选择:
- 单功能快测 → `Browser Use`
- 有视觉/布局/渲染判断 → `Browser Use + Screenshot Review`
- 大型验收或需要可复跑 → `Playwright Script`
- 文件选择器/下载目录/系统弹窗 → `Computer Use`
- 数据库或 Supabase 后端事实 → `Supabase Verify` 作为辅助 verify
- 安全绕过 UI 的攻击面 → `API/Security Supplemental`

### Viewport Discipline

Codex in-app browser 窗口可能很小。小窗口会触发移动端布局,导致截图不代表真实桌面体验。
凡是截图或视觉判断,必须记录:
- viewport 宽高
- 测试意图:desktop / tablet / mobile / small-codex-viewport
- 截图路径
- 该截图是否可作为 desktop 布局证据

默认 desktop 目标是 `1280x800` 或 `1440x900`。
如果无法设置到目标大小,报告必须标注 `small-codex-viewport evidence`,并且不能直接把导航折叠、表格换行、卡片堆叠判为 desktop bug。

### Full Flow TC 必填字段

- **`Codex-tool-plan`**:首选执行计划,必填
- **`Viewport target`**:视觉/截图相关 TC 必填
- **`Evidence to collect`**:截图、console、dialog、network、trace、DB/Supabase 查询等
- **`Screenshot points`**:需要截图判断时必填
- **`Operator-mode`**:旧字段,可选兼容;如果存在,必须和 `Codex-tool-plan` 不冲突

例:

```yaml
Codex-tool-plan:
  primary: Browser Use + Screenshot Review
  helpers:
    - Supabase Verify
  reason: "需要验证聊天消息的后端存储和前端 Markdown 渲染"

Viewport target:
  intent: desktop
  size: 1280x800
  fallback: "若 Codex 窗口无法达到目标尺寸,标注 small-codex-viewport evidence"

Evidence to collect:
  - screenshot
  - console_errors
  - dialog_events
  - server_state: "messages 表新增 user + assistant 两条记录"

Screenshot points:
  - after_step: 5
    save_to: screenshots/TC-005-after-send.png
    viewport: 1280x800
    llm_judges:
      - "气泡内 Markdown **重要** 是否渲染为加粗?"
      - "整体气泡布局是否正常,且结论不受 small viewport 影响?"
```

### Inspector 审什么

Inspector 不替 Cartographer 重新选择工具,但必须审查:
- TC 是否填写 `Codex-tool-plan`。
- 视觉/截图 TC 是否填写 `Viewport target` 和 `Screenshot points`。
- `Computer Use` 是否只用于浏览器外/OS 级动作。
- `Supabase Verify` 是否只用于 setup / verify,没有变成触发被测功能的捷径。
- `API/Security Supplemental` 是否和普通 E2E trigger 分开。

---

## Agent 实例隔离规则(execution-time architecture)

Full Flow Test 中的角色不只是逻辑角色——**Inspector 应该在独立 agent 实例中运行**,
这是隔离独立性的执行层保证。

### Inspector 必须在独立 agent 实例中运行(强制)

**原因**:Inspector 的核心价值是"独立审查 Cartographer 的判断"——
但如果 Inspector 和 Cartographer 在同一个 conversation 里跑,
Inspector 已经"看过代码 / 知道 Cartographer 的思考过程",**它的独立性被污染了**——
它会下意识为 Cartographer 的设计辩护,审查质量大幅降低。

**Full Flow 强制要求**:Cartographer 阶段 2 完成后(以及阶段 3 修订完成后),**必须**告知用户开独立实例跑 Inspector,**不允许**在原 conversation 里直接切换角色。

Quick Feature Test 默认不运行 Inspector,因为它追求快速验证和现场证据。

**怎么开独立实例**(按部署环境选择):

| 环境 | 推荐方式 | 备用方式 |
|------|--------|--------|
| **Codex / Claude Code** | 用 subagent / Task 工具开新 agent(如当前环境允许) | 让用户开新对话 |
| **API 调用方** | 发起新 conversation,system prompt 引导进入 Inspector 角色 | — |
| **Claude.ai / Claude Desktop** | 让用户开新对话(普通用户没有 subagent 能力) | — |

**给 Inspector 实例的输入清单**:
1. 规约文档(Cartographer 阶段 1 产出 + 人类 review 后的最终版)
2. 用例文档(Cartographer 阶段 2 产出 + 阶段 2.5 文件决策完成后的最终版)
3. 装上 codex-web-test skill,系统会引导进入 Inspector 角色

**绝对不要传给 Inspector**:
- ❌ 代码(任何源代码文件)
- ❌ Cartographer 阶段 1 / 阶段 2 的思考过程 / 中间决策
- ❌ Cartographer 选用某些方法论的原因

Inspector 完成后,把反馈文档传回原 Cartographer conversation,Cartographer 阶段 3 处理反馈。

### Operator 不强制独立(同一 conversation 也行)

**原因**:Operator 的价值是"忠实执行"——它看过代码反而能更好处理异步 timing 等细节。
诚实性由 E2E 视角约束(SKILL.md 第 11 条原则)保证,不需要 context 隔离来实现。

实际上,**让 Cartographer 阶段 3 完成后,在同一 conversation 里继续跑 Operator,是合理的**——
出题人来执行测试,对题目细节理解最深。

**但仍然要遵守的边界**:
- Operator 必须严格按已审过的用例执行(Steps 必须用浏览器 UI,不允许 API 捷径)
- Operator 不"创造性"补测试或修复用例——这些超出执行职责

### 阶段内部不需要隔离

Cartographer 的所有阶段(0 / 1 / 2 / 2.5 / 3)都是 Cartographer 角色,
**同一个 conversation 里连续跑**——不需要切换 agent 实例。
中间的两道人类 review 是隔离机制,不是切换 agent。

Coordinator 可以和当前 conversation 保持在一起。它负责入口决策和最终整理,不需要独立隔离。

### 流程示意

```
agent A(Coordinator + Cartographer): 模式判断 → 阶段 0 → 阶段 1 → 阶段 2 → 阶段 2.5 → 阶段 3 → Operator → Coordinator Final Review
                                                                      ↑
                                                  反馈传回 ── ── ── ┘
                                                       ↑
agent B(Inspector,独立实例): 审查
                              ↑
            (规约 + 用例传入)
```

---

## 核心制品

Quick 模式产出轻量测试记录;Full 模式产出完整文档。所有正式文档用 Markdown 格式。

| 制品 | 产出者 | 模板 |
|------|------|------|
| Quick 测试记录 | Coordinator / Operator | 直接在对话或项目测试记录中输出 |
| 规约文档 | Cartographer | `templates/spec-template.md` |
| 测试用例文档 | Cartographer | `templates/test-cases-template.md` |
| Inspector 反馈 | Inspector | `templates/judge-output-template.md` |
| 执行报告 | Operator | `templates/execution-report-template.md` |
| Coordinator Final Review | Coordinator | 执行报告中的 Final Review 段 |

完整工作样例在 `examples/login-spec-example.md`。

---

## 启动这个 skill

当用户要求测试某个 web 功能时,agent 先进入 **Coordinator**:

1. **用户想测哪个功能**——明确具体的功能名(如"用户登录"、"密码重置")
2. **代码在哪**——用户应该指明项目位置或相关文件
3. **测试环境怎么访问**——项目是否已启动?目标 URL 是什么?是否允许启动服务?
4. **测试模式怎么选**——Quick Feature Test 还是 Full Flow Test
5. **工具和 viewport 怎么设**——Browser Use / Playwright / Computer Use 是否可用,desktop 目标尺寸是什么

如果以上有不清楚的,问用户。不要立刻开始读代码。

完整入口协议见 `references/coordinator.md`;Full Flow 的阶段 0 协议见 `references/cartographer.md`。

---

## 暂停点和"通过"信号

Full Flow Test 有 2 道强制人类 review,agent **必须暂停**等待。Quick Feature Test 默认没有强制 review gate:

| 暂停点 | 触发时机 | 必须做的 | 通过信号 |
|------|------|------|------|
| **规约 review** | Cartographer 阶段 1 完成后 | 把规约展示给用户 | 用户说:"规约 OK" / "通过" |
| **用例 review** | Cartographer 阶段 3 完成后(反馈处理完) | 把最终用例展示给用户 | 用户说:"用例 OK" / "可以跑了" |

浏览器、viewport、测试数据和环境问题由 Coordinator 在入口阶段先确认。第一道 review 关注规约准确性,第二道关注用例质量。

完整 review 清单见 `references/human-review-checklists.md`。

---

## 关键设计原则

13 条核心原则,**每条只在主文件展开**——下面给一句话要点 + 引用主文件。

**1. Agent 之间的隔离边界是 skill 的灵魂**——Inspector 不看代码,Operator 不做归因判断。
独立性详见上面"Agent 实例隔离规则"。

**2-4. 三层规约结构 / client vs server state / behaviors 用户意图级**——规约怎么写。详见
`templates/spec-template.md` 字段注释,以及 `references/cartographer.md` 阶段 1。

**5. 严重程度分级(P0/P1/P2)**——P0 必修,P1 默认修(不修需 rationale),P2 可选。
详见 `references/inspector.md` 工作流程 §3。

**6. 信息源权威等级**——多个来源冲突时按 P1-P7 取信(用户 ground truth > SQL > fixture > 代码 > 配置 > 文档 > 口头),
冲突时显式声明让人类裁决。详见 `references/cartographer.md` 阶段 1 第 7 条。

**7. 多模态输入靠工程方法**——规约只描述"需要什么样的文件",阶段 2.5 让用户逐个文件选(A 路径 / B 手动 / C Agent 生成)。
详见 `references/cartographer.md` 阶段 2.5。

**8. 易抽象字段必须带"逻辑依据"**——LLM 读代码容易把 fallback / 异常处理 / 模板字符串错误归纳成普通规则。
让 Cartographer 在写涉及代码归纳的字段时先写依据再下结论,Inspector 审"依据 vs 结论是否自洽"。
详见 `references/cartographer.md` 阶段 1 第 8 条。

**9. 场景模式 + 自检 + 审查自检**——方法论(EP/BVA)是"标尺",场景模式是"必查清单"。
Cartographer 阶段 1 识别匹配模式 → 阶段 2 把每个清单项标 ✓/⚠/✗(必给依据)→ Inspector 审查这张自检表。
完整模式库见 `references/scenarios/`,机制详见 `references/cartographer.md` 阶段 2 第 1 条 + `references/inspector.md` §1.5。

**10. 破坏性 TC 识别 + Setup/Teardown**——TC 之间通过共享资源互相污染是经典死锁。
每个 TC 标 Destructive: yes/no,破坏性 TC 必须有 Teardown,不可逆操作必须 mock。
用例文档加 Resource Dependency Matrix。详见 `references/cartographer.md` 阶段 2 第 6 条 + `references/inspector.md` §1.7。

**11. E2E 视角:Steps 必须用户视角**——Steps 写"浏览器输入 X / 点击 Y",不是 "POST /api/...";
否则 E2E 退化为 API 测试。仅 Setup / Teardown / verify server_state 允许走 API/SQL。
详见 `references/cartographer.md` 阶段 2 第 7 条 + `references/operator.md` 核心原则 1 + `references/inspector.md` §1.8。

**12. Codex-tool-plan 工具路由**——
每个 Full Flow TC 标 `Codex-tool-plan`:Browser Use / Browser Use + Screenshot Review / Playwright Script / Computer Use / Supabase Verify / API/Security Supplemental。
Browser Use 是网页功能测试默认首选;Computer Use 只补浏览器外/OS 级动作;Supabase 只做辅助验证。
详见上面"Codex 工具执行计划"章节 + `references/operator.md` 工作流程。

**13. Viewport Discipline**——
所有截图和视觉判断必须记录 viewport;Codex 小窗口截图标 `small-codex-viewport evidence`,不能直接当作 desktop 布局失败证据。
详见 `references/coordinator.md` 和 `templates/execution-report-template.md`。

---

## 方法论参考

Inspector **按功能特征选用**方法论(不是 6 个全跑)。当前 skill 提供以下方法论文档:

**经典 spec-based testing 方法论**:
- `references/methodologies/equivalence-partitioning.md` — 等价类划分(用于输入数据型)
- `references/methodologies/boundary-value-analysis.md` — 边界值分析(用于输入数据型)
- `references/methodologies/decision-table.md` — 决策表(用于多条件组合)
- `references/methodologies/state-transition.md` — 状态转移(用于状态机)
- `references/methodologies/use-case-testing.md` — 用例测试(用于完整流程)

**辅助 checklist**:
- `references/methodologies/right-bicep.md` — Right-BICEP(辅助交叉验证,不作为主方法论)

详细的选用逻辑见 `references/inspector.md` §2。

---

## 样例

`examples/` 目录提供完整的样例供 Cartographer / Operator 参考:

**简单功能样例(登录)**——展示 Quick Feature Test 和 Full Flow 规约/用例的边界:
- `examples/login-spec-example.md` — 用户登录的规约样例(三层结构、§3.4 拆分、§3.5 setup、逻辑依据)
- `examples/login-cases-example.md` — 对应的用例样例(Resource Dependency Matrix、场景模式自检表、Codex-tool-plan、viewport evidence)

**复杂功能样例(chatbot,核心)**——展示 Browser Use + Screenshot Review / Playwright Script / Supabase Verify 的组合:
- `examples/chatbot-spec-example.md` — 轻量 chatbot 规约(对话型 UI + 异步流式 + LLM agent + 前端渲染保真度多模式叠加)
- `examples/chatbot-cases-example.md` — 对应的用例(Codex-tool-plan、Screenshot points、API/Security Supplemental 边界)
- `examples/chatbot-execution-report-example.md` — 执行报告样例(viewport evidence、Playwright trace 摘要、LLM 截图判断、Coordinator Final Review)

**强烈推荐**:Cartographer 阶段 2 写涉及前端渲染保真度的 TC 时,**必读 chatbot-cases-example.md**。

---

## 工程边界

这个 skill **不**做的事(以及如何处理):

- **skill 不审代码正确性**——如果代码本身有 bug,规约只是描述"有 bug 的代码做什么";测试会照着这个跑,通过。这是设计上的:spec-driven testing 测的是"实现是否符合规约",而"规约是否对"是人类 review 的责任。
- **性能 / 负载测试**——超出范围;规约描述行为,不描述性能特性。
- **安全审计**——skill 涵盖基础认证授权和输入边界(XSS 通过长度边界),但**不能**替代专业的安全审计。
- **视觉回归**——skill 验证功能行为,不验证像素级视觉变化。

---

## 添加新场景模式

如果实际使用中发现某种重复出现的场景类型,但当前 11 个模式覆盖不到(如"实时协作编辑"、"区块链交易"、"图像识别"),按以下步骤添加新模式:

1. 起一个简洁名字(2-4 个字)
2. 在 `references/scenarios/` 创建新的 `.md` 文件(参考已有文件结构)
3. 在文件中列出该模式的必查清单
4. 在 `references/scenarios/index.md` 加一行,让 Cartographer 能发现

这是低成本扩展——不需要修改 Cartographer 或 Inspector 主文件,两者读取目录的最新版本。

---

## 备注

这个 skill 是重型工具,完整跑一次 E2E 测试可能消耗 100K-500K tokens(取决于功能复杂度)。适合:

- 关键业务流程(登录 / 支付 / 数据创建删除)
- 安全相关功能(权限 / 认证 / 隐私)
- LLM agent 系统(grounding / hallucination / 工具调用安全)

不适合:

- 不值得留证据的随手探索(手动操作更高效)
- 单元测试(用 pytest / jest)
- 性能压测(专门工具)
- 探索性测试(手动操作更高效)

用之前问自己:这个功能只需要 Quick Feature Test,还是值得花 100K-500K tokens 做 Full Flow Test?
