# Test Cases: AI Chatbot 对话核心

> 这是 `chatbot-spec-example.md` 对应的测试用例样例。
> **核心展示**:Operator-mode A / B / C 三种全用上 + Screenshot points 完整格式。
> 为了简洁,只展示 4 个代表性 TC,真实情况下会有 8-10 个。

## Coverage Summary

| 路径类型 | 用例数 | 覆盖的 behavior |
|---------|------|----------------|
| 主路径 | 2 | B1, B2 |
| 备选路径 | 0 | — |
| 异常路径 | 2 | B4(中断), B5(空消息) |
| 不变量验证 | 1 | **TC-005**: INV-S1 + INV-C3(XSS 安全) |

## Resource Dependency Matrix

| 共享资源 | 破坏性 TC | 依赖 TC | 是否有 Teardown 恢复 | 备注 |
|---------|---------|--------|------------------|----|
| messages 表 | TC-001, TC-002, TC-003, TC-005(都新增消息) | 无(每个 TC 独立验证) | ✓ 每个 TC teardown 删除自己创建的记录 | 闭环 |
| LLM mock | 全部 TC(消费 mock 配额) | 全部 TC | ✓ mock 是无限响应,不消耗 | 闭环 |
| (TC-004 无破坏 — 不入此表) | — | — | — | — |

## Scenario Pattern Coverage Self-Check

### 模式 1: 对话型 UI

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 发送消息后 textarea 清空 | ✓ | TC-001 |
| 用户气泡 + assistant 气泡同时显示 | ✓ | TC-001(LLM 截图判断) |
| 流进行中禁止再次发送 | ✓ | TC-001 |
| 空消息拒绝 | ✓ | TC-004 |

### 模式 2: 异步 / 流式输出

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 流的 done 事件正确终结 | ✓ | TC-001 |
| 流中断有错误处理 | ✓ | TC-003 |
| 流式渲染逐字效果 | OOS | spec §3.4b 工程边界(LLM 看截图无法精准判断) |

### 模式 3: LLM agent 决策

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| LLM 输出存入 messages 表 | ✓ | TC-001(SQL verify) |
| system prompt 不泄漏到客户端 | ✓ | TC-005(INV-S2 测试) |
| LLM 答复内容的事实正确性 | OOS | spec §3.4a 业务边界(归内容审核团队) |

### 模式 4: 前端渲染保真度(关键模式 — 必须用 Operator-mode C)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| Markdown 粗体 / 标题渲染 | ✓ | TC-002(LLM 截图判断) |
| Markdown 列表渲染 | ✓ | TC-002 |
| **HTML 转义安全(`<script>` 输入不执行)** | ✓ | **TC-005(INV-S1 + INV-C3 联合验证)** |
| **属性注入防护(`<img onerror>`)** | ✓ | **TC-005** |
| emoji 显示无方块 / 问号 | ⚠ | 本期未单独测;建议下期补 emoji 专项 TC |
| 长文本不溢出气泡 | ⚠ | 同上 |
| 时区显示符合用户区域 | OOS | 本 chatbot 不显示时间戳 |
| 错误提示视觉(红色/警示色) | ✓ | TC-003(LLM 截图判断) |

### 模式 5: 状态流转

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| idle → streaming → completed | ✓ | TC-001(发送按钮文本变化) |
| streaming → error 转移 | ✓ | TC-003 |
| 错误后回到 idle 可重试 | ✓ | TC-003 末尾 |

### 模式 6: 异常路径(通用)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 网络中断 | ⚠ | spec §3.4b 工程边界(无法真实模拟,用 mock 替代) |
| LLM 服务 5xx | ✓ | TC-003(mock 返回 error 事件) |
| 输入校验(空消息) | ✓ | TC-004 |

## Test Cases

### TC-001: 用户发送普通消息,看到完整流式回复

- **Path type**: 主路径
- **References**: B1, INV-C1, INV-C2
- **Method applied**: Equivalence Partitioning - 有效输入代表
- **Destructive**: yes(新增 messages 记录)
- **Operator-mode**: C

<!--
mode C:
- 数据维度:验证 messages 表新增、textarea 清空(Playwright 精确)
- 视觉维度:验证用户气泡 + assistant 气泡同时显示、发送按钮在流中变"生成中..."(LLM 截图判断)
两者都需要 → C
-->

**Screenshot points**

```yaml
- after_step: 4  # 流刚开始(SSE start 事件后,delta 还在累积)
  save_to: screenshots/TC-001-streaming.png
  llm_judges:
    - "页面是否同时显示了用户气泡(右侧)和 assistant 气泡(左侧)?"
    - "发送按钮文字是否变成了'生成中...',且呈 disabled 灰色状态?"
    - "textarea 是否已被清空?"

- after_step: 5  # 流结束后
  save_to: screenshots/TC-001-completed.png
  llm_judges:
    - "assistant 气泡内是否显示了完整回复内容(无截断)?"
    - "发送按钮是否恢复为'发送'文字,且为可点击状态?"
    - "整体气泡布局是否正常,无文字溢出?"
```

**Preconditions**

- 浏览器在 `/chat` 页面,textarea 为空
- LLM mock 配置返回固定回复:"细菌性肺炎是由细菌引起的肺部感染..."(完整 200 字回复)

**Setup actions**

1. 调用 `POST /test/reset-messages`(清空消息表)
2. 调用 `POST /test/configure-llm-mock?response=fixture://pneumonia-answer.txt`
3. 浏览器导航到 `/chat`

**Steps**

1. 浏览器在 textarea 输入 "什么是细菌性肺炎?"
2. 点击发送按钮
3. 等待 SSE start 事件(URL 监听 `/api/chat/stream`)
4. **截图节点 1**:流进行中(start 事件后约 200ms)
5. 等待 SSE done 事件(最多 30 秒)— **截图节点 2**:流结束

**Expected**

- textarea 被清空
- assistant 气泡显示完整回复 "细菌性肺炎是由细菌引起的肺部感染..."
- SQL: `SELECT count(*) FROM messages WHERE session_id=current` = 2(user + assistant 各一条)
- SQL: user 消息 content = "什么是细菌性肺炎?",assistant 消息 content = mock 配置的完整回复
- 截图判断结果见 Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

**Invariant checks (auto-applied)**: INV-C1, INV-C2, INV-S1, INV-S2

---

### TC-002: 发送 Markdown 消息,前端正确渲染

- **Path type**: 主路径
- **References**: B2, INV-S1, INV-X1
- **Method applied**: 场景模式 "前端渲染保真度" 直接测试
- **Destructive**: yes
- **Operator-mode**: C

<!--
本 TC 是混合模式的**典型代表**——
后端要 verify 存储的是原始 Markdown 字符串(数据);
前端要看 Markdown 是否真的渲染为粗体 / 标题 / 列表(视觉)。
单纯 Playwright 检查 <strong> 元素能查"渲染了吗",但抓不到"字体加粗了吗"——必须 LLM 看截图。
-->

**Screenshot points**

```yaml
- after_step: 5  # 流结束,完整渲染后
  save_to: screenshots/TC-002-markdown.png
  llm_judges:
    - "用户气泡内的 **重点 1** 是否真的渲染为粗体(字体明显比正文粗)?"
    - "用户气泡内的 # 大标题 是否渲染为大字标题(字号明显大于正文,无 # 字符)?"
    - "列表项 1. 和 2. 是否渲染为有序列表(有序号 + 缩进)?"
    - "整体气泡布局是否正常,Markdown 元素之间间距合理?"
```

**Preconditions**: 同 TC-001

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?response="收到您的列表"`(简单回复,本 TC 重点测用户输入渲染)
3. 浏览器导航到 `/chat`

**Steps**

1. 在 textarea 输入:
   ```
   请用列表回答:
   1. **重点 1**
   2. # 大标题
   ```
2. 点击发送按钮
3. 等待流结束
4. **截图节点**:对照判断渲染结果

**Expected**

- SQL: 用户消息 content **原样存储**为 Markdown 字符串(包含 `**` `#` `1.` `2.` 等字面字符)——
  这是 INV-S1 的关键断言,后端不做转义
- 前端 DOM:用户气泡内含 `<strong>` 元素 `<h1>` 元素 `<ol><li>` 列表
- 截图判断:见 Screenshot points(LLM 视觉确认渲染保真度)

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`

---

### TC-003: 流式响应中途出错,显示错误提示

- **Path type**: 异常路径
- **References**: B4
- **Method applied**: State Transition - streaming → error
- **Destructive**: yes
- **Operator-mode**: C

<!--
mode C:
- 数据维度:验证 SSE error 事件后端记录、消息状态变 error(SQL)
- 视觉维度:错误提示样式(红色)、按钮恢复样式(LLM 看截图)
-->

**Screenshot points**

```yaml
- after_step: 5  # 流中断后页面状态
  save_to: screenshots/TC-003-error.png
  llm_judges:
    - "页面是否显示了红色或警示色的错误提示文字'连接中断,请重试'?"
    - "已经收到的部分 assistant 内容是否仍然可见(没消失)?"
    - "发送按钮是否恢复为'发送'状态,可再次点击?"
```

**Preconditions**: 同 TC-001

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?mode=error_after_2_chunks`
   (mock 配置:发完 2 个 delta 后返回 error 事件)
3. 浏览器导航到 `/chat`

**Steps**

1. 在 textarea 输入 "测试一下"
2. 点击发送
3. 等待第 2 个 delta 事件
4. mock 返回 error 事件(自动触发,无需 Operator 操作)
5. **截图节点**:错误提示出现后

**Expected**

- 错误提示 "连接中断,请重试" 可见
- 已收到的部分 assistant 内容(2 chunks)仍可见
- 发送按钮恢复 "发送" 文字,可再次点击
- SQL: assistant 消息 status = 'error'
- 截图判断结果见 Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

---

### TC-004: 空消息发送被拒(纯前端校验)

- **Path type**: 异常路径
- **References**: B5
- **Method applied**: Boundary Value - length=0
- **Destructive**: no
- **Operator-mode**: A

<!--
mode A 纯 LLM 浏览器:
- 测点完全是视觉/交互层(发送按钮 disabled、placeholder 提示),无后端数据传递
- 不需要 Playwright,直接 LLM 看截图判断更直观
-->

**Screenshot points**

```yaml
- after_step: 1  # 进入 /chat 页面后
  save_to: screenshots/TC-004-empty-textarea.png
  llm_judges:
    - "textarea 是否显示了 placeholder 提示文字(浅灰色)?"
    - "发送按钮是否处于 disabled 灰色状态?"

- after_step: 2  # 输入空格后
  save_to: screenshots/TC-004-whitespace.png
  llm_judges:
    - "textarea 是否仍然被识别为'空'?(发送按钮仍 disabled)"
    - "如果用户继续输入空格,按钮是否一直保持 disabled?"
```

**Preconditions**: 浏览器在 `/chat`,textarea 为空

**Setup actions**

1. 浏览器导航到 `/chat`(不发任何消息)

**Steps**

1. 观察 textarea 初始状态(空 + 显示 placeholder + 按钮 disabled)
2. 在 textarea 输入 "   "(3 个空格)— 验证按钮仍 disabled(因 trim 后为空)
3. 尝试点击发送按钮 — **由于 disabled,应无任何反应**(不是"被前端校验拒绝")

**Expected**

- 步骤 1:截图判断 textarea 显示 placeholder,按钮 disabled
- 步骤 2:截图判断按钮仍 disabled(空格 trim 后为空,符合 B5 逻辑依据)
- 步骤 3:点击 **完全无反应**——
  - 无网络请求发出(开发者工具 Network 面板无新请求,可由 LLM 截图判断或 Playwright 拦截)
  - 无任何 UI 变化(无 loading 状态、无错误提示、无新气泡)
- SQL: messages 表无新增

**注意**:本 TC 测的不是"按钮可点+前端拒绝",而是"按钮 disabled+点击无反应"——
两者都阻止了空消息发送,但**用户体验不同**,规约 B5 严格选择前者(见 spec B5 末尾的"逻辑依据"说明)。

**Teardown actions**

1. 无(本 TC 没破坏任何状态)

---

### TC-005: XSS 注入测试(渲染层 sanitize 验证)

- **Path type**: 不变量验证
- **References**: INV-S1, INV-C3
- **Method applied**: 安全测试 — 注入攻击向量
- **Destructive**: yes(新增 messages 记录,含恶意字符串)
- **Operator-mode**: C

<!--
mode C:
- 数据维度:验证 INV-S1 后端原样存储 `<script>` 字符串(SQL 查 content)
- 视觉维度:验证 INV-C3 渲染层 sanitize,页面**显示为字面字符串**且 alert **不弹出**(LLM 截图 + 监听 dialog 事件)

这是混合模式抓"DOM 通过 ≠ 视觉通过"和"存储 vs 渲染分层防御"的标准范例。
-->

**Screenshot points**

```yaml
- after_step: 4  # 流结束、消息渲染后
  save_to: screenshots/TC-005-xss-rendered.png
  llm_judges:
    - "用户气泡内是否将 `<script>alert(1)</script>` 显示为**字面字符串**(即看得到 `<` `>` 这些字符,而不是被解析为 HTML 标签消失)?"
    - "页面上是否**没有**弹出任何 alert 对话框?(应该是没有)"
    - "如果用户气泡里看不见 `<script>` 字符,说明 HTML 标签被解析了——这是 XSS 漏洞的视觉信号"
```

**Preconditions**

- 浏览器在 `/chat`,无未完成的流
- LLM mock 返回普通回复(本 TC 重点测**用户输入的渲染**,不测 LLM 输出)

**Setup actions**

1. `POST /test/reset-messages`
2. `POST /test/configure-llm-mock?response="收到"`
3. 浏览器导航到 `/chat`
4. **Playwright 监听 `dialog` 事件**——任何 alert/confirm/prompt 弹窗都应被捕获(`page.on('dialog', ...)`)

**Steps**

1. 在 textarea 输入恶意字符串:`<script>alert(1)</script>` 后跟 `<img src=x onerror=alert(2)>`
2. 点击发送按钮
3. 等待 SSE 流结束(LLM 回复"收到"也是流式)
4. **截图节点**:消息渲染完成后

**Expected**

- **后端断言(INV-S1)**:
  - SQL: `SELECT content FROM messages WHERE role='user' ORDER BY id DESC LIMIT 1`
  - 返回字符串**完全等于**输入(包含 `<script>` `<img>` 等原始字符,无转义、无替换)
- **前端 DOM 断言(INV-C3 第一层)**:
  - 用户气泡 DOM 内**不应**含 `<script>` 元素(被 markdown-it 当字面文本)
  - 用户气泡 DOM 内**不应**含 `<img onerror>` 元素(被 markdown-it 当字面文本)
  - 用户气泡的 textContent 包含 `<script>alert(1)</script>` 字符串(说明被当字面渲染)
- **运行时断言(INV-C3 第二层 — 关键)**:
  - **Playwright dialog 事件监听器**应**未触发**(整个 TC 期间无 alert/confirm/prompt 弹出)
  - 浏览器控制台**无** `alert` 调用记录
- **视觉判断**:见 Screenshot points

**Teardown actions**

1. SQL: `DELETE FROM messages WHERE session_id=current`
2. `POST /test/reset-llm-mock`

**预期结果说明**

- 如果**全部 PASSED**:存储和渲染分层防御都生效,XSS 不可达
- 如果**SQL 通过但 DOM 含 `<script>` 元素**:INV-S1 OK,**INV-C3 失败**——markdown-it 没禁 HTML 模式,
  这是真实的 XSS 漏洞,生产中可被利用
- 如果**dialog 事件被触发**:已经被 XSS 攻击,严重 P0 安全 bug

---

## Boundary Value Coverage

| 字段 | 边界值 | 对应 TC | 备注 |
|----|------|------|----|
| message.length = 0 | 空字符串 | TC-004 | 应被拒绝 |
| message.length 含纯空格 | "   " | TC-004 | 等同空 |
| message.length = 1 | 单字符 | (合并到 TC-001) | 简化 |
| message.length = 4000 | 上限附近 | (未列出) | 简化 |

### Skipped boundaries

- `message.length = 4001`(超长被拒):未单独测,合并到"输入校验"中
- 理由:本规约重点是对话核心,极端长度由后端校验组件单独测

## Decision Table Coverage

| 输入合法 | 网络正常 | LLM 可用 | behavior | 对应 TC |
|--------|--------|--------|--------|------|
| ✅ | ✅ | ✅ | B1/B2 | TC-001, TC-002 |
| ❌(空) | * | * | B5 | TC-004 |
| ✅ | ❌ | * | B4 | TC-003(用 mock 模拟) |

## Inspector Feedback Log

(本样例假设 Inspector 给了 0 个 P0,2 个 P1。简化省略具体反馈内容。)

## Out of Scope (from Spec)

### 业务边界(从规约 §3.4a 复制)

- 历史会话切换
- 用户登录与权限
- LLM 答复内容的临床/事实正确性

### 工程边界(从规约 §3.4b 复制)

- 流式渲染的逐字打字机视觉效果
- 网络中断真实模拟(用 mock 替代)
