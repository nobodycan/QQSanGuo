# QQSanGuo

## Inventory Foundation

Phase 22 has begun with stable item template IDs, stack capacity, and explicit identities for non-stack instances. The legacy UI-backed inventory remains in place while the 50-slot command model and migration are built.

The inventory foundation now includes a versioned 50-slot state with deterministic stack insertion, capacity-safe failure handling, slot movement, stack splitting, quest-safe consumption, canonical export, and v0-to-v1 migration. Its deterministic 1,000-command regression verifies quantity conservation and canonical round trips. `GameStateV2` now owns the inventory section at v1, upgrades only empty legacy v0 sections, and rejects unknown or lossy migrations.

The migration boundary now includes a tested legacy inventory bridge: explicit item-name aliases import old slots into canonical state, command operations mutate that state, and a compatibility projection preserves the shape consumed by the existing UI.

`PlayerInventory.add_item` now routes pickups through this bridge when item metadata is available, so stack capacity and full-inventory rejection are enforced by the canonical command model before the legacy UI projection is refreshed.

The inventory and hotbar presenters retain their existing interaction flow, while inventory take, place, and quantity-adjust methods now also use the bridge where item metadata is available. The hotbar remains a separate legacy collection until its dedicated migration phase.

Remaining inventory UI callers now invoke `PlayerInventory` commands instead of editing its dictionary directly, including item consumption and legacy slot widgets.

Legacy import now reconstructs a distinct `instance_id` for every non-stack item, so duplicate equipment names remain distinguishable after migration.

## Combat Gate Status

Phase 21 Combat Gate has passed. The integration lane includes a deterministic two-skill by two-enemy CombatAction matrix, fixed-seed targeting/AI/spawn trace, 54,000-tick component and real-adapter scene soaks, full manual/automation real-scene matrix coverage, and idempotent enemy rewards. The accepted Gate tag is `combat-vertical-slice`.

The current [Phase 21 Combat Gate acceptance report](docs/superpowers/reports/2026-07-23-phase-21-combat-gate-acceptance.md) records verified evidence and the remaining real-scene soak requirement.

QQ三国 Godot 3.x 本地单人原型。素材源自《QQ三国》，仅供个人学习与研究；请勿用于二次销售、商业发布或分发原始素材。

## 开发状态

项目按 [V1 路线图](docs/superpowers/plans/2026-07-20-qqsanguo-v1-roadmap.md) 分阶段推进。Phase 00～16 已完成工程基线、V2 存档/迁移基础、音频设置边界、Foundation Gate、PlayerIntent/PlayerStats，以及 Vitals 状态机与遗留生命值适配；Phase 17 已建立稳定 Actor ID、阵营与目标选择基础；Phase 18 已建立确定性 DamagePipeline 基础；Phase 19 已建立数据驱动技能解锁、MP 与冷却基础；Phase 20 已建立 EnemyBrain 状态机基础。完整 Gate 已在 Godot `3.5.3` 下通过。

## 运行与测试

项目目标引擎为 Godot `3.5.3`。将可执行文件路径传给 runner，或设置 `GODOT_BIN`：

```powershell
$env:GODOT_BIN = 'C:\path\to\Godot_v3.5.3-stable_win64.exe'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1
```

测试报告会写入 `artifacts/test-reports/`：

- `test-report.json`：机器可读的测试状态、终态和日志文件名。
- `junit.xml`：CI 可消费的 JUnit 报告。
- `*.stdout.log` / `*.stderr.log`：UTF-8 原始诊断输出。

常用命令：

```powershell
# 验证 runner 本身能识别通过、失败、超时和 ERROR 假绿。
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1 -SelfTest

# 只运行资源审计。
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1 -Lane resource

# 在完成 Godot 导入后运行图标回退回归用例。
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1 -Lane unit
```

没有 Godot 时，GDScript 测试会标记为 `blocked_tool_missing` 并使全量运行失败，避免误判通过。

## 旧代码入口

- 玩家脚本：`Character/Steve.gd`
- 怪物脚本：`Enemy/Snake.gd`
- Boss 脚本：`Character/dengmao.gd`
