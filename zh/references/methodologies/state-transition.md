# State Transition(状态转换)

## 核心思想

某些功能的本质不是"输入对应输出",而是"系统在不同**状态**间切换"。
状态转换测试专门测这类功能——**确保每个状态可达、每条合法转移正确、每条非法转移被拒绝**。

它和其他方法论的区别:

- **EP/BVA** 测输入数据
- **Decision Table** 测条件组合
- **State Transition** 测**系统的"记忆"**——之前发生过什么决定了当前能做什么

## 何时用这个方法论

当规约里的 `## 3.3 State Machine` 字段非空时,必须用这个方法论。

典型有状态机的功能:

- **订单流程**:`待支付 → 已支付 → 已发货 → 已签收 → 已完成`
- **Token 生命周期**:`已生成 → 已发送 → 已使用 / 已过期 / 已撤销`
- **会话状态**:`未登录 → 已登录 → 会话过期 → 已登出`
- **审批流**:`草稿 → 待审 → 已批准 / 已驳回`
- **资源状态**:`空闲 → 占用中 → 释放中 → 空闲`

无状态机的功能(如纯查询、纯计算)不适用——直接跳过这个方法论。

## 套用步骤(Inspector 用)

1. 从规约 `hints.state_machine` 提取**状态列表**和**转移列表**
2. 对每个状态,检查**至少有一个 TC 能到达它**
3. 对每条合法转移,检查**至少有一个 TC 测试它**
4. 对每条非法转移(状态机里没列的),检查**有 TC 验证它被拒绝**
5. 检查**孤岛状态**(进得去出不来)和**死状态**(到达后无法继续)

## 例子:订单状态机

规约 `hints.state_machine`:

```
States: [pending, paid, shipped, delivered, cancelled]
Transitions:
  - pending → paid:        触发于"用户支付成功"
  - pending → cancelled:   触发于"用户取消订单"
  - paid → shipped:        触发于"商家发货"
  - paid → cancelled:      触发于"用户申请退款"
  - shipped → delivered:   触发于"快递签收"
```

### 第 1 类检查:状态可达性

每个状态都要有 TC 能进入:

| 状态 | 进入路径 | 是否有 TC |
|-----|--------|---------|
| pending | 创建订单 | ✅ |
| paid | pending → paid | ✅ |
| shipped | pending → paid → shipped | ✅ |
| delivered | 完整链路 | ✅ |
| cancelled | pending → cancelled OR paid → cancelled | ✅(注意要测两条路径) |

### 第 2 类检查:合法转移测试

| 转移 | 是否有 TC |
|-----|---------|
| pending → paid | ✅ |
| pending → cancelled | ✅ |
| paid → shipped | ✅ |
| paid → cancelled | ✅ |
| shipped → delivered | ✅ |

5 条合法转移,5 个 TC。

### 第 3 类检查:非法转移拒绝

状态机里**没列**的转移,系统应该拒绝。要专门测:

- `paid → pending`(订单已支付不能回到待支付)
- `delivered → shipped`(已签收不能退回已发货)
- `cancelled → paid`(已取消订单不能再支付)
- `shipped → cancelled`(已发货后能否取消?——这条要看业务,如果业务说不能,要测拒绝)

**这是最常被遗漏的**——测试用例往往只覆盖 happy path,忘了测"系统能阻止非法操作"。

### 第 4 类检查:孤岛和死状态

- **孤岛状态**:从初始状态出发,通过任何转移都到不了的状态
  - 例:state machine 里有 `archived` 但没有任何转移指向它 → 这是孤岛,要么补转移要么删状态
- **死状态**(陷阱状态):到达后没有任何转移能离开
  - 例:`delivered` 是终态——OK,这是预期的
  - 例:`paid` 进去后没有任何转移出来 → bug

## Inspector 反馈样例

```
P0-001: 状态可达性不全
- Methodology: State Transition
- Issue: 规约状态机有 5 个状态,但 cancelled 状态只有从 pending 进入的 TC,没有从 paid 进入的 TC
- Affected: hints.state_machine 中 paid → cancelled 转移
- Suggested fix: 增加 TC,前置条件设置订单已 paid,trigger 用户申请退款,expected 状态变为 cancelled

P0-002: 非法转移未测
- Methodology: State Transition
- Issue: 状态机隐含规则"已签收订单不能退回已发货",但用例完全没测这种保护
- Suggested fix: 增加 TC,前置条件 delivered 状态,trigger 调用发货 API,expected 应被拒绝(403 或 409)

P1-001: 孤岛状态
- Methodology: State Transition
- Issue: 状态机列出 archived 状态,但没有任何转移指向它,无法到达
- Suggested fix: 要么在 state machine 中补充进入 archived 的转移规则,要么从规约中删除该状态
```

## 严重等级判定

- **P0**:状态可达性缺失(规约列出但用例无法到达)
- **P0**:核心非法转移未测(尤其是涉及金钱、权限、数据完整性的)
- **P1**:次要非法转移未测
- **P1**:孤岛状态或死状态(规约设计问题,不一定是用例问题——指出来供人类审视)
- **P2**:状态命名或转移描述不清晰

## 常见错误

- ❌ 只测 happy path 的状态流转,忘了测非法转移
- ❌ 终态(如 delivered)被当成"死状态"误报——终态是预期的
- ❌ 把同一个状态在不同 context 下当成不同状态(如"未登录用户"和"会话过期"如果系统行为完全相同,应该合并)
- ❌ 测了"A → B"但忘了"B → A"是否应该被允许(对称性)

## 不适用场景

- 纯查询/展示功能(无状态机)
- 纯计算功能(输入决定输出,无"记忆")
- 纯路由跳转(URL 切换,但系统本身无状态)

如果规约的 `## 3.3 State Machine` 字段明确写"(无)",直接跳过这个方法论。
