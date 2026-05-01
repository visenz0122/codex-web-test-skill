# Feature: AI Chatbot 对话核心

> 这是 codex-web-test skill 的**核心样例**——展示一个轻量 chatbot 的规约,
> 涵盖最常用的场景模式叠加(对话型 UI + 异步流式 + LLM agent 决策 + 前端渲染保真度)。
>
> 假设的产品:一个简化的 AI 助手 chatbot,用户输入问题,后端调 LLM,
> SSE 流式返回回复,前端 Markdown 渲染。**不带登录、不带历史会话**——保持轻量。

## 1. Interface

### 1.1 Routes

- `/chat` — chatbot 对话主页面

### 1.2 API Endpoints

- `POST /api/chat/stream` — 请求 `{ message: string }`,响应 SSE 流式
  - SSE 事件类型:`start` / `delta` / `done` / `error`
  - delta 事件 payload:`{ chunk: string }` —— 累积成完整回复
- `GET /api/chat/messages?session_id=X` — 查询某会话的历史消息(给测试 verify 用)

## 2. Constraints (MUST)

### 2.1 Behaviors

#### B1: 用户发送普通消息,收到完整流式回复

**Preconditions**

- Client state: 在 `/chat` 页面,textarea 为空,**发送按钮处于 disabled 状态**(因 textarea 为空)
- Server state: LLM 服务可用

**Trigger**

- Intent: 在 textarea 输入消息(此时按钮变为 enabled)→ 点击发送(或按 Enter)
- With: `message="什么是细菌性肺炎?"`

**Expected (eventually)**

- Client state after:
  - URL 仍为 `/chat`
  - textarea 被清空,**发送按钮回到 disabled 状态**(因清空后又为空)
- Server state after:
  - 新增一条 user 消息记录到 messages 表(role=user, content=原始输入)
  - 新增一条 assistant 回复记录(role=assistant, content=完整回复)
  - Verifiable via: `GET /api/chat/messages?session_id=X`
- UI observable:
  - 用户消息气泡显示原始输入"什么是细菌性肺炎?"
  - assistant 气泡渐进出现(流式),最终显示完整回复
  - 流式期间,发送按钮文本变为"生成中..."并 disabled
  - 流式结束后,发送按钮恢复(若 textarea 仍为空,则 disabled;textarea 有内容,则 enabled)

#### B2: 用户发送 Markdown 格式消息,前端正确渲染

**Preconditions**: 同 B1

**Trigger**

- Intent: 发送含 Markdown 标记的消息
- With: `message="请用列表回答:\n1. **重点 1**\n2. # 大标题"`

**Expected (eventually)**

- 用户消息气泡内:**重点 1** 渲染为加粗 `<strong>` 元素;# 大标题 渲染为 `<h1>`
- 列表项渲染为 `<ol>` / `<li>`
- 后端存储的是**原始 Markdown 字符串**(不是 HTML)
  *(来源: src/handlers/chat.js:42 — content 字段直存用户输入,无预处理)*

#### B3: assistant 流式回复包含 Markdown,实时渲染

**Preconditions**: 同 B1

**Trigger**

- Intent: 发送一个会让 LLM 用 Markdown 回复的问题
- With: `message="列出 3 种感冒药"`(假设 LLM 会用列表回复)

**Expected (eventually)**

- assistant 气泡的内容随 SSE delta 渐进出现
- **每个 delta 到达后**,Markdown 增量渲染——不是等流结束才一次性渲染
  *(来源: src/components/Bubble.vue:88 — markdown-it 在 watch(content) 中实时调用)*
- 流结束时,所有 Markdown 元素都正确渲染

#### B4: 网络中断时显示错误提示,流不挂起

**Preconditions**: 同 B1

**Trigger**

- Intent: 发送消息,但 SSE 流中途网络断开(或后端返回 error 事件)

**Expected (eventually)**

- assistant 气泡显示已收到的部分内容
- 气泡下方显示红色错误提示"连接中断,请重试"
- 发送按钮恢复为"发送"可点击(不会卡在"生成中...")
- Server state: messages 表中该 assistant 消息标记为 `status=error`(不影响后续 TC)

#### B5: textarea 为空时,发送按钮 disabled 不响应

**Preconditions**: 在 `/chat` 页面,textarea 为空(或仅含空白字符),**发送按钮 disabled**

**Trigger**

- Intent: 尝试点击发送按钮(因 disabled,实际无响应——这正是要测试的)
- With: textarea 内容为空字符串 / 仅空格 / 仅换行

**Expected (eventually)**

- 不发起任何 API 请求(无 SSE 连接、无网络流量)
- 发送按钮保持 disabled 视觉状态(灰色 / 不可点击)
- textarea 显示 placeholder 提示文字
- messages 表无新增

**逻辑依据** *(来源: src/components/ChatInput.vue:25)*: 按钮 disabled 属性绑定到
`computed(() => textarea.value.trim().length === 0)`。trim 后为空 → disabled。
这意味着**前端层完全阻止提交**,后端不会收到空消息请求。
**注意**:不存在"按钮可点 + 后端拒绝"的备选实现——本规约严格按"前端 disabled"语义。

### 2.2 Invariants

#### Client-side invariants

- **INV-C1**: textarea 在流式响应进行中**禁止再次提交**(防止 race)
  - Applies to: B1, B2, B3
- **INV-C2**: **streaming 状态进入后**(任何 behavior 触发了 SSE start 事件),
  用户消息气泡和 assistant 气泡**必须同时可见**——不能只显示一边
  - 适用范围:所有进入 streaming 状态的 behavior(B1 / B2 / B3 / B4 都覆盖,
    无论流是 done 正常结束还是 error 中断)
  - **逻辑依据**: src/components/ChatList.vue:35 — 发送时同时 push user 和 assistant 两条消息到 list,
    assistant 初始 content 为空,delta 事件追加。两条记录在 push 时就同时进入 list,
    任何后续状态(streaming/completed/error)都不会单独移除其中一条
- **INV-C3**: **渲染层对所有 content 必须经过 sanitize**——markdown-it 必须配置 `html: false`
  禁用 HTML 模式,或用 DOMPurify 等价 sanitize;**绝不允许**对原始 content 直接 `v-html` / `innerHTML` 注入
  - Applies to: 全局(任何渲染 messages.content 的地方)
  - **Verifiable via**: 注入测试——发送 `<script>alert(1)</script>` 等输入,验证页面**显示为字面字符串**
    且 alert **不被触发**(用 Playwright 监听 dialog 事件确认无对话框弹出)
  - **逻辑依据**: src/components/Bubble.vue:88 调用 `markdownIt({ html: false }).render(props.content)`,
    `html: false` 选项让 markdown-it 把 `<script>` 等 HTML 标签当作字面文本不解析
  - **可达性**: 所有 content 都走此渲染路径,无分支
  - **与 INV-S1 的关系**:INV-S1 明确"存储不转义"——这是有意的设计决策(保留原始字符串供导出 / API 消费),
    但**带来 XSS 风险必须由 INV-C3 在渲染层闭环防御**。两条 invariant 必须同时满足,
    单独任一条不足以保证安全:仅 S1 → 存储干净但渲染漏 XSS;仅 C3 → 渲染干净但攻击字符串可被
    其他途径(API、导出文件)取出后在不防御的客户端引发 XSS

#### Server-side invariants

- **INV-S1**: 任何用户输入(包括恶意 HTML / 脚本)在 messages 表中**原样存储**,不做转义
  - Applies to: 全局
  - **逻辑依据**: chat.js:42 直接 INSERT content,无 sanitize 调用
  - **可达性**: 无分支,所有输入都走此路径
  - **配套防御**:存储不转义带来 XSS 风险——必须配合 **INV-C3**(渲染层 sanitize)闭环防御
- **INV-S2**: assistant 回复中**不能包含敏感系统提示词**(如 LLM 的 system prompt 内容)
  - Applies to: B1, B2, B3
  - **逻辑依据**: src/services/llm.js:60 — 调 LLM 时 system prompt 在 messages[0],不会随 stream 返回客户端

#### Cross-cutting invariants

- **INV-X1**: 前端渲染的 Markdown 元素 **必须从原始 content 字符串派生**——
  不能在 content 之外加任何"前端注入"的内容
  - Applies to: B2, B3
  - **逻辑依据**: Bubble.vue 用 markdown-it 渲染 props.content,无其他数据源混入

## 3. Hints (SHOULD)

### 3.1 Boundary Values

- 字段 `message.length`:
  - 0:空消息,应被拒绝(B5)
  - 1:最小有效输入
  - 4000:常见 LLM 上下文限制附近
  - 4001:超过限制,后端应拒绝并返回 error
- 字段 `message.encoding`(测试输入字符种类):
  - 纯 ASCII / CJK / emoji / 零宽字符 / RTL 文字 / 混合

### 3.2 Decision Table

| 输入合法 | 网络正常 | LLM 服务可用 | 预期 behavior |
|--------|--------|------------|------------|
| ✅ | ✅ | ✅ | B1/B2/B3: 正常流式回复 |
| ❌(空) | * | * | B5: 按钮 disabled,不发起请求 |
| ✅ | ❌(中断) | * | B4: 流终止 + UI 恢复可交互(无断点续传) |
| ✅ | ✅ | ❌(LLM 5xx) | B4 类似:错误提示 + UI 恢复可交互 |

### 3.3 State Machine

适用于"单次对话流"生命周期:

- States: [idle, streaming, completed, error]
- Transitions:
  - idle → streaming: 触发于 B1/B2/B3 的 trigger
  - streaming → completed: 收到 done 事件
  - streaming → error: 收到 error 事件 / 网络断开 / 超时
  - completed → idle: 用户清空 textarea 准备下一条
  - error → idle: 用户点击重试或开始新消息
- **逻辑依据** *(来源: src/composables/useChat.ts)*: status 字段由 SSE 事件类型驱动,
  start → streaming, delta 不变状态, done → completed, error → error

### 3.4 Out of Scope

#### 3.4a 业务边界(真的不需要测)

- 历史会话切换(本规约范围外,会话管理是独立功能)
- 用户登录与权限(本规约不涉及)
- LLM 答复内容的临床/事实正确性(归属内容审核团队,不是 E2E 范围)

#### 3.4b 工程边界(该测但本期没法测)

- **流式渲染的逐字打字机视觉效果**
  - 不测理由:工具能力——LLM 看截图无法精准判断"字符是不是逐个出现"(只能看最终或某瞬间状态)
  - 已知风险:打字机效果坏掉用户体验差(变成一次性闪现),但不影响功能
  - 替代手段:在 TC 中间穿插 1-2 次截图判断"流到一半时确实只显示了部分内容"
  - 建议补救路径:用 Playwright 录制视频,人类抽样审

- **网络中断真实模拟**
  - 不测理由:工具能力——Browser Use 不便模拟网络中断
  - 已知风险:B4 (网络断开提示)可能在生产中表现与测试不一致
  - 替代手段:用 mock 后端返回 error 事件代替真实网络断开
  - 建议补救路径:下期用 Playwright 的 `route.abort()` 真实测试

### 3.5 Setup Strategy

按"全流程测试模式"——本规约从空白状态开始测,每个 TC 独立准备数据。

进入测试起点前,Operator 应:

1. 浏览器导航到 `/chat`(无登录态依赖)
2. 调用 `POST /test/reset-messages`(清空测试用户的历史消息,避免 TC 间污染)

#### 3.5b 环境隔离与 Mock 要求

- 必须 mock 的外部依赖:
  - **LLM 服务**:用 mock LLM 替代真实调用,返回可预测的回复
    - 配置:在测试环境设 `LLM_PROVIDER=mock`,`mock_responses` 指向 fixture 文件
    - 否则真实 LLM 每次返回不同内容,断言无法稳定
- 共享测试资源隔离:
  - messages 表使用独立 schema(`test_messages`),每轮测试前 reset
- 不可避免的不可逆操作:无(LLM mock 化后所有操作可重现)

## 4. Scenario Patterns

- 匹配的场景模式:
  - **对话型 UI**(textarea + 历史气泡 + 发送按钮)
  - **异步 / 流式输出**(SSE delta 事件渐进渲染)
  - **LLM agent 决策**(后端调用 LLM 生成回复)
  - **前端渲染保真度**(Markdown / emoji / 长文本截断 / 错误提示样式都需要 Agent 看截图判断)
  - **状态流转**(idle → streaming → completed/error)
  - **异常路径(通用)**(B4 网络中断、B5 空消息)

- 不匹配但容易误判的模式:
  - 不匹配"用户认证 / 会话管理"——本 chatbot 无登录(简化)
  - 不匹配"CRUD 列表与详情"——单条消息不构成 CRUD 列表
  - 不匹配"文件上传 / 下载"——本 chatbot 不支持文件附件

## 5. Meta

- Generated by: Cartographer (示例)
- Code commit: example-commit-hash
- Generated at: 2026-04-28T10:00:00Z
- Reviewed by human: yes
- Notes: 这是一个为了演示 skill 范式而手工撰写的样例,展示**轻量 chatbot 的规约**。
  对应的用例样例见 `chatbot-cases-example.md`,执行报告样例见 `chatbot-execution-report-example.md`。
