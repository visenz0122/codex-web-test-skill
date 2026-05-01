<!--
================================================================================
Operator 测试执行报告模板

Operator 跑完测试后产出本文档。
核心原则:Operator 只忠实记录,不做对错判断。
- 用例通过/失败的判断由 Operator 做(基于用例的 expected)
- 但"为什么失败"的归因不做(留给人类或后续 agent)
- 意外情况按致命/重要/轻微分级
================================================================================
-->

# Test Execution Report

**Test cases version**: <对应用例的版本>
**Executed by**: Operator
**Started at**: <ISO 8601>
**Finished at**: <ISO 8601>
**Tools used**: <Browser Use / Browser Use + Screenshot Review / Playwright Script / Computer Use / Supabase Verify / API/Security Supplemental>
**Artifact root**: `test-artifacts/<feature>/<YYYYMMDD-HHMMSS>/`

## Summary

| 状态 | 数量 |
|-----|-----|
| Setup phase | succeeded / failed |
| 通过 | N |
| 失败 | M |
| 跳过(因前置失败) | K |
| 因致命意外终止 | <0 或 1> |

## Setup Phase

<!--
仅当规约的 Setup Strategy 字段非空时填写(聚焦测试模式)。
全流程测试模式可以写"(无 setup 阶段)"。

如果 setup 失败,后续所有用例都标 SKIPPED,这部分要详细说明失败原因。
区分这一阶段是为了让人类能立刻判断:这次失败是被测功能的问题,还是测试环境的问题。
-->

- **Setup steps executed** (来自规约 Setup Strategy):
  1. <如:调用 `POST /test/login-as?email=alice@example.com`> — ✅ 成功 / ❌ 失败
  2. <如:确认 cookie session_token 存在> — ✅ 成功 / ❌ 失败
  3. <如:导航到 `/chat`> — ✅ 成功 / ❌ 失败
- **Status**: succeeded / failed
- **如果失败**,详细记录:
  - 哪一步失败
  - 错误信息(HTTP 响应、控制台输出、截图路径)
  - 已尝试次数
- **结论**:
  - 如果 setup failed → **后续测试结果不可信,本次报告仅作前置失败诊断用**
  - 如果 setup succeeded → 继续看下面的用例结果

## Environment

<!--
简要记录测试环境,方便复现问题。
不需要 Operator 自己启动环境(那是用户的事),但要记录 Operator 实际跑在什么环境上。
-->

- 浏览器:<如:Chrome 122>
- 测试目标 URL:<如:http://localhost:3000>
- 测试用户身份:<如:登录态、未登录、特定权限>
- Dev server command:<如:npm run dev / 用户已启动 / 不适用>
- Viewport target:<如:desktop 1280x800>
- Viewport actual:<如:1012x742>
- Viewport evidence note:<desktop evidence / mobile evidence / small-codex-viewport evidence>

## Evidence Index

<!--
列出本次测试产生的主要证据,不要把长日志贴进报告正文。
-->

| 类型 | 路径/摘要 | 用途 |
|----|----------|----|
| Screenshot | `test-artifacts/.../screenshots/TC-001.png` | 视觉判断 |
| Console | `test-artifacts/.../console/TC-001.txt` | 控制台错误 |
| Dialog events | `test-artifacts/.../dialogs/TC-001.json` | XSS / alert / confirm 验证 |
| Playwright trace | `test-artifacts/.../traces/TC-001.zip` | 稳定复跑调试 |
| Server verify | `<SQL/API/Supabase 查询摘要>` | server_state 验证 |

## Results

### TC-001: <用例标题>

- **Status**: PASSED / FAILED / SKIPPED
- **Duration**: <如:3.2s>
- **References**: B1, INV-C1
- **Codex-tool-plan used**: <Browser Use / Browser Use + Screenshot Review / Playwright Script / Computer Use / Supabase Verify / API/Security Supplemental>
- **Operator-mode used**: <可选兼容字段:A / B / C>
- **Viewport actual**: <宽x高>
- **Viewport evidence**: desktop evidence / mobile evidence / small-codex-viewport evidence

<!-- 如果 PASSED,以下部分可以简略 -->
<!-- 如果 FAILED 或有意外,详细记录 -->

**Steps executed**

1. ✅ 访问 /login
2. ✅ 提交表单
3. ❌ 期望 URL 为 /dashboard,实际为 /login(仍在登录页)

**Observations**

- Final URL: /login
- Cookie session_token: 不存在
- Visible text: "邮箱或密码错误"
- (如有)截图:<路径>
- (如有)控制台错误:<内容>
- (如有)dialog 事件:<内容>
- (如有)network / request 摘要:<内容>

**Viewport Evidence**

| 截图 | 目标 viewport | 实际 viewport | 是否可作为 desktop 证据 | 说明 |
|----|--------------|--------------|------------------------|----|
| TC-001-after-send.png | 1280x800 | 1012x742 | false | small-codex-viewport evidence,不能直接判定 desktop 布局失败 |

**Playwright trace 摘要**(仅 Codex-tool-plan 包含 Playwright Script 时填)

<!--
B / C 模式跑了 Playwright 后,Playwright 会产生 trace.zip / report.html。
在这里给关键摘要,不要贴整份报告。
-->

- 脚本路径:`tests/generated/TC-001.spec.ts`
- 执行命令:`npx playwright test tests/generated/TC-001.spec.ts`
- 通过的 assertion:N 项
- 失败的 assertion:M 项(列出每条失败的 expect 语句 + 实际值)
- Trace 文件:`test-results/TC-001/trace.zip`(供后续调试)
- 关键截图:`test-results/TC-001/test-failed-1.png`(自动失败截图)

**LLM 截图判断**(仅 Codex-tool-plan 包含 Screenshot Review 时填)

<!--
对每个在用例 Screenshot points 中定义的截图点,记录 LLM 看图后的判断结果。
每个 llm_judges 问题都要有 ✅ / ❌ + 简短描述。

如果某项判断为 ❌,这是一个独立的 FAILED 信号——即使 Playwright 部分全 PASSED,
本 TC 综合状态也是 FAILED(任一失败 = FAILED)。
-->

| 截图 | 判断问题 | 结果 | 描述 |
|----|--------|----|----|
| TC-001-after-send.png | Markdown **重要** 是否渲染为粗体? | ✅ | 气泡内 strong 元素存在 |
| TC-001-after-send.png | # 标题 是否渲染为 H1? | ✅ | h1 元素存在,字号正常 |
| TC-001-after-send.png | 整体气泡布局是否正常? | ❌ | 长文本溢出气泡,触及右边距 |

**Console / Dialog / Network 摘要**

- Console errors: <无 / 列出关键错误>
- Console warnings: <无 / 列出关键 warning>
- Dialog events: <无 / alert("xss") 被拦截等>
- Network notes: <无 / 关键请求失败 / 响应状态异常>

**Invariant checks**

- INV-C1 (URL 不含密码): ✅ 通过
- INV-S1 (日志不含密码): ⚠️ 无法验证(Operator 没有日志访问权限)

**前后端数据对比**(仅当 verify 同时涉及浏览器观察 + 服务器查询时填)

<!--
本 TC 是不是同时验证了"后端数据"(SQL/API 查询)和"前端渲染"(浏览器观察)?
如果是,**逐个数据维度对比两侧值是否一致**——这能精确定位"前端渲染保真度"问题。

经典场景:后端 SQL 查到的 message.content 是 Markdown 字符串 "**Hello**",
但浏览器气泡里显示的是字面字符串 "**Hello**"(没渲染成粗体)——
这种 bug 用单侧断言抓不到,必须前后端同时观察 + 对比。

如果本 TC 不涉及前后端对比(纯前端 / 纯后端断言),整段省略。
-->

| 数据维度 | 后端值(来源) | 前端渲染(浏览器观察) | 是否一致 |
|--------|-----------|------------------|--------|
| 用户名 | "张三"(SQL: SELECT name FROM users WHERE id=1) | "张三"(用户气泡 .username 文本) | ✅ |
| 时间戳 | 2026-04-26T10:00:00Z(SQL: created_at) | "2026-04-26 18:00"(.timestamp 文本) | ✅ 时区转换正确 |
| 消息 Markdown | "**重要**"(SQL: messages.content) | "**重要**"(.bubble 文本,无 `<strong>` 元素) | ❌ 未渲染为粗体 |
| 数字精度 | 12345.67(API response.amount) | "12,345.7"(.amount 文本) | ⚠ 精度丢失 |

**前端渲染问题**(如有不一致):

- 描述:消息 Markdown 没有渲染——SQL 数据是 `"**重要**"`,但前端 .bubble 内是字面字符串
- 严重程度:中等(影响阅读体验,不阻塞功能)
- 建议归因方向:前端 Markdown 渲染器未启用 / 渲染时机错误 / 转义函数过度

**Anomalies**

<!--
如果遇到用例没预料到的情况(意外),在这里记录。
按致命/重要/轻微分级。Operator 不判断对错,只记录现象。
-->

- 严重等级:轻微
- 描述:点击登录按钮后,页面右上角短暂闪过一个不在 expected 中的 toast 通知

### TC-002: ...

<!-- 重复 -->

## Anomalies Aggregated

<!--
所有用例中出现的意外汇总,方便人类一次性 review。
按严重等级降序排列。
-->

### 致命级(导致测试中断或后续用例无法运行)

- 无 / 列出

### 重要级(单个用例失败但不影响其他)

- TC-005: 浏览器渲染异常,但页面文本断言通过
- TC-008: API 响应耗时 > 30s

### 轻微级(不影响断言但值得注意)

- TC-001: 出现非预期 toast(见上)
- TC-003: 控制台有一条 warning(<内容>)

## Skipped Test Cases

<!--
如果某些用例没跑(因前置失败、致命意外终止等),在这里说明原因。
-->

- TC-020: 跳过,原因:依赖 TC-019 的状态(TC-019 失败)
- TC-021 ~ TC-030: 跳过,原因:致命意外触发(浏览器崩溃),Operator 主动终止

## Failure Classification Draft

<!--
Operator 只记录事实;下面是供 Coordinator Final Review 使用的初步分类草稿。
如果不确定,标 needs manual review。
-->

| 发现 | 证据 | 初步分类 | 不确定性 |
|----|----|--------|--------|
| TC-001 登录后仍停留 /login | 截图 + URL + console | product bug / environment/setup issue / needs manual review | <说明> |

可用分类:
- product bug
- test script bug
- environment/setup issue
- tool limitation
- data pollution
- needs manual review

## What Operator Did Not Do

<!--
Operator 必须诚实声明它做了什么、没做什么。
-->

- 未判断失败用例是"被测系统 bug"还是"用例写错了"——这是人类的工作
- 未尝试修复用例或被测代码——超出 Operator 职责
- 未访问数据库验证 server_state——除非用例的 expected 明确指出可验证手段且 Operator 有权访问
- 未把 small-codex-viewport 截图当作 desktop 布局失败的最终证据

## Coordinator Final Review

<!--
由 Coordinator / Test Lead 在 Operator 报告之后填写。
这里可以做初步归因和行动建议,但必须基于证据,并标注不确定性。
-->

### Findings by Category

#### product bug
- <发现 + 证据 + 推荐修复方向>

#### test script bug
- <发现 + 证据 + 如何修测试>

#### environment/setup issue
- <发现 + 证据 + 如何修环境>

#### tool limitation
- <发现 + 证据 + 需要换工具/人工复测的原因>

#### data pollution
- <发现 + 证据 + 需要清理/隔离的数据>

#### needs manual review
- <发现 + 证据不足点 + 人类要看什么>

### Retest Recommendations

- <修复后优先复测哪些 TC>
- <是否需要 desktop viewport 复测>
- <是否需要把 Quick 测试升级为 Full Flow 或补 Playwright 回归>
