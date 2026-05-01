# Execution Report: AI Chatbot 对话核心

> 这是 `chatbot-cases-example.md` 对应的执行报告样例。
> **核心展示**:Codex-tool-plan、viewport evidence、Playwright trace、Screenshot Review 和 Coordinator Final Review 在实际报告中长什么样。
> 真实情况下 4 个 TC 全跑完会更长,这里只展示 2 个 TC 的细节,其他 TC 简略。

## Summary

- **Total**: 4 TCs
- **Passed**: 2 (TC-001, TC-004)
- **Failed**: 2 (TC-002 渲染问题, TC-003 错误提示样式问题)
- **Skipped**: 0
- **Duration**: 6m 12s
- **Setup status**: ✅ 成功
- **Teardown status**: ✅ 全部恢复

## Setup Phase

- 调用 `POST /test/reset-messages` → 200 ✅
- 配置 LLM mock → 200 ✅
- 浏览器导航 `/chat` → 200 ✅

## Environment

- 浏览器:Codex Browser Use / Playwright Chromium
- 测试目标 URL:http://localhost:3000/chat
- LLM mock:启用,fixture 路径 `tests/fixtures/pneumonia-answer.txt`
- Viewport target:desktop 1280x800
- Viewport actual:1280x800
- Viewport evidence note:所有桌面布局判断均来自 1280x800;未使用小 Codex 窗口截图作为桌面失败证据

## Results

### TC-001: 用户发送普通消息,看到完整流式回复

- **Status**: ✅ PASSED
- **Duration**: 24.3s
- **References**: B1, INV-C1, INV-C2
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport actual**: 1280x800

**Steps executed**

1. ✅ 浏览器导航到 `/chat`
2. ✅ 在 textarea 输入"什么是细菌性肺炎?"
3. ✅ 点击发送按钮,记录到 SSE start 事件
4. ✅ 截图节点 1:`screenshots/TC-001-streaming.png`
5. ✅ 等待 SSE done 事件(实际耗时 23.8s)— 截图节点 2:`screenshots/TC-001-completed.png`

**Observations**

- Final URL: /chat
- textarea 状态:空(已被清空)
- 收到 SSE 事件序列:start → delta×42 → done

**Playwright trace 摘要**

- 脚本路径:`tests/generated/TC-001.spec.ts`
- 执行命令:`npx playwright test tests/generated/TC-001.spec.ts`
- 通过的 assertion:8 项
  - `await expect(page.locator('textarea')).toBeEmpty()` ✅
  - `await expect(page.locator('.user-bubble').last()).toContainText('什么是细菌性肺炎?')` ✅
  - `await expect(page.locator('.assistant-bubble').last()).toBeVisible()` ✅
  - SQL: 2 条消息记录 ✅
  - (其他 4 项 SQL / cookie 验证)
- 失败的 assertion:0 项
- Trace 文件:`test-results/TC-001/trace.zip`

**LLM 截图判断**

| 截图 | 判断问题 | 结果 | 描述 |
|----|--------|----|----|
| TC-001-streaming.png | 用户气泡 + assistant 气泡同时显示? | ✅ | 两侧气泡均可见,对齐合理 |
| TC-001-streaming.png | 发送按钮变"生成中..."且 disabled? | ✅ | 按钮文字"生成中...",颜色变浅灰 |
| TC-001-streaming.png | textarea 已清空? | ✅ | 完全清空,显示 placeholder |
| TC-001-completed.png | assistant 气泡显示完整回复? | ✅ | 200 字回复完整可见 |
| TC-001-completed.png | 发送按钮恢复为"发送"可点击? | ✅ | 按钮文字"发送",颜色为正常蓝色 |
| TC-001-completed.png | 整体气泡布局正常,无文字溢出? | ✅ | 长文本正常折行,无溢出 |

**Invariant checks**

- INV-C1 (textarea 流中禁止再次提交): ✅ 通过(尝试在流中再次点击发送,无效果)
- INV-C2 (用户气泡和 assistant 气泡同时可见): ✅ 通过(见截图 TC-001-streaming)
- INV-S1 (用户输入原样存储): ✅ 通过(SQL 查到原始字符串)
- INV-S2 (system prompt 不泄漏): ⚠️ 无法直接验证(需要看 LLM mock 内部),依赖人类对照代码

**Anomalies**: 无

---

### TC-002: 发送 Markdown 消息,前端正确渲染

- **Status**: ❌ FAILED(2/4 视觉判断未通过)
- **Duration**: 18.7s
- **References**: B2, INV-S1, INV-X1
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script + Supabase Verify
- **Viewport actual**: 1280x800

**Steps executed**

1. ✅ 浏览器导航到 `/chat`
2. ✅ 在 textarea 输入 Markdown 消息(`**重点 1**\n# 大标题`)
3. ✅ 点击发送按钮
4. ✅ 等待流结束(2.4s)
5. ✅ 截图节点:`screenshots/TC-002-markdown.png`

**Observations**

- 用户消息气泡 DOM 含 `<strong>` 元素 ✅
- 用户消息气泡 DOM 含 `<h1>` 元素 ✅
- 用户消息气泡 DOM 含 `<ol>` 和 `<li>` 元素 ✅
- SQL 验证:用户消息 content 字段原样存储为 Markdown 字符串 ✅

**Playwright trace 摘要**

- 脚本路径:`tests/generated/TC-002.spec.ts`
- 通过的 assertion:6 项
  - DOM 含 strong / h1 / ol / li 元素 ✅
  - SQL content 字段原样字符串 ✅
- 失败的 assertion:0 项
- Trace 文件:`test-results/TC-002/trace.zip`

**LLM 截图判断**

| 截图 | 判断问题 | 结果 | 描述 |
|----|--------|----|----|
| TC-002-markdown.png | **重点 1** 渲染为粗体(明显比正文粗)? | ❌ | DOM 里有 `<strong>` 元素,但 CSS `font-weight: bold` 失效——视觉上和正文一样粗。**疑似前端 bug:CSS 加载顺序或样式被覆盖** |
| TC-002-markdown.png | # 大标题 渲染为大字标题(字号明显大于正文)? | ❌ | `<h1>` 元素存在,但实际字号只比正文大 1px,几乎无视觉差异。**疑似前端 bug:h1 样式被全局重置覆盖** |
| TC-002-markdown.png | 列表项 1. / 2. 渲染为有序列表? | ✅ | 序号正确显示,缩进合理 |
| TC-002-markdown.png | 整体气泡布局正常,Markdown 元素间距合理? | ✅ | 整体布局 OK |

**Invariant checks**

- INV-S1 (用户输入原样存储): ✅ 通过(SQL 验证)
- INV-X1 (前端渲染从 content 派生): ✅ 通过(DOM 元素和 content 一致)

**Anomalies**

- ⚠️ **重要**:DOM 通过但视觉失败——这是典型的"前端渲染保真度"问题。
  Playwright 单独跑会通过(因为它只检查 `<strong>` / `<h1>` 元素存在),
  但用户实际看到的是**未加粗的"重点 1"和不大的"大标题"**。
  这种 bug 只能通过 Screenshot Review 抓到——证明了 Browser Use / Playwright / Screenshot Review 组合的价值。

**对开发的归因建议**

- 检查全局 CSS 是否覆盖了 `<strong>` 和 `<h1>` 样式
- 检查 Markdown 渲染容器的 CSS scope 是否生效
- 用浏览器开发者工具的"Computed"面板查 `<strong>` 元素实际 font-weight 值

---

### TC-003: 流式响应中途出错,显示错误提示

- **Status**: ❌ FAILED(1/3 视觉判断未通过)
- **Duration**: 8.2s
- **Codex-tool-plan used**: Browser Use + Screenshot Review + Playwright Script
- **Viewport actual**: 1280x800

**Playwright trace 摘要**

- 通过的 assertion:5 项(SSE error 事件接收 + status 字段更新等)
- 失败的 assertion:0 项

**LLM 截图判断**

| 截图 | 判断问题 | 结果 | 描述 |
|----|--------|----|----|
| TC-003-error.png | 错误提示是红色或警示色? | ❌ | 文字"连接中断,请重试"出现,但**颜色是普通灰色**(和正文同色),用户难以注意到这是错误。**疑似前端 bug:错误样式 class 没应用** |
| TC-003-error.png | 已收到的部分 assistant 内容仍可见? | ✅ | 已显示的 2 chunks 内容仍在 |
| TC-003-error.png | 发送按钮恢复"发送"可点击? | ✅ | 按钮已恢复 |

**对开发的归因建议**

- 检查 `.error-message` class 的 CSS 是否生效
- 检查错误提示组件是否正确传入了 type="error" prop

---

### TC-004: 空消息发送被拒

- **Status**: ✅ PASSED
- **Duration**: 1.8s
- **Codex-tool-plan used**: Browser Use + Screenshot Review
- **Viewport actual**: 1280x800

**Playwright trace 摘要**

不适用(本 TC 使用 Browser Use + Screenshot Review,无 Playwright 脚本)。

**LLM 截图判断**

| 截图 | 判断问题 | 结果 |
|----|--------|----|
| TC-004-empty-textarea.png | textarea 显示 placeholder? | ✅ |
| TC-004-empty-textarea.png | 发送按钮 disabled? | ✅ |
| TC-004-whitespace.png | 输入空格后按钮仍 disabled? | ✅ |

**Anomalies**: 无

---

## Anomalies Aggregated

### 致命级

无

### 重要级

- **TC-002**:Markdown 粗体和标题视觉样式失效——DOM 通过但视觉错。可能影响所有用户的 Markdown 阅读体验。
- **TC-003**:错误提示颜色未应用警示色——用户可能错过错误提示,以为消息发送成功。

### 轻微级

- 无

## Viewport Evidence

| 用途 | 目标 viewport | 实际 viewport | 证据路径 | 结论边界 |
|---|---:|---:|---|---|
| 桌面聊天布局 | 1280x800 | 1280x800 | `screenshots/TC-001-completed.png` | 可作为 desktop 证据 |
| Markdown 渲染 | 1280x800 | 1280x800 | `screenshots/TC-002-markdown.png` | 可作为 desktop 证据 |
| 错误提示样式 | 1280x800 | 1280x800 | `screenshots/TC-003-error.png` | 可作为 desktop 证据 |

本轮没有把小 Codex 窗口截图用于桌面布局失败判断。

## Skipped Test Cases

无

## What Operator Did Not Do

- **INV-S2(system prompt 不泄漏)**:Operator 无法直接验证 LLM mock 内部行为,
  依赖人类对照 `src/services/llm.js` 代码确认。
- **流式渲染逐字打字机效果**:按 spec §3.4b 工程边界,本期未测。
- **emoji / 长文本边界**:未单独测(在场景模式自检表标 ⚠,本期不测)。
- **小窗口截图结论**:未把 Codex 小窗口截图当作 desktop 布局 bug 证据。

## Failure Classification Draft

| 发现 | 分类 | 证据 | 复测建议 |
|---|---|---|---|
| TC-002 Markdown 粗体 / 标题视觉样式失效 | product bug | DOM 通过,1280x800 截图视觉失败 | 修 CSS 后复跑 TC-002 |
| TC-003 错误提示颜色未应用警示色 | product bug | 1280x800 截图中错误文本为普通灰色 | 修错误样式后复跑 TC-003 |
| INV-S2 不能直接验证 | needs manual review | Operator 无 LLM mock 内部事实源 | 人类对照服务端 prompt 注入逻辑 |

## Coordinator Final Review

- **整体结论**:Full Flow Test 完成;2 个 product bug,0 个 test script bug,0 个 environment/setup issue。
- **工具边界**:网页触发动作均由 Browser Use / Playwright UI 操作完成;没有用 API 替代用户点击。
- **Viewport 结论**:所有视觉失败来自 1280x800 desktop 证据,不是 Codex 小窗口误判。
- **复测优先级**:先复测 TC-002 / TC-003;若修复范围涉及 Markdown 容器,补跑 TC-001 防回归。

## 下一步建议

1. **优先修 TC-002 / TC-003 的视觉 bug**——影响用户体验,但 Playwright 单跑会漏报
2. 修完后**重新跑这两个 TC** 确认视觉 bug 解决(只跑 2 个 TC,token 成本低)
3. 考虑给 emoji / 长文本场景加专项 TC——本轮已在自检表标 ⚠,可下一轮补
