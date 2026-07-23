# QQSanGuo

## Inventory Foundation

Phase 22 has begun with stable item template IDs, stack capacity, and explicit identities for non-stack instances. The legacy UI-backed inventory remains in place while the 50-slot command model and migration are built.

The inventory foundation now includes a versioned 50-slot state with deterministic stack insertion, capacity-safe failure handling, slot movement, stack splitting, quest-safe consumption, canonical export, and v0-to-v1 migration. Its deterministic 1,000-command regression verifies quantity conservation and canonical round trips. `GameStateV2` now owns the inventory section at v1, upgrades only empty legacy v0 sections, and rejects unknown or lossy migrations.

The migration boundary now includes a tested legacy inventory bridge: explicit item-name aliases import old slots into canonical state, command operations mutate that state, and a compatibility projection preserves the shape consumed by the existing UI.

`PlayerInventory.add_item` now routes pickups through this bridge when item metadata is available, so stack capacity and full-inventory rejection are enforced by the canonical command model before the legacy UI projection is refreshed.

The inventory and hotbar presenters retain their existing interaction flow, while inventory take, place, and quantity-adjust methods now also use the bridge where item metadata is available. The hotbar remains a separate legacy collection until its dedicated migration phase.

Remaining inventory UI callers now invoke `PlayerInventory` commands instead of editing its dictionary directly, including item consumption and legacy slot widgets.

Legacy import now reconstructs a distinct `instance_id` for every non-stack item, so duplicate equipment names remain distinguishable after migration.

## Equipment Foundation

Phase 23 has begun with a versioned 10-slot equipment model. It validates item slot, job, and level eligibility, supports equip/swap/unequip, and recomputes derived modifiers from base stats rather than incrementally mutating attributes. `GameStateV2` now owns equipment section v1, upgrades only empty v0 sections, and rejects lossy or future formats.

PlayerStats now exposes the same composition path used by equipment: level-derived base values are calculated first, then equipment modifiers are aggregated, so repeated recalculation is deterministic.

EquipmentState now provides an idempotent v0 migration using explicit legacy-name definitions; repeated legacy names receive stable, slot-distinct instance identities.

The legacy equipment bridge now converts existing item JSON fields into canonical modifiers, validates job and level gates, and projects equipped names back to the current UI dictionary.

## Economy Foundation

Phase 24 has begun with WalletState: versioned money and juntuan balances, non-negative preflight, and an operation ledger that makes rewards and transactions idempotent. `GameStateV2` now persists wallet section v1 and safely initializes older envelopes that lack the section.

The legacy wallet bridge imports current balances, applies explicit operation IDs through the ledger, and projects the result back to the existing UI fields.

`Steve.gd` rewards now call `PlayerInventory.apply_wallet_operation`; legacy callers remain compatible, while callers that provide a stable operation ID gain duplicate-reward protection.

EconomyTransaction now atomically preflights a wallet debit and inventory grant: insufficient balance, capacity failure, or duplicate operation IDs leave the transaction state unchanged.

RewardService uses the same ledger to atomically grant money, juntuan, and optional item stacks; a full inventory prevents all reward components from committing.

## Enhancement Foundation

Equipment instances now persist an independent `enhancement_level` from `+0` through `+10`; existing equipment v1 saves migrate losslessly to `+0`.

Enhancement uses explicit `10000` to `14000` basis-point multipliers in 4% steps and deterministic nearest-integer rounding for every modifier. Enhanced modifiers and `power_score` are derived from immutable base modifiers, so repeated presentation cannot drift stats.

The enhancement transaction atomically debits a tiered money quote and one matching material before advancing an equipment instance; insufficient money/materials and duplicate operation IDs leave all state unchanged.

The legacy equipment bridge now also exposes a presenter-safe name, enhancement-level, and power-score projection for each fixed slot.

`EquipmentPresenter` turns canonical slots into UI-safe empty states, titles, enhancement levels, and power scores without mutating gameplay state.

## Loot Foundation

Phase 26 begins with a seed-deterministic LootTable supporting guaranteed drops, basis-point chances, quantity ranges, and flag-gated entries.

RewardService now preflights and commits multiple item drops with wallet rewards as one ledger-backed transaction.

LootRewardService resolves stable loot IDs to item templates and commits the whole result through that same ledger-backed transaction.

WorldPickup removes a world drop only after its reward transaction succeeds, so full inventories preserve the pickup.

## World State Foundation

GameStateV2 now persists a versioned WorldState v1 for flags, unlocked maps, defeated bosses, checkpoints, and once-only world operations; older empty world sections migrate safely.

WorldState commands apply flag, map-unlock, boss-defeat, and checkpoint changes through an idempotent operation ledger.

MapAccessPolicy checks registered map/spawn targets and WorldState unlocks before a scene transition is attempted.

SceneManager now exposes an access-gated world replacement path that preserves the active world when a transition is locked.

## Dialogue Foundation

Phase 28 begins with stable NPC and dialogue definitions, including flag-gated dialogue nodes that do not depend on scene node paths.

InteractionLock ensures only one NPC interaction can be active, preventing double-click and stale-callback overlap.

DialoguePresenter emits UI-safe available lines, while InteractionSession releases the lock when a dialogue closes.

## Quest Foundation

Phase 29 begins with a deterministic five-state quest model and idempotent event IDs for unlock, accept, objective completion, and turn-in.

DefeatRewardGate claims stable defeat IDs once, preventing duplicate death callbacks from spawning duplicate rewards.

The legacy dengmao Boss death adapter now uses that gate before it emits drops, money, or experience.

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
