# QQSanGuo Phase Spec / Design / Plan / Acceptance Template

这是一份强制模板，不是可直接执行的 Implementation Plan。所有 `{{required_field}}` 在文档进入 `Approved` 前必须替换为具体内容；批准文档不得含 `TBD`、`TODO`、`以后处理` 或未决占位。

---

## A. Phase Spec 模板：定义“做什么”

建议路径：

```text
docs/superpowers/specs/YYYY-MM-DD-phase-{{phase_id}}-{{slug}}-spec.md
```

```markdown
# Phase {{phase_id}}: {{name}} Spec

**Status:** Draft | In Review | Approved | Superseded
**Owner:** {{owner}}
**Depends on:** {{approved_phase_ids}}
**Master requirements:** {{FR/NFR IDs}}
**Supersedes:** {{document path or None}}

## 1. Outcome

用一句可观察结果说明玩家或开发者在 Phase 完成后获得什么。

## 2. Problem and evidence

- 当前具体行为、错误或限制。
- 代码/场景/测试的精确路径和行号。
- 为什么现在必须解决，若不解决会阻断哪个后续 Phase。

## 3. User flows

按时间顺序写主流程、恢复流程和失败流程。每条流程都必须有终态。

## 4. In scope

- 本 Phase 必须交付的行为。
- 本 Phase 允许迁移的旧入口。
- 本 Phase 要新增或修改的内容数量。

## 5. Out of scope

- 明确推迟的相邻能力及其目标 Phase。
- Master Spec 中永久不进入 V1 的内容。

## 6. Functional requirements

### P{{phase_id}}-FR-01 {{short title}}

- Given / When / Then 行为。
- 可见错误和恢复动作。
- 幂等、重试、并发或重复触发语义。

## 7. Data and content contract

- 稳定 ID、字段、类型、范围、枚举和默认值。
- 跨表引用及内容计数。
- 老数据映射和未知值策略。

## 8. Failure modes

| Failure | Expected result | User sees | State mutation allowed |
|---|---|---|---|
| {{specific failure}} | {{terminal result}} | {{message/action}} | None or exact delta |

## 9. Acceptance criteria

每条写成机器可判断阈值：次数、帧数、时间、状态 hash、计数或错误码。禁止只写“工作正常”。

## 10. Evidence required

- 自动测试命令和预期终结记录。
- 人工视觉/手感检查。
- 报告、截图、日志或 profiler 文件。

## 11. Rollback and compatibility

- 回滚点。
- 新旧入口共存期限。
- 存档/content revision 兼容。

## 12. Decisions

| ID | Decision | Reason | Rejected alternative |
|---|---|---|---|

NO UNRESOLVED DECISIONS
```

### Spec 审核问题

Spec 通过前必须能明确回答：

1. 玩家或下游开发者能观察到什么变化？
2. 什么明确不做？
3. 所有失败是否有终态和恢复动作？
4. 是否给出精确计数、范围和性能阈值？
5. 重复触发、旧回调、存档恢复和满容量等边界是什么？
6. 是否可以只读 Spec 就写黑盒验收测试？

## B. Phase Design 模板：定义“怎么做”

建议路径：

```text
docs/superpowers/specs/YYYY-MM-DD-phase-{{phase_id}}-{{slug}}-design.md
```

```markdown
# Phase {{phase_id}}: {{name}} Design

**Status:** Draft | In Review | Approved | Superseded
**Implements:** {{spec path}}
**Architecture constraints:** {{master design sections}}

## 1. Existing code reused

| Existing path/symbol | Reuse, adapt, or retire | Why |
|---|---|---|

## 2. Component boundaries

画 ASCII SceneTree、依赖图或数据流；标出 owner 和生命周期。

## 3. Target file map

| File | Create/Modify/Retire | Single responsibility |
|---|---|---|

## 4. Public API and events

列出完整方法签名、输入、Result、错误码、事件 payload 和调用方向。UI 或地图不得绕过 API。

## 5. Data model

给出完整 JSON/GDScript 结构、类型、范围、不变量、canonical 顺序和 schema version。

## 6. State machines and sequencing

为任何异步、可重试或多状态流程画状态机；每个状态必须有进入、退出、timeout、cancel 和 terminal result。

## 7. Happy-path data flow

从输入源一路追到状态写入和 UI 反馈，不能只列模块名称。

## 8. Error handling

| Error code | Detection point | Rollback | Visible recovery |
|---|---|---|---|

## 9. Idempotency and concurrency

- operation/event token。
- duplicate/retry policy。
- stale callback policy。
- commit boundary and ledger。

## 10. Save and migration impact

- export/import owner。
- schema/content revision。
- old→new mapping。
- unknown value policy。
- repeated migration behavior。

## 11. Security and trust boundary

- 受信任资源映射。
- 文件读写边界。
- JSON/范围验证。
- 不可由存档控制的路径或脚本。

## 12. Performance budget

- 复杂度、每帧工作、缓存、池上限。
- 需要 profiler 证明的场景和阈值。

## 13. Test design

画覆盖图，逐分支映射 Unit/Integration/Resource/Scene/E2E/Soak。每个生产失败模式必须注明：测试、错误处理和玩家结果。

## 14. Rollout and strangler steps

- adapter first。
- pilot caller/content。
- bulk migration。
- static ban。
- removal criteria。

## 15. Rollback

- commit/tag 回滚点。
- 数据兼容。
- feature gate 或旧 adapter 恢复路径。

## 16. Alternatives considered

| Alternative | Benefit | Cost/risk | Decision |
|---|---|---|---|

## 17. Self-review

- Spec 每条 requirement 映射到设计章节。
- 无第二真相源、无新 Autoload、无隐藏路径身份。
- 所有循环/等待有界。
- 所有副作用可重试或有 ledger。
- 所有迁移可回滚且不静默丢数据。

NO UNRESOLVED DECISIONS
```

### Design 审核问题

1. 每份状态究竟由谁拥有？
2. 一个组件能否在最小夹具中实例化和测试？
3. 最坏失败会影响多少系统，能否保持旧状态？
4. 是否使用 Godot 3.5 内建 SceneTree、ResourceLoader、PackedScene、File/Directory、ConfigFile 和信号，而非自造基础设施？
5. 是否引入超出六个 Autoload 的全局状态？
6. 哪个旧入口何时删除，静态门禁如何证明？

## C. Implementation Plan 要求：定义“按什么小步骤改”

建议路径：

```text
docs/superpowers/plans/YYYY-MM-DD-phase-{{phase_id}}-{{slug}}-implementation.md
```

每份实际计划必须以此头部开始：

```markdown
# Phase {{phase_id}}: {{name}} Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** {{one observable outcome}}

**Architecture:** {{2-3 sentences describing the approved design}}

**Tech Stack:** Godot 3.5.3, GDScript, PowerShell test orchestrator

---
```

实际 Implementation Plan 必须满足：

- 开头先列精确文件结构和每个文件的单一职责。
- 每个 Task 是一个可单独提交的逻辑单元。
- 每个 Step 只做一个 2～5 分钟动作。
- 严格顺序：写失败测试 → 运行并看到指定失败 → 最小实现 → 运行并通过 → 相关回归 → 精确暂存 → 提交。
- 每个代码步骤给出完整代码或精确 patch，不写“实现相应逻辑”。
- 每个命令给出工作目录、完整参数、期望退出码和期望 `TEST_RESULT`。
- 每个验证命令先标记 lane。确定性功能/资源 lane 使用 Godot 3.5.3 的 `--no-window --audio-driver Dummy`，需要帧确定性时才加 `--fixed-fps 60`。
- 性能 lane 必须使用最低配置上的可见 Windows Release 构建、真实时钟/渲染驱动且禁止 `--fixed-fps` 和 `--no-window`；视觉/音频人工 lane 使用实际窗口/音频设备。任何 lane 都不用 Godot 4 API。
- 不使用裸 `assert` 作为唯一失败机制。
- 禁止 `git add -A`；列出精确路径。
- 每个迁移步骤都要有旧 fixture、失败回滚和重复迁移测试。
- 计划结尾执行 Spec coverage、placeholder scan、类型/签名一致性自审。

### Task 颗粒度示例

```markdown
### Task 3: Reject stale or duplicate transition completion

**Files:**
- Modify: `autoload/SceneManager.gd:{{exact lines after plan author reads file}}`
- Test: `tests/integration/test_scene_transition_tokens.gd`

- [ ] **Step 1: Add the exact failing stale/duplicate-token callback case**
- [ ] **Step 2: Run only that test and verify `duplicate_transition` failure is missing**
- [ ] **Step 3: Add the minimal token guard from the approved Design**
- [ ] **Step 4: Run the test and verify one terminal result and unchanged world hash**
- [ ] **Step 5: Run the complete integration suite and log classifier**
- [ ] **Step 6: Stage the two exact files and commit**
```

上例只展示形状。实际计划必须填入代码、行号、命令和预期输出后才能批准。

## D. Acceptance Report 模板：定义“拿什么证明完成”

建议路径：

```text
docs/superpowers/reports/YYYY-MM-DD-phase-{{phase_id}}-{{slug}}-acceptance.md
```

```markdown
# Phase {{phase_id}}: {{name}} Acceptance Report

**Spec:** {{path and commit}}
**Design:** {{path and commit}}
**Plan:** {{path and commit}}
**Implementation range:** {{first commit}}..{{last commit}}
**Godot:** 3.5.3.stable.official.6c814135b
**Result:** PASS | FAIL

## 1. Delivered scope

逐条映射 Spec requirement ID → implementation commit → test evidence。

## 2. Automated evidence

| Command | Exit | TEST_RESULT | Unclassified errors | Artifact |
|---|---:|---|---:|---|

## 3. Manual evidence

记录视觉、动画、音频、手感和恢复体验；附绝对路径截图或录屏。

## 4. Migration evidence

列出 fixtures、旧/新 hash、unknown policy 和 repeated migration 结果。

## 5. Performance and leak evidence

列出场景、帧数、median/1% low、内存、节点/Timer/信号前后值。

## 6. Static gates

列出 change_scene、Autoload、legacy dependency、稳定 ID 和断引用扫描结果。

## 7. Git and workspace hygiene

列出有意提交文件；证明未混入 `.tools`、未审查 `.import` 或场景自动帧差异。

## 8. Known warnings

每条 warning 必须含 owner、原因、到期 Phase；没有则写 None。

## 9. Rollback point

记录可恢复的 commit/tag 和数据兼容说明。

## 10. Final checklist

- [ ] Spec 全覆盖
- [ ] 所有相关测试通过
- [ ] 日志无未分类错误
- [ ] 迁移/重复 apply/失败原子性通过
- [ ] 文档与实现一致
- [ ] 工作树只含已知用户/生成差异

PASS requires every checked item.
```

## E. 文档批准顺序

```text
讨论 Phase outcome
  → Spec Draft
  → Spec 自审 + 用户批准
  → Design Draft
  → Eng review + 用户批准
  → Implementation Plan
  → Plan 自审
  → Inline/Subagent execution
  → Acceptance Report
  → Gate/next Phase
```

不得在 Spec/Design 存在未决决定时用 Implementation Plan 替用户做产品决定。不得在 Acceptance Report 缺证据时仅凭“我已经实现”进入下一 Phase。
