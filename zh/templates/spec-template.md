<!--
================================================================================
规约模板 (Specification Template)

填写说明:
- 这份模板是 Cartographer 生成规约的目标格式
- 所有 <!-- 注释 --> 是给 Cartographer 的填写指引,生成最终规约时应删除
- 章节结构是固定的,不要新增或合并章节
- 如果某章节没有内容,写 "(无)" 而不是删除章节
- 整份规约用 Markdown 写,LLM 友好且人类可读

Source 标注规则(易冲突字段必标):
- 容易出现"代码 vs 文档冲突"的字段(测试账号、API 路径、关键文案、边界值等)
  必须在事实后用斜体括号标注 Source
- 格式: 事实  *(来源: 文件:行号)*
- 如果发现多个来源对同一事实有冲突,以高权威等级为准,但要在规约里
  显式声明冲突,格式:  *(来源: A;⚠️ 与 B 不一致,以 A 为准)*
- 详见 cartographer.md 的"信息源权威等级"原则
================================================================================
-->

# Feature: <功能名称>

<!--
功能名称用简短的名词短语,不写动作。例如:
- 好:"密码重置"、"购物车结算"、"用户登录"
- 不好:"实现用户能登录"、"做一个登录功能"
-->

## 1. Interface

<!--
Interface 是 Layer 1:从代码静态读出的事实。
这部分内容应该 100% 可验证,不允许 LLM 推断或猜测。
-->

### 1.1 Routes

<!--
列出该功能涉及的所有前端路由。
每条路由格式:`路径` — 简短描述
路径的 Source 标注:代码中的 router 文件
-->

- `/path` — 描述  *(来源: src/router.js:42)*
- `/path/:param?query=value` — 描述  *(来源: src/router.js:67)*

### 1.2 API Endpoints

<!--
列出该功能涉及的所有后端 API。
格式:METHOD `路径` — 请求和响应概要
不要写完整 schema(那是给开发的),写关键字段就够。
-->

- `POST /api/...` — 请求 `{ field1, field2 }`,响应 `200 | 4xx`  *(来源: src/api/auth.js:15)*

## 2. Constraints (MUST)

<!--
Constraints 是 Layer 2 + 3 的"必须"部分。
Cartographer 生成 + 人类审校 + 后续 Inspector 检查时,这部分都是硬要求。
-->

### 2.1 Behaviors

<!--
每个 behavior 是一个完整可验证的因果片段。
- ID 用 B1, B2, ... 顺序编号
- trigger 写"用户意图级",不写步骤级
- expected 用 "eventually" 表达最终稳定状态
- preconditions 分 client_state / server_state
- 状态划分原则:
  * client_state = 浏览器里的状态(cookie / localStorage / URL)
  * server_state = 服务器侧的状态(数据库 / 缓存 / 计数器)
  * UI 文本不算 client_state,放在 expected.ui_observable
-->

#### B1: <一句话描述这个行为>

**Preconditions**

- Client state:
  - <如:用户未登录,无 session cookie>
- Server state:
  - <如:数据库中存在测试账号 alice@example.com / Test1234!>  *(来源: migrations/seed.sql:12)*
  - <如有冲突示例>:测试账号 admin / Test1234!  *(来源: seed.sql:5;⚠️ 与 README.md 写的 admin/password123 不一致,以 SQL 为准)*

**Trigger**

- Intent: <用户的高层意图,如"提交登录表单">
- With:
  - Text inputs: <如:`email=test@x.com, password=Test1234`(无文本输入填"无")>
  - File inputs: <可选,只在功能涉及文件上传时填,无则填"无">

<!--
File inputs 字段格式(每个文件一行):

| 字段名 | 文件描述 | 用途 |
|-------|--------|----|
| avatar | 正常 PNG 图片,~500KB,256x256 | 测试基本上传成功路径 |
| document | 损坏的 PDF(头部正确但内容损毁) | 测试损坏文件处理 |

注意:
- 这里只描述文件应该是什么样,不写实际路径
- 实际用什么文件由 Cartographer 阶段 2.5 让用户决策(指定路径 / 手动上传 / Agent 生成)
- 决策结果写在测试用例文档,不写在规约
-->

**Expected (eventually)**

- Client state after:
  - <如:cookie session_token 存在>
  - <如:URL 变为 /dashboard>
- Server state after:
  - <如:user_activity 表新增一条 login 记录>
  - Verifiable via: <如:test endpoint / DB query / log inspection>
- UI observable:
  - Visible text: <如:"Welcome, X">  *(来源: locales/zh-CN.json:14)*
  - Visible elements: <如:登出按钮可见>
- Not observable:
  - <如:不应出现 "Login failed" 文本>

**逻辑依据**(本 behavior 的输出归纳依据,见 cartographer.md 第 8 条原则):

- <2-4 句话描述代码控制流结构。如:
  "loginHandler 在密码验证通过后,1) 在 sessions 表插入 user_id, 
  2) 设置 Set-Cookie 响应头, 3) 返回 redirect 到 /dashboard。
  三步均在同一事务中,任一失败回滚。">
- **可达性**: <如:正常路径只有一条,异常分支由 B2/B3 覆盖>
- **结论修正**(如适用): <如:写依据时发现某个 expected 字段写错了,在这里说明并修正>

#### B2: ...

<!-- 重复以上格式 -->

### 2.2 Invariants

<!--
不变量是跨 behavior 的永恒约束,不绑定到具体动作。
分三类:
- Client-side:浏览器侧永远成立的(如:密码不出现在 URL)
- Server-side:服务器侧永远成立的(如:密码不出现在日志)
- Cross-cutting:横跨两侧的(如:某些 behavior 对外不可区分)
每条不变量必须可验证,模糊的写法(如"系统应该安全")不允许。
-->

#### Client-side invariants

- INV-C1: <如:任何时候,密码字段值不出现在 URL 中>
  *(来源: src/router.js:88)*
  - Applies to: B1, B2, ... (或 "all")
  - **逻辑依据**: <如:登录表单 onSubmit 用 POST body 提交,不会经过 URL 参数。
    检查 router.push 调用全部使用 path 而不是含 query 的对象>
  - **可达性**: <如:无 fallback 路径,所有路径均不会把 password 放进 URL>

#### Server-side invariants

- INV-S1: <如:任何时候,密码字段值不出现在日志中>
  *(来源: src/middleware/logger.js:42)*
  - Applies to: all
  - Verifiable via: <如:grep 应用日志>
  - **逻辑依据**: <如:logger 中间件在记录请求 body 前调用 sanitize() 函数,
    sanitize 会移除 password、token、secret 三个字段名的值>
  - **可达性**: <如:所有日志路径都经过该中间件,无绕过路径>

#### Cross-cutting invariants

<!--
这里特别用于表达"等价行为"——某些行为对外不可区分。
这是为了防止 Inspector 把"故意的安全设计"误报为 bug。
-->

- INV-X1: <如:B1 和 B2 在 response_status / response_body / ui_text 维度上不可区分>
  *(来源: src/api/auth.js:30-50)*
  - Rationale: <如:防止用户邮箱枚举攻击>
  - **逻辑依据**: <如:auth.js 在 email 不存在和 password 错误两种情况下,
    都返回 status=401 + message="Invalid credentials",且耗时通过 dummy bcrypt 调用
    保持一致(防时序攻击)>
  - **可达性**: <如:两条分支均可达,无 fallback>

## 3. Hints (SHOULD)

<!--
Hints 是给 Cartographer 自己(后续生成测试用例时)和 Inspector 的提示。
不是硬约束,但 Cartographer 应该尽量用上,Inspector 用来检查覆盖度。
-->

### 3.1 Boundary Values

<!--
关键边界值,显式列出。
不要把所有可能的边界都列上(那是 Inspector 用方法论展开的工作)。
只列代码里有 magic number 或限制的字段。
-->

- 字段 `<field>`:边界值 `[v1, v2, v3, v4]`,预期行为 <对应哪个 behavior>  *(来源: src/validators.js:23)*
  - **逻辑依据**: <如:validators.js 中代码 `password.length >= 8 && password.length <= 32`,
    用 >= 和 <=,所以 8 通过、32 通过、7 拒绝、33 拒绝。
    边界两侧两值法选 [7, 8, 32, 33]>
  - **可达性**: <如:>= 和 <= 都执行,无 fallback>

### 3.2 Decision Table

<!--
当多条件组合影响结果时,列决策表。
不需要穷举所有组合,只列开发者实际处理的分支。
-->

| 条件1 | 条件2 | 条件3 | 预期 behavior |
|------|------|------|------|
| ✅ | ✅ | ✅ | B1 |
| ✅ | ❌ | ✅ | B3 |
| ❌ | - | - | B5 |

### 3.3 State Machine

<!--
仅适用于有状态流程(订单、审批、token 生命周期)。
无状态功能可以写"(无)"。
-->

- States: [created, sent, used, expired]
- Transitions:
  - created → sent: 触发于 B1
  - sent → used: 触发于 B5
  - sent → expired: 触发于时间流逝
- **逻辑依据**: <如:tokens 表有 status 字段(enum: created/sent/used/expired)。
  代码 token-service.ts 中:
  - createToken 插入时 status='created'
  - sendToken 把 status 从 created 改 sent
  - useToken 检查 status='sent' 且 expire_at>now,改 status='used'
  - 定时任务 cleanupExpired 把 status='sent' 且 expire_at<now 的改 expired>
- **可达性**: <如:created→sent 必经,sent 后两条出口(used/expired)互斥可达,
  无其他状态;无非法转移路径(代码用 enum + 状态校验)>

### 3.4 Out of Scope

<!--
Out of Scope **必须分两类**——这是为了防止"难测就丢这"的逃避模式。
两类的根本区别:
- 业务边界:**真的不需要测**(产品决策 / 第三方归属 / 不在本期范围)
- 工程边界:**该测但本期没法测**(承认缺口,需要补救方案)

每条必须给"分类依据 + 不测理由 + (工程边界类还要)已知风险 + 替代手段"。
不允许写"教学原型"、"实现复杂"这类一句话敷衍——会被 Inspector 提 P1 要求补具体内容。

聚焦测试模式下,依赖功能(登录、注册等)放在业务边界 3.4a。
-->

#### 3.4a Out of Scope - 业务边界(故意不测,有合理业务理由)

<!--
这类项是"真的不需要测"——产品决策 / 第三方组件 / 本期范围外 / 由独立团队/独立规约覆盖。
Inspector 不会反对这类项的内容。
-->

每条格式:

- <项目名>
  - **类别**:业务边界
  - **不测理由**:<具体说明为什么不测>

例子:

- 国际化(i18n)
  - **类别**:业务边界
  - **不测理由**:本期产品仅支持中文界面,无 i18n 切换逻辑,代码中无对应路径
- 短信验证码找回
  - **类别**:业务边界
  - **不测理由**:本期不做,产品 backlog 在 Q3
- DICOM 渲染细节
  - **类别**:业务边界
  - **不测理由**:由 OHIF / Cornerstone 第三方组件负责,不在我们代码控制范围内
- 用户登录(仅聚焦测试模式)
  - **类别**:业务边界
  - **不测理由**:由独立规约覆盖,本规约假设登录态已建立(见 §3.5 Setup Strategy)

#### 3.4b Out of Scope - 工程边界(应当测但本期手段不足)

<!--
这类项是"该测但没法测"——承认是缺口。
Cartographer 把项放进这里时,**必须诚实承认是缺口**,并提"替代手段"或"后续如何补救"。
Inspector 对这类项**有干预权**:可以提 P1 建议(如"建议加 manual_upload 标记"
或"建议后续单独立项",或"建议增加 invariant 间接降低风险")。
人类 review 时也要重点看这一节——这里列的每一条都是"已知缺口"。
-->

每条格式:

- <项目名>
  - **类别**:工程边界
  - **不测理由**:<具体说明为什么本期没法测>(必须是工具能力 / 自动化限制 /
    断言粒度问题,不是"业务上不需要测"——那种属于业务边界)
  - **已知风险**:<这条不测可能在生产中导致什么后果>
  - **替代手段**:<目前用什么方式部分降低风险>(可以写"无")
  - **建议补救路径**(可选):<未来怎么补救——如 manual review、独立专项测试、上不同工具>

例子:

- LLM 答复的语义正确性 / hallucination 检测
  - **类别**:工程边界
  - **不测理由**:断言此项需要医学专家审查每条 LLM 输出,无法在自动化 E2E 中实现;
    LLM-as-judge 当前可用度不足
  - **已知风险**:hallucination 可能在生产中误导用户(给错误诊断建议)
  - **替代手段**:已通过 INV-S3(敏感字段不入库)间接降低部分风险;
    通过 system prompt 中的免责声明降低误导可能
  - **建议补救路径**:未来上 LLM-as-judge 自动化评判 + 抽样人工 review

- SSE 长连接稳定性专项
  - **类别**:工程边界
  - **不测理由**:Claude in Chrome 工具不支持精确模拟"网络断开 N 秒后恢复"
    类的复杂时序场景
  - **已知风险**:用户在网络抖动场景下,流式输出可能丢失 / 卡死 / 无错误提示
  - **替代手段**:基础异常路径已通过 TC-XX 覆盖(模拟一次完整断开)
  - **建议补救路径**:用 Playwright + offline mode 单独立项

### 3.5 Setup Strategy

<!--
仅在"聚焦测试模式"下填写。全流程测试模式写"(无,从空白状态开始)"。

描述 Operator 如何最简化地进入测试起点。原则:越简单越好。
按优先级选择前置方式(详见 cartographer.md 阶段 1 关键原则第 6 条):
1. setup endpoint
2. 加载已保存的浏览器状态
3. 用户提供有效 token
4. 实际跑一次登录(最不推荐)

每一步必须可独立失败:前置失败 ≠ 测试失败。
Operator 遇到前置失败时,必须中止测试,标记 "setup failure"。
-->

- 进入测试起点前,Operator 应:
  1. <如:调用 `POST /test/login-as?email=alice@example.com` 获取 session cookie>
  2. <如:确认浏览器 cookie session_token 已存在>
  3. <如:导航到测试目标页面 `/chat`>
- 前置失败时:Operator 中止整个测试,在报告中标记 "setup failure"——
  这种失败不是被测功能的 bug

#### 3.5b 环境隔离与 Mock 要求

<!--
对于不可逆操作(发邮件、调外部 API、触发 webhook、修改外部支付状态等),
不能依赖 teardown 恢复——必须在测试环境用 mock 替代。

这一段列出本测试套需要的 mock,Operator 在测试启动前确认 mock 已就绪。
-->

- 必须 mock 的外部依赖:
  - <如:邮件服务(SendGrid / SES)→ 用本地 Mailhog 替代,SMTP 转发到 localhost:1025>
  - <如:支付网关(Stripe)→ 用 Stripe test mode + test cards>
  - <如:第三方 webhook → 配置为 `localhost:8080/webhook-receiver`>
- 共享测试资源(避免 TC 间干扰):
  - <如:每个测试 user 独立隔离(user_test_for_TC_001, user_test_for_TC_002, ...)>
  - <如:测试用 schema 单独建,每轮测试前重置(`DROP SCHEMA test; CREATE SCHEMA test;`)>
- 不可避免的不可逆操作(声明已知缺陷):
  - 见规约 §3.4b 工程边界

## 4. Scenario Patterns

<!--
该功能匹配的场景模式(可叠加,通常 2-4 个)。
完整模式库见 references/scenarios/(每个模式独立文件,索引在 scenarios/index.md)。

Cartographer 阶段 1 末尾必填——这个字段决定阶段 2 该应用哪些必查清单。
人类 review 时要重点确认:这些模式标注是否准确,有没有漏匹配的模式。
-->

- 匹配的场景模式:
  - <如:对话型 UI(因为 Behaviors 中含输入框 + 历史消息渲染)>
  - <如:异步/流式输出(因为 LLM 回复是流式)>
  - <如:LLM agent 决策(因为后端调用 LLM 做生成)>
  - <如:多租户/权限矩阵(因为有 admin/user/guest 三角色)>
  - <如:异常路径(通用)>
- 不匹配但容易误判的模式(可选):
  - <如:不匹配"状态流转"——本对话功能无明确状态机>

## 5. Meta

<!--
溯源信息,方便人类 review 和后续追踪。
-->

- Generated by: Cartographer
- Code commit: <git commit hash>
- Generated at: <ISO 8601 时间戳>
- Reviewed by human: <yes/no/pending>
