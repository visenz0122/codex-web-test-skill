---
name: spec-driven-test
description: 用规约驱动测试(specification-based testing)的方法对 web 应用做端到端测试。当用户说要"测试一下这个功能"、"检查一下这个功能的完整性"、"对这个项目做 E2E 测试"、"用 agent 测这个 web 应用"或者直接提到 spec-driven-test / specification-based testing 时使用这个 skill。也适用于用户希望基于代码自动生成测试规约和测试用例,然后通过浏览器自动化执行测试的场景。即使用户没有明确说"规约"或"测试用例"这些词,只要他想系统地、自动化地测试一个 web 项目的某个功能,都应该使用这个 skill。
---

# Spec-Driven Test

用规约驱动测试的方法对 web 应用做端到端测试。
整个流程由三个 agent 协作完成:**Cartographer** 读代码生成规约和用例,**Inspector** 用方法论审用例,**Operator** 在真实浏览器执行测试。两道人类 review 把关质量。

---

## 按需加载导航(执行 skill 前先读这段)

这个 skill 是文件型 skill,你**不需要一次性读完所有 reference 文件**——按角色和阶段读对应章节,可大幅节省 token。

**确定你的角色,只读对应主文件**:

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

## 整体流程

```
用户指定要测试的功能
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
│ 在真实浏览器执行用例                   │
│ 输出执行报告                           │
└───────────────────────────────────────┘
```

---

## 三个 Agent 的职责

| Agent | 角色 | 看什么 | 不看什么 |
|------|-----|------|--------|
| **Cartographer** | 制图师 | 代码 + 规约 + 用例 + Inspector 反馈 | (无限制) |
| **Inspector** | 检查员 | 规约 + 用例 + 方法论 | **不看代码** |
| **Operator** | 执行员(模拟真实用户) | 用例 + 浏览器实际状态 | **不做对错判断 + Steps 不走 API 捷径** |

**Operator 关键约束**:trigger(被测功能的触发动作)**必须**通过浏览器 UI 完成,
不允许走 API / SSE / SQL 等捷径——否则 E2E 测试退化为 API 测试。
仅 Setup / Teardown / 验证 server_state 时允许走 API/DB(因为不是被测功能本身)。
详见 `references/operator.md` 核心原则 1。

每个 agent 的详细指引在对应的 reference 文件里:

- 进入 Cartographer 角色 → 读 `references/cartographer.md`
- 进入 Inspector 角色 → 读 `references/inspector.md`
- 进入 Operator 角色 → 读 `references/operator.md`

---

## Operator 混合执行模式(Playwright + LLM 截图判断)

### 核心理念

Operator 默认采用**混合执行模式**——不是单纯的 LLM 实时操作浏览器,也不是单纯的 Playwright 脚本。
两种工具分工合作,**让每种工具做它擅长的事**:

| 工具 | 擅长什么 | 不擅长什么 |
|----|--------|--------|
| **Playwright** | 输入输出层(数据进数据出)、DOM 断言、SQL/API 验证、可重放、token 成本极低 | 视觉/UX 判断、"看起来对不对"的语义理解 |
| **LLM 看截图**(computer-use) | 视觉判断、UI 设计/UX、Markdown/emoji/字体渲染保真度 | 精确数据断言、循环执行、可重放 |

混合模式的逻辑:**Playwright 跑业务流程 + 在关键时刻留截图 + LLM 后处理读截图做视觉判断**。
这是方案 X(Playwright 留截图 + LLM 后处理),**不是**方案 Y(场景重跑两次)。

### 三种 TC 类型(Operator-mode 字段)

Cartographer 阶段 2 写每个 TC 时,**必须**标 `Operator-mode` 字段,三选一:

| 模式 | 适用场景 | 执行方式 |
|----|--------|--------|
| **A: LLM 浏览器**(Claude in Chrome / browser-use) | 测视觉 / 渲染 / UX / 探索性 | LLM 实时操作浏览器 + 看截图判断 |
| **B: Playwright** | 测输入输出 / 数据流 / 业务逻辑 / 回归 | 生成 .spec.ts 脚本,Playwright 引擎执行 |
| **C: 混合**(默认推荐) | 既要数据正确又要视觉验证(如 chatbot 消息渲染、Markdown 处理) | Playwright 跑业务 + 关键时刻留截图,LLM 后处理读截图判断渲染 |

**判别要点**:
- 测点是"数据传递正确性" → B
- 测点是"视觉/渲染/UX" → A
- 测点既要数据也要视觉 → C(大多数 chatbot / CRUD / 个人主页类功能都是 C)

### 混合模式 C 的执行流程

```
TC-005: 发送 Markdown 消息,验证渲染 + 后端存储

第 1 阶段(Playwright 自动执行):
  1. 浏览器访问 /app/agent
  2. 在 textarea 输入 "**重要**\n# 标题"
  3. 点击发送按钮
  4. 等待 SSE 流完成
  5. 📸 截图保存到 screenshots/TC-005-after-send.png  ← 截图节点
  6. SQL 验证: SELECT content FROM messages → 应为 "**重要**\n# 标题"

第 2 阶段(LLM 后处理):
  - 读 screenshots/TC-005-after-send.png
  - 视觉判断: 气泡里 "重要" 是粗体吗?"# 标题" 是大字标题吗?
  - 输出截图判断结果到 execution-report

合并报告:
  - Playwright trace: Steps 全部 PASSED
  - LLM 截图判断: 粗体 ✅, 标题 ✅
  - 综合状态: PASSED
```

### TC 必须包含的两个新字段(在 test-cases-template.md 中)

- **`Operator-mode`**:A / B / C
- **`Screenshot points`**(仅 mode A 和 C 用):列出在哪些步骤后留截图,以及每张截图后 LLM 应该判断什么

例:

```yaml
Operator-mode: C

Screenshot points:
  - after_step: 5  # SSE 流完成后
    save_to: screenshots/TC-005-after-send.png
    llm_judges:
      - "气泡内 Markdown **重要** 是否渲染为加粗 <strong> 元素?"
      - "气泡内 # 标题 是否渲染为 <h1> 大字标题?"
      - "整体气泡布局是否正常(无错位、文字未溢出)?"
```

### Inspector 不审 Operator-mode 的工具选择

Inspector 不质疑 Cartographer 选 A/B/C 的判断——这是工程决策,不是规约/方法论问题。
Inspector 只审:
- TC 是否填了 `Operator-mode`(没填 → P0)
- 模式 A 和 C 的 TC 是否填了 `Screenshot points`(没填但 expected 涉及视觉断言 → P1)

详见 `references/operator.md` 工作流程,以及 `templates/test-cases-template.md` 字段格式。

---

## Agent 实例隔离规则(execution-time architecture)

skill 的三个角色不只是逻辑角色——**它们应该在不同的 agent 实例中运行**,
这是隔离独立性的执行层保证。

### Inspector 必须在独立 agent 实例中运行(强制)

**原因**:Inspector 的核心价值是"独立审查 Cartographer 的判断"——
但如果 Inspector 和 Cartographer 在同一个 conversation 里跑,
Inspector 已经"看过代码 / 知道 Cartographer 的思考过程",**它的独立性被污染了**——
它会下意识为 Cartographer 的设计辩护,审查质量大幅降低。

**强制要求**:Cartographer 阶段 2 完成后(以及阶段 3 修订完成后),**必须**告知用户开独立实例跑 Inspector,**不允许**在原 conversation 里直接切换角色。

**怎么开独立实例**(按部署环境选择):

| 环境 | 推荐方式 | 备用方式 |
|------|--------|--------|
| **Claude Code** | 用 subagent / Task 工具开新 agent | 让用户开新对话 |
| **API 调用方** | 发起新 conversation,system prompt 引导进入 Inspector 角色 | — |
| **Claude.ai / Claude Desktop** | 让用户开新对话(普通用户没有 subagent 能力) | — |

**给 Inspector 实例的输入清单**:
1. 规约文档(Cartographer 阶段 1 产出 + 人类 review 后的最终版)
2. 用例文档(Cartographer 阶段 2 产出 + 阶段 2.5 文件决策完成后的最终版)
3. 装上 spec-driven-test skill,系统会引导进入 Inspector 角色

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

### 流程示意

```
agent A(Cartographer): 阶段 0 → 阶段 1 → 阶段 2 → 阶段 2.5 → 阶段 3 → ... → Operator(可选同实例)
                                                                      ↑
                                                  反馈传回 ── ── ── ┘
                                                       ↑
agent B(Inspector,独立实例): 审查
                              ↑
            (规约 + 用例传入)
```

---

## 核心制品

整个流程产出 4 类文档,所有文档用 Markdown 格式:

| 制品 | 产出者 | 模板 |
|------|------|------|
| 规约文档 | Cartographer | `templates/spec-template.md` |
| 测试用例文档 | Cartographer | `templates/test-cases-template.md` |
| Inspector 反馈 | Inspector | `templates/judge-output-template.md` |
| 执行报告 | Operator | `templates/execution-report-template.md` |

完整工作样例在 `examples/login-spec-example.md`。

---

## 启动这个 skill

当用户要求测试某个 web 功能时,agent 进入 **Cartographer 阶段 0**:

1. **用户想测哪个功能**——明确具体的功能名(如"用户登录"、"密码重置")
2. **代码在哪**——用户应该指明项目位置或相关文件
3. **测试环境怎么访问**——用户是不是已经把项目跑起来了?浏览器工具怎么用?(这影响 Operator 阶段)

如果以上有不清楚的,问用户。不要立刻开始读代码。

完整阶段 0 协议见 `references/cartographer.md`。

---

## 暂停点和"通过"信号

整个流程有 2 道强制人类 review,agent **必须暂停**等待:

| 暂停点 | 触发时机 | 必须做的 | 通过信号 |
|------|------|------|------|
| **规约 review** | Cartographer 阶段 1 完成后 | 把规约展示给用户 | 用户说:"规约 OK" / "通过" |
| **用例 review** | Cartographer 阶段 3 完成后(反馈处理完) | 把最终用例展示给用户 | 用户说:"用例 OK" / "可以跑了" |

浏览器和环境的问题等到 Operator 阶段再问。第一道 review 关注规约准确性,第二道关注用例质量。

完整 review 清单见 `references/human-review-checklists.md`。

---

## 关键设计原则

11 条核心原则,**每条只在主文件展开**——下面给一句话要点 + 引用主文件。

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

**12. Operator 混合执行模式(Playwright + LLM 截图判断)**——
不强制单一工具。每个 TC 标 `Operator-mode`:A(LLM 浏览器,适合视觉/UX)/ B(Playwright,适合数据流/回归)/ C(混合,默认推荐——Playwright 跑业务 + 关键时刻留截图,LLM 后处理读截图判断渲染)。
方案 X:截图在 Playwright 阶段留下,LLM 后处理读截图,**不**重跑场景。
详见上面"Operator 混合执行模式"章节 + `references/operator.md` 工作流程。

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

**简单功能样例(登录)**——展示规约 + 用例的基本结构:
- `examples/login-spec-example.md` — 用户登录的规约样例(三层结构、§3.4 拆分、§3.5 setup、逻辑依据)
- `examples/login-cases-example.md` — 对应的用例样例(Resource Dependency Matrix、场景模式自检表、5 个代表性 TC)

**复杂功能样例(chatbot,核心)**——展示混合模式 C 的完整应用:
- `examples/chatbot-spec-example.md` — 轻量 chatbot 规约(对话型 UI + 异步流式 + LLM agent + 前端渲染保真度多模式叠加)
- `examples/chatbot-cases-example.md` — 对应的用例(Operator-mode A/B/C 三种全用上,带完整 Screenshot points)
- `examples/chatbot-execution-report-example.md` — 执行报告样例(Playwright trace 摘要 + LLM 截图判断段实际填法)

**强烈推荐**:Cartographer 阶段 2 写涉及前端渲染保真度的 TC 时,**必读 chatbot-cases-example.md**——
里面的 TC-002 是混合模式 C 的标准范例。

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

- 简单 UI 交互测试(用 Playwright 直接写更快)
- 单元测试(用 pytest / jest)
- 性能压测(专门工具)
- 探索性测试(手动操作更高效)

用之前问自己:这个功能值得花 100K-500K tokens 做严谨 E2E 测试吗?
