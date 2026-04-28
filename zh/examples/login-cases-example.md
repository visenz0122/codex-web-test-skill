# Test Cases: 用户登录

> 这是 `login-spec-example.md` 对应的测试用例样例。
> 展示用例文档的关键字段:Resource Dependency Matrix / Scenario Pattern Coverage Self-Check /
> Operator-mode / Screenshot points / Destructive。
> 为了简洁,这里只展示 5 个代表性 TC,真实情况下会有 10+ 个。

## Coverage Summary

| 路径类型 | 用例数 | 覆盖的 behavior |
|---------|------|----------------|
| 主路径 | 1 | B1 |
| 备选路径 | 0 | — |
| 异常路径 | 3 | B2, B3, B4 |
| 不变量验证 | 1 | INV-X1, INV-S1 |

## Resource Dependency Matrix

| 共享资源 | 破坏性 TC | 依赖 TC | 是否有 Teardown 恢复 | 备注 |
|---------|---------|--------|------------------|----|
| user_test (alice@example.com) | TC-004(状态变 locked) | TC-001, TC-002, TC-003 | ✓ TC-004 teardown 重置 locked_until=NULL | 闭环 |
| sessions 表 | TC-001(新增 session) | TC-005(验证 INV) | ✓ TC-001 teardown 删除该 session | 闭环 |
| rate_limit 计数器 | TC-002, TC-003(失败计数 +1) | TC-004(达 5 次锁定) | ⚠ 计数累积是预期行为(TC 之间故意累积) | 用例顺序 002→003→004 必须严格 |

矩阵显示 TC-002 / TC-003 / TC-004 之间存在**故意的累积依赖**——
为了测限流,需要前几次失败累积到 5 次。这种"故意依赖"在用例文档说明中说清楚即可,不算循环依赖。

## Scenario Pattern Coverage Self-Check

### 模式 1: 表单输入型(spec §4 标注)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 必填字段为空 | ✓ | TC-空字段(未列出,简化) |
| 等价类(有效输入代表) | ✓ | TC-001 |
| 等价类(无效输入代表:邮箱格式错) | ⚠ | 工具能力——前端 HTML5 type=email 校验阻断提交,后端不会收到无效邮箱 |
| 边界值(密码长度 8 / 64) | ⚠ | 本期未测——见 §3.4b 工程边界(密码强度实时反馈) |
| XSS 注入测试(`<script>` 输入) | ✗ | spec §3.4a 未列;但 INV-S2 间接覆盖(响应不暴露内部错误) |
| 表单 disabled 状态视觉切换 | ✓ | TC-004(账号锁定后按钮变灰,Operator-mode A) |

### 模式 2: 用户认证 / 会话管理(spec §4 标注)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 正常登录后 session cookie 存在 | ✓ | TC-001 |
| Cookie 安全标志(HttpOnly + Secure) | ✓ | TC-001(INV-C3 检查) |
| 错误密码不创建 session | ✓ | TC-002 |
| 限流(失败 N 次后锁定) | ✓ | TC-004 |
| 邮箱枚举攻击防护(响应不可区分) | ✓ | TC-005(测 INV-X1) |
| Logout 清除 session | OOS | spec §3.4a 范围外(本规约只测登录,不测登出) |

### 模式 3: 前端渲染保真度(spec §4 标注)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 错误提示文本渲染 | ✓ | TC-002, TC-003(LLM 截图判断错误提示样式) |
| 按钮 disabled 视觉切换 | ✓ | TC-004(LLM 截图判断按钮变灰) |
| 输入框 placeholder 文案 | ⚠ | 与登录核心功能无关,未单独测 |
| 第三方登录按钮(Apple / Google) | OOS | spec §3.4a 业务边界(本期不做 SSO) |

### 模式 4: 异常路径(通用)(spec §4 标注)

| 必查清单项 | 状态 | 对应 TC / 理由 |
|---------|----|----|
| 网络断开时的提示 | ⚠ | 工具能力——本期工具不便模拟网络中断;考虑 Playwright offline mode |
| 服务器 5xx 错误 | ⚠ | 同上,需要 mock |
| 限流(429)响应处理 | ✓ | TC-004 |

## Test Cases

### TC-001: 已注册用户用正确密码成功登录

- **Path type**: 主路径
- **References**: B1, INV-C1, INV-C3
- **Method applied**: Equivalence Partitioning - 有效输入代表
- **Destructive**: yes
- **Operator-mode**: B

<!-- 主路径只断言数据传递正确(URL / cookie / SQL),无视觉判断 → mode B 纯 Playwright -->

**Preconditions**

- Client state: 无 session cookie,URL 为 `/login`
- Server state: alice@example.com 存在,密码哈希匹配 Test1234!

**Setup actions**

1. 调用 `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. 浏览器清空 cookie + localStorage,导航到 `/login`

**Steps**

1. 浏览器在 email 输入框输入 `alice@example.com`
2. 在 password 输入框输入 `Test1234!`
3. 点击"登录"按钮

**Expected**

- 最终 URL 匹配 `/dashboard`
- 页面可见 "Welcome, Alice"
- SQL: `SELECT count(*) FROM sessions WHERE user_email='alice@example.com'` = 1
- **Cookie 验证**(via Playwright `context.cookies()`):
  - cookie 名 `session_token` 存在
  - `cookie.httpOnly === true`(HttpOnly 标志生效)
  - `cookie.secure === true`(Secure 标志生效)
  - **不要用** `document.cookie` 验证 — HttpOnly cookie 在 JS 中本来就读不到(见 INV-C3 注释)

**Teardown actions**

1. SQL: `DELETE FROM sessions WHERE user_email='alice@example.com'`
2. 重置该用户的 last_login_at(避免污染下个 TC)

**Invariant checks (auto-applied)**: INV-C1, INV-C2, INV-C3, INV-S1, INV-S3

---

### TC-002: 已注册用户用错误密码,看到错误提示

- **Path type**: 异常路径
- **References**: B2, INV-X1
- **Method applied**: Equivalence Partitioning - 错误密码代表
- **Destructive**: yes(失败计数器 +1)
- **Operator-mode**: C

<!-- 既要测后端"sessions 不新增"(数据),又要测前端"错误提示样式"(视觉) → mode C -->

**Screenshot points**

```yaml
- after_step: 3  # 点击登录按钮、错误提示出现后
  save_to: screenshots/TC-002-error-message.png
  llm_judges:
    - "页面是否显示了清晰的错误提示文字'邮箱或密码错误'?"
    - "错误提示是否使用了红色或警示色,与正文区分?"
    - "登录表单是否仍然可见,密码字段是否被清空?"
```

**Preconditions**

- Server state: alice@example.com 存在,失败计数 < 4

**Setup actions**

1. `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. `POST /test/reset-rate-limit?email=alice@example.com`
3. 浏览器清空 cookie,导航到 `/login`

**Steps**

1. 在 email 输入框输入 `alice@example.com`
2. 在 password 输入框输入 `WrongPassword`
3. 点击"登录"按钮

**Expected**

- URL 仍为 `/login`(未跳转)
- 无 session cookie
- 页面可见 "邮箱或密码错误"
- SQL: `SELECT count(*) FROM sessions WHERE user_email='alice@example.com'` = 0
- API: `GET /test/rate-limit?email=alice@example.com` 返回 `{ failed_count: 1 }`
- 截图判断见 Screenshot points

**Teardown actions**

1. `POST /test/reset-rate-limit?email=alice@example.com`(清失败计数)

---

### TC-003: 未注册邮箱登录,响应与 TC-002 不可区分

- **Path type**: 不变量验证
- **References**: B3, INV-X1
- **Method applied**: 测等价行为 invariant
- **Destructive**: yes(失败计数器 +1)
- **Operator-mode**: B

<!-- 纯数据断言:验证 response_status / body / time 与 TC-002 相同 → mode B -->

**Preconditions**

- Server state: ghost@example.com **不存在**

**Setup actions**

1. `POST /test/ensure-user-not-exists?email=ghost@example.com`
2. 浏览器清空 cookie,导航到 `/login`

**Steps**

1. 在 email 输入框输入 `ghost@example.com`
2. 在 password 输入框输入 `AnyPassword`
3. 点击"登录"按钮,**记录响应耗时**

**Expected**

- URL 仍为 `/login`
- 页面可见 "邮箱或密码错误"(与 TC-002 完全一致文本)
- API: `POST /api/auth/login` 响应 status = 401(与 TC-002 一致)
- API: 响应 body = `{"error": "Invalid credentials"}`(与 TC-002 一致)
- **响应耗时 vs TC-002 差异 < 100ms**(防时序攻击)
- SQL: 应用日志含 `ghost@example.com` 尝试记录(level=info)

**Teardown actions**

1. 无(用户本来就不存在,无需恢复)

---

### TC-004: 失败 5 次后账号锁定,按钮变灰

- **Path type**: 异常路径
- **References**: B4
- **Method applied**: Boundary Value Analysis - 边界 5
- **Destructive**: yes(用户状态变 locked)
- **Operator-mode**: C

<!-- 既要验证后端 locked_until 字段(数据),又要看按钮变灰视觉切换(渲染) → mode C -->

**Screenshot points**

```yaml
- after_step: 4  # 第 5 次失败响应到达后,锁定状态显示
  save_to: screenshots/TC-004-locked.png
  llm_judges:
    - "页面是否显示'账号已锁定,请 15 分钟后重试'?"
    - "登录按钮是否变成灰色 disabled 状态(视觉上明显比正常状态淡)?"
    - "鼠标悬停按钮时,是否仍可点击?(预期不可点击)"
```

**Preconditions**

- 失败计数器 = 4(已经失败 4 次,再失败 1 次即触发锁定 — 见 spec B4 修订版)

**Setup actions**

1. `POST /test/setup-user?email=alice@example.com&password=Test1234!`
2. `POST /test/set-rate-limit?email=alice@example.com&failed_count=4`
3. 浏览器清空 cookie,导航到 `/login`

**Steps**

1. 在 email 输入框输入 `alice@example.com`
2. 在 password 输入框输入 `WrongPassword`
3. 点击"登录"按钮(这是该用户的第 5 次失败 — 已 4 次基础上 + 本次)
4. 等待响应——本次响应即应触发锁定(不是"再点一次",是这次提交本身)

**Expected**

- 页面可见 "账号已锁定,请 15 分钟后重试"(**不是** "邮箱或密码错误")
- 登录按钮 `disabled` 属性为 true
- API: `GET /test/user-status?email=alice@example.com` 返回 `{ locked_until: <future timestamp> }`,
  且 `locked_until > now`
- API: `GET /test/rate-limit?email=alice@example.com` 返回 `{ failed_count: 5 }`(刚好达到阈值)
- 截图判断见 Screenshot points

**Teardown actions**

1. SQL: `UPDATE users SET locked_until=NULL WHERE email='alice@example.com'`
2. `POST /test/reset-rate-limit?email=alice@example.com`

---

### TC-005: 验证邮箱枚举防护(INV-X1 跨用例对比)

- **Path type**: 不变量验证
- **References**: INV-X1
- **Method applied**: Right-BICEP - Cross-check
- **Destructive**: no(只是对比 TC-002 和 TC-003 的结果)
- **Operator-mode**: B

<!-- 跨 TC 对比响应一致性,纯数据 → mode B -->

**Preconditions**

- TC-002 和 TC-003 已经跑过,有响应数据可对比

**Setup actions**

1. 加载 TC-002 的响应记录(status / body / time)
2. 加载 TC-003 的响应记录

**Steps**

1. 对比两次响应的 status:应该完全相等
2. 对比 response.body:应该完全相等
3. 对比 response_time:应该差异 < 100ms

**Expected**

- 两次响应在 status / body / time 三个维度完全不可区分
- 这是 INV-X1 的核心断言

**Teardown actions**

1. 无

---

## Boundary Value Coverage

| 字段 | 边界值 | 对应 TC | 备注 |
|----|------|------|----|
| password.length = 0 | 空字符串 | (未列出,简化) | 应被前端拒绝 |
| password.length = 8 | 最小有效长度 | TC-001 间接覆盖 | Test1234! 长度 9 |
| failed_count = 5 | 锁定阈值 | TC-004 | 重点 |

### Skipped boundaries

- `password.length = 65` 和 `1000`:未单独测,合并到"密码长度上限"测试中(简化)
- 理由:本规约重点是"登录核心",密码长度边界由密码校验组件单独测

## Decision Table Coverage

参考 spec §3.2,5 行决策表:

| 用户存在 | 密码正确 | 已锁定 | 预期 behavior | 对应 TC |
|--------|--------|------|------------|------|
| ✅ | ✅ | ❌ | B1: 登录成功 | TC-001 |
| ✅ | ❌ | ❌ | B2: 密码错误提示 | TC-002 |
| ❌ | * | ❌ | B3: 邮箱或密码错误 | TC-003 |
| ✅ | * | ✅ | B4: 账号锁定 | TC-004 |
| ❌ | * | ✅ | B4: 账号锁定(防御性) | (未测,理论不可能) |

## Inspector Feedback Log

(本样例假设 Inspector Round 1 给了 0 个 P0,3 个 P1,1 个 P2。
真实使用中这一段会列出 Inspector 的反馈和 Cartographer 的处理。简化省略。)

## Out of Scope (from Spec)

### 业务边界(从规约 §3.4a 复制)

- 短信二步验证 / SSO 登录 / Remember me / 邮件服务可达性

### 工程边界(从规约 §3.4b 复制)

- 密码强度实时反馈视觉变化
