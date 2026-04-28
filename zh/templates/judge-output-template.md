<!--
================================================================================
Inspector 反馈输出模板

Inspector 完成审查后,产出符合本格式的 Markdown 文档。
- 一份反馈对应一轮审查
- P0/P1/P2 严重程度分级
- 每条反馈必须可操作 — 模糊建议不允许
- 第二轮起,Inspector 只能跟进上一轮未解决的问题,不能引入新问题
================================================================================
-->

# Inspector Feedback Round <N>

**Test cases version**: <对应用例文档的版本>
**Inspector reviewed at**: <ISO 8601 时间戳>
**Methodologies applied**: <如:Equivalence Partitioning, BVA, Decision Table>

## Summary

| 严重等级 | 数量 | 说明 |
|---------|-----|-----|
| P0 | N | 必须修复才能进入下一阶段 |
| P1 | M | 建议修复,Cartographer 可决定不修但需填 rationale |
| P2 | K | 可选优化,Cartographer 可忽略 |

## Findings

### P0 (必须修)

<!--
P0 标准:
- 缺少对核心 behavior 的测试覆盖
- 关键边界值未测(如安全相关边界)
- 决策表中分支被遗漏
- 用例和规约直接矛盾
-->

#### P0-001: <一句话标题>

- **Methodology**: <如:Decision Table Coverage>
- **Issue**: <具体问题描述>
- **Affected**: <如:规约中 B3 没有对应用例>
- **Suggested fix**: <如:增加一个 TC,preconditions 设置 token 已过期,trigger 访问 /reset-password,expected UI 显示"链接已过期">

### P1 (建议修)

<!--
P1 标准:
- 等价类划分有遗漏
- 一般边界值未测
- 测试粒度过粗或过细
- 主/备/异常路径分类不清
-->

#### P1-001: <标题>

- **Methodology**: <如:Equivalence Partitioning>
- **Issue**: ...
- **Suggested fix**: ...

### P2 (可选优化)

<!--
P2 标准:
- 用例描述可以更清晰
- 用例顺序可以更合理
- 注释和 rationale 可以更详细
-->

#### P2-001: <标题>

- **Issue**: ...
- **Suggested fix**: ...

## Methodology Coverage Self-Check

<!--
只列**实际应用了**的方法论。不在功能特征清单里的方法论根本不要写——
不要列"不适用"作为占位。
应用理由要具体说明:为什么这个特征下选了这个方法论。
-->

| 方法论 | 应用理由 | 发现的问题数 |
|-------|--------|----------|
| Equivalence Partitioning | 该功能有 3 个输入字段(email、password、code) | 3 |
| Boundary Value Analysis | 同上,且代码中有数值范围限制 | 2 |
| Use Case Testing | 该功能为端到端登录流程 | 1 |
| Right-BICEP (I) | 触发该激发条件:behaviors 含写入语义(创建 session) | 1 |

<!--
注意:
- Decision Table、State Transition、多字段组合等方法论如果未被选用,
  本表中**不出现**,而不是写"不适用"
- Right-BICEP 后面要标注激发的字母(I / C / P / 多个),不激发就根本不列
-->

## What I Did Not Check

<!--
Inspector 必须诚实声明它没法判断的内容。
这些会留给人类 review 处理。
-->

- 业务正确性:Inspector 不看代码,无法判断"这个行为是不是业务想要的"
- 用例与实际页面元素的对应关系:需要人类用真实页面交叉验证
- 性能可接受性:除非规约明确指定阈值
