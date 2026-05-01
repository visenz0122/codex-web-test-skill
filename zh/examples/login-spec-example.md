# Feature: 用户登录

> 这是一个**样例**,展示按 codex-web-test skill 范式设计的规约长什么样。
> Cartographer 在阶段 1 生成规约时可以参考这个样例的结构。
> 注意:这份样例假设了一个虚构的产品,描述的字段值仅作演示。

## 1. Interface

### 1.1 Routes

- `/login` — 登录页,未登录访问其他需登录页面会被重定向至此
- `/dashboard` — 登录后默认页,需登录态访问

### 1.2 API Endpoints

- `POST /api/auth/login` — 请求 `{ email, password }`,响应 `200 | 401 | 429`
- `POST /api/auth/logout` — 需 session cookie,响应 `200`
- `GET /api/auth/me` — 探针接口,需 session cookie,响应 `200 { user_id, email } | 401`

## 2. Constraints (MUST)

### 2.1 Behaviors

#### B1: 已注册用户用正确密码成功登录

**Preconditions**

- Client state:
  - 无 session cookie
  - 当前 URL 为 `/login`
- Server state:
  - 数据库 users 表存在 email=`alice@example.com`、密码哈希匹配 `Test1234!` 的用户
  - 该用户 status=`active`
  - 限流计数器:该 email 1 小时内失败登录次数 < 5

**Trigger**

- Intent: 提交登录表单
- With: `email=alice@example.com, password=Test1234!`

**Expected (eventually)**

- Client state after:
  - URL 匹配 `/dashboard`
  - cookie `session_token` 存在,HttpOnly=true,Secure=true
- Server state after:
  - 数据库 sessions 表新增一条 user_id 对应的记录
  - 该 user 的 last_login_at 字段更新为当前时间
  - Verifiable via: `GET /api/auth/me` 返回 200 + 该用户信息
- UI observable:
  - Visible text: "Welcome, Alice"
  - Visible elements: 登出按钮、用户菜单
- Not observable:
  - 文本 "Login failed" / "Invalid credentials" / "Error" 不应出现

#### B2: 已注册用户用错误密码登录失败

**Preconditions**

- Client state:
  - 无 session cookie
  - 当前 URL 为 `/login`
- Server state:
  - users 表存在 email=`alice@example.com` 的用户
  - 限流计数器:该 email 1 小时内失败登录次数 < 5

**Trigger**

- Intent: 提交登录表单
- With: `email=alice@example.com, password=WrongPassword`

**Expected (eventually)**

- Client state after:
  - URL 仍为 `/login`(未跳转)
  - 无 session cookie
- Server state after:
  - sessions 表无新增记录
  - 该 email 的失败登录计数器 +1
  - Verifiable via: 内部 API `GET /test/rate-limit?email=alice@example.com`(test endpoint)
- UI observable:
  - Visible text: "邮箱或密码错误"
  - Visible elements: 登录表单仍可见
- Not observable:
  - 不应区分是"邮箱不存在"还是"密码错误"(见 INV-X1)

#### B3: 未注册邮箱登录,响应与 B2 一致

**Preconditions**

- Client state:
  - 无 session cookie
- Server state:
  - users 表**不存在** email=`ghost@example.com` 的用户

**Trigger**

- Intent: 提交登录表单
- With: `email=ghost@example.com, password=AnyPassword`

**Expected (eventually)**

- Client state after:
  - URL 仍为 `/login`
  - 无 session cookie
- Server state after:
  - sessions 表无新增
  - 应用日志记录该次尝试(level=info)
  - Verifiable via: 应用日志 grep `ghost@example.com`
- UI observable:
  - Visible text: "邮箱或密码错误"(与 B2 完全一致)

#### B4: 失败 5 次后,该次响应即触发账号锁定 15 分钟

**Preconditions**

- Client state:
  - 无 session cookie
- Server state:
  - users 表存在 email=`alice@example.com`
  - 限流计数器:该 email 1 小时内**已失败 4 次**(再失败 1 次就达到阈值)

**Trigger**

- Intent: 第 5 次提交错误密码登录(无论密码对错都会被锁;为了触发,这次提交错密码)
- With: `email=alice@example.com, password=WrongPassword`

**Expected (eventually)**

- Client state after:
  - URL 仍为 `/login`
- Server state after:
  - sessions 表无新增
  - **该次响应即触发锁定**:该 email 的 `locked_until=now+15min` 被写入 users 表
  - 失败计数器最终值为 5
  - Verifiable via: `GET /test/user-status?email=alice@example.com` 应返回 `{ locked_until: <future timestamp> }`
- UI observable:
  - Visible text: "账号已锁定,请 15 分钟后重试"(注意:**不是** "邮箱或密码错误")
  - 登录按钮变灰禁用
- **逻辑依据** *(来源: src/api/auth.js:55-72,src/services/rate-limit.js:20)*:
  rate-limit.js 的 `recordFailure(email)` 函数在递增计数后 **立刻判断**:
  `if (newCount >= 5) { setLockedUntil(email, now+15min); }`。
  所以是"第 5 次失败本身触发锁定",不是"第 6 次被拒绝"。
- **可达性**: 失败次数 = 4 时再次提交,无论密码对错(锁定不区分),
  都走"先递增到 5,然后立即锁定"的路径

#### B5: 登录后访问 /dashboard

**Preconditions**

- Client state:
  - cookie `session_token` 有效(对应 alice@example.com)
- Server state:
  - sessions 表存在该 token

**Trigger**

- Intent: 访问 `/dashboard`

**Expected (eventually)**

- Client state after:
  - URL 仍为 `/dashboard`(无重定向)
- UI observable:
  - Visible text: "Welcome, Alice"
- Not observable:
  - 不应跳转到 `/login`

#### B6: 未登录访问 /dashboard 跳转登录页

**Preconditions**

- Client state:
  - 无 session cookie

**Trigger**

- Intent: 访问 `/dashboard`

**Expected (eventually)**

- Client state after:
  - URL 重定向到 `/login?redirect=/dashboard`
- UI observable:
  - Visible text: 登录表单可见

### 2.2 Invariants

#### Client-side invariants

- **INV-C1**: 任何时候,密码字段值不出现在 URL 中(query 或 path)
  - Applies to: all
- **INV-C2**: 任何时候,密码字段值不出现在 localStorage / sessionStorage 中
  - Applies to: all
- **INV-C3**: session cookie 必须设置 HttpOnly 和 Secure 标志
  - Applies to: B1
  - **Verifiable via**: 用 Playwright 的 `context.cookies()` 或 CDP 的 `Network.getCookies` 读取 cookie 元数据,
    检查返回对象的 `httpOnly` 和 `secure` 字段为 true。
  - **❌ 不要用** `document.cookie`(浏览器 JS API)验证——HttpOnly cookie 的定义本身就是 JS 读不到,
    用 JS 验证只能确认"读不到",但**不能区分**"HttpOnly 生效"和"cookie 根本没设置"。
  - **Codex-tool-plan 提示**:本 invariant 几乎要求 Playwright Script(需要 Playwright 访问 cookies API);
    纯 Browser Use 不便验证此项,可在场景模式自检表标 ⚠ + 工具能力理由

#### Server-side invariants

- **INV-S1**: 应用日志中任何时候不应出现密码明文
  - Applies to: all
  - Verifiable via: 测试期间监控应用日志,grep 密码字符串
- **INV-S2**: 任何登录失败响应不应暴露内部错误细节(stack trace、SQL 错误等)
  - Applies to: B2, B3, B4
- **INV-S3**: 数据库 users 表的 password 字段必须是 bcrypt 哈希,绝不能是明文
  - Applies to: 全局
  - Verifiable via: `GET /test/users-schema`(test endpoint,只返回字段类型不返回值)

#### Cross-cutting invariants

- **INV-X1**: B2(密码错)和 B3(用户不存在)在以下维度上**完全不可区分**:
  - response_status(都是同一个 status)
  - response_body(都是同一个 message)
  - ui_text(都是"邮箱或密码错误")
  - response_time(差异 < 100ms,防止时序攻击)
  - **约束范围**:本不可区分约束**仅适用于面向客户端的可观测维度**——
    服务端内部日志、监控指标、内部审计记录等**不在约束范围**(B3 中"应用日志记录该次尝试"是合法的服务端观测,
    不违反 INV-X1)。攻击者无法访问这些内部数据,所以日志的差异不构成邮箱枚举漏洞。
  - **Rationale**: 防止用户邮箱枚举攻击——攻击者不应能通过响应判断邮箱是否注册
  *(来源: src/api/auth.js:30-78)*
  - **逻辑依据**: auth.js 的 login handler 在 user 不存在时,会调用 dummy bcrypt.compare()
    保持耗时一致,然后和密码错误情况共用同一个 returnUnauthorized() 函数返回
    `{ status: 401, message: "Invalid credentials" }`。两条分支汇合到同一个 return
    点,响应体完全一致。
  - **可达性**: 两条分支均可达——攻击者通过提交不同 email 确实能触发不同分支,
    但两分支的**外部输出**不可区分,这正是该 invariant 要保证的

## 3. Hints (SHOULD)

### 3.1 Boundary Values

- 字段 `password.length`:边界值 `[0, 1, 7, 8, 9, 63, 64, 65, 1000]`
  *(来源: src/validators/password.js:12)*
  - 0(空):应被拒绝,提示密码不能为空
  - 1, 7:小于最小长度 8,应被拒绝
  - 8, 9, 63, 64:在合法范围 8-64,应通过(假设密码本身正确)
  - 65:超过最大长度,应被拒绝
  - 1000:防 DOS,应被拒绝且不引发服务器异常
  - **逻辑依据**: validators/password.js 中代码:
    ```
    if (!password || password.length === 0) return 'EMPTY';
    if (password.length < 8) return 'TOO_SHORT';
    if (password.length > 64) return 'TOO_LONG';
    return 'OK';
    ```
    所以 8 通过(`< 8` 不成立)、64 通过(`> 64` 不成立)、7 拒绝、65 拒绝。
    1000 也走 `> 64` 分支被拒绝,但单独列以测 DOS 防护。
  - **可达性**: 4 条分支均可达;无 fallback(明确的 return 'OK')
- 字段 `rate_limit.failed_attempts_per_email`:边界值 `[4, 5, 6]`
  - 4:还能登录,对应 B2
  - 5:刚好达到锁定阈值,对应 B4
  - 6:已锁定状态下再尝试,仍被锁定

### 3.2 Decision Table

| 用户存在 | 密码正确 | 已锁定 | 预期 behavior |
|--------|--------|------|------------|
| ✅ | ✅ | ❌ | B1: 登录成功 |
| ✅ | ❌ | ❌ | B2: 密码错误提示 |
| ❌ | * | ❌ | B3: 邮箱或密码错误(与 B2 一致) |
| ✅ | * | ✅ | B4: 账号锁定提示 |
| ❌ | * | ✅ | **unreachable** — 见下方说明 |

**不可达行说明**(❌ 用户不存在 + ✅ 已锁定):

- **逻辑依据**:锁定状态(`locked_until` 字段)**写在 users 表上**——
  没有 user 记录就没有可锁定的对象。代码层面 `recordFailure(email)` 在 user 不存在时
  走 dummy 路径(见 INV-X1),不进入 `setLockedUntil` 调用。
- **测试影响**:**不要为这一行写测试用例**——它在数据模型上不可能发生,
  写出来会需要"先创建用户、锁定、再删除用户"的怪异 setup,白白浪费精力。
- **不是"防御性"**:这一行不是"代码可能有 bug 进入这个状态,所以测一下兜底"——
  数据模型本身就排除了这种状态,测它没有意义。

### 3.3 State Machine

适用于 session 生命周期:

- States: [none, active, expired, revoked]
- Transitions:
  - none → active: 触发于 B1(成功登录)
  - active → none: 触发于 logout
  - active → expired: 触发于时间流逝(默认 24h)
  - active → revoked: 触发于密码修改或管理员强制下线
- **逻辑依据** *(来源: src/services/session.js)*: sessions 表的状态由 expires_at 字段
  和 revoked_at 字段隐式表达:
  - none = 数据库无该 token 记录
  - active = 记录存在 & expires_at > now & revoked_at IS NULL
  - expired = 记录存在 & expires_at <= now
  - revoked = 记录存在 & revoked_at IS NOT NULL
  
  代码 session.js 在每次请求 middleware 中按上述条件计算状态;无显式状态字段,
  也无定时任务转移状态——状态是查询时计算出来的。
- **可达性**: 4 个状态均可达。注意 expired 和 revoked 是终态(数据库不会自动清理,
  但应用层不会再让它们回到 active);active → none 通过 logout 实际是删除 sessions 记录,
  所以严格说不是状态转移而是记录消失

### 3.4 Out of Scope

#### 3.4a 业务边界(真的不需要测)

- 短信二步验证(下期功能)
- SSO 登录(Google / GitHub,本期不做——如截图所示的 Apple/Google 登录在产品本期范围外)
- 记住登录状态(Remember me 选项,本期不做)
- 邮件服务本身的可达性(由邮件服务团队负责)

#### 3.4b 工程边界(该测但本期没法测)

- **密码强度实时反馈的视觉变化**
  - 不测理由:工具能力——Browser Use 无法在每次按键时精确捕获密码强度颜色变化
  - 已知风险:用户可能看不到弱密码提示而创建弱密码
  - 替代手段:用 INV-S3 保证后端拒绝弱密码;无前端实时反馈测试
  - 建议补救路径:下期用 Playwright 在每次输入后断言色彩 class 切换

### 3.5 Setup Strategy

按"聚焦测试模式"——本规约只测登录,**不测注册流程**(假设用户已存在)。

进入测试起点前,Operator 应:

1. 调用 `POST /test/setup-user?email=alice@example.com&password=Test1234!`(setup endpoint)
   创建测试用户 alice
2. 确认浏览器 cookie 已清空
3. 导航到 `/login`

前置失败时:Operator 中止整个测试,标记 "setup failure"——不要尝试跑后续用例。

#### 3.5b 环境隔离与 Mock 要求

- 必须 mock 的外部依赖:无(本登录功能不依赖外部服务)
- 共享测试资源隔离:
  - 每轮测试前重置 sessions 表(`DELETE FROM sessions WHERE user_email LIKE '%test%'`)
  - 限流计数器测试期使用独立的 redis namespace(避免污染生产计数)
- 不可避免的不可逆操作:无

## 4. Scenario Patterns

- 匹配的场景模式:
  - **表单输入型**(Behaviors B1-B4 涉及"填邮箱+密码 → 提交")
  - **用户认证 / 会话管理**(本功能核心:登录建立 session、cookie 设置、会话防护)
  - **前端渲染保真度**(错误提示"邮箱或密码错误"、按钮 disabled 灰色视觉切换需要 Agent 看截图判断)
  - **异常路径(通用)**(B2/B3/B4 是失败路径,需要测网络异常 / 限流 / 服务器异常)
- 不匹配但容易误判的模式:
  - 不匹配"对话型 UI"——单次表单提交,不是聊天
  - 不匹配"异步/流式输出"——登录响应是单次同步返回
  - 不匹配"LLM agent 决策"——后端是常规身份校验,无 LLM
  - 不匹配"文件上传 / 下载"——无文件输入

## 5. Meta

- Generated by: Cartographer (示例)
- Code commit: example-commit-hash
- Generated at: 2026-04-26T10:00:00Z
- Reviewed by human: yes
- Notes: 这是一个为了演示 skill 范式而手工撰写的样例,不对应任何实际产品
