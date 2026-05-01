<!--
================================================================================
Quick Feature Test 记录模板

用于单功能快速验证。不需要完整 spec / test cases / Inspector。
核心要求:快、真实、有证据,并明确 viewport 限制。
================================================================================
-->

# Quick Feature Test: <功能名称>

**Tested by**: Coordinator / Operator
**Started at**: <ISO 8601>
**Finished at**: <ISO 8601>
**Target URL**: <http://localhost:...>
**Tools used**: Browser Use / Browser Use + Screenshot Review / Playwright Script / Computer Use / Supabase Verify / API/Security Supplemental
**Artifact root**: `test-artifacts/<feature>/<YYYYMMDD-HHMMSS>/`

## Scope

- 测试目标:<一句话说明本次只测什么>
- 不测内容:<依赖功能、完整链路、性能、安全审计等>
- 是否允许改代码:yes / no
- 是否允许创建测试数据:yes / no

## Environment

- Dev server:<命令或"用户已启动">
- Browser:<如:Codex in-app browser / Chrome>
- Viewport target:<desktop 1280x800 / mobile / small-codex-viewport>
- Viewport actual:<宽x高>
- Viewport evidence note:<desktop evidence / small-codex-viewport evidence>

## Steps Executed

1. <用户视角步骤>
2. <用户视角步骤>
3. <用户视角步骤>

## Evidence

| 类型 | 路径/摘要 | 说明 |
|----|----------|----|
| Screenshot | `screenshots/quick-001.png` | <截图说明 + viewport> |
| Console | <无错误 / 错误摘要> | <说明> |
| Dialog | <无 / alert 内容> | <说明> |
| URL/client state | <最终 URL / cookie/localStorage 摘要> | <说明> |
| Server verify | <SQL/API/Supabase 摘要或"未验证"> | <说明> |

## Result

- **Status**: PASSED / FAILED / BLOCKED / NEEDS MANUAL REVIEW
- **Summary**:<一句话结论>

## Findings

| 发现 | 证据 | 分类 | 建议 |
|----|----|----|----|
| <问题或通过点> | <截图/console/URL> | product bug / environment/setup issue / tool limitation / needs manual review | <下一步> |

## Retest Notes

- <是否需要 desktop viewport 复测>
- <是否需要升级为 Full Flow Test>
- <是否需要补 Playwright 回归脚本>
