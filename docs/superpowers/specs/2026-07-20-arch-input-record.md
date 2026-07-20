# QQSanGuo `arch.md` 架构输入记录

**记录日期：** 2026-07-20\
**用途：** 让 fresh checkout 能复现本轮规划采用了哪些原始方向，而不依赖某个 worktree 外的未跟踪文件。\
**规范性：** 本记录只保存来源和决策谱系；V1 的规范要求以同目录 Master Spec、Architecture Design 和 Roadmap 为准。

## 1. 原始输入

| 字段 | 值 |
|---|---|
| 原始路径 | `D:\AI coding\QQSanGuo\arch.md` |
| 原始状态 | 主工作区未跟踪文件，不存在于 `game-state-save` worktree |
| 行数 | 1,187 |
| SHA-256 | `8731C8420DC4898D3F23F5CC5D2174BE3F45F3313C846594B30593DBB409F397` |
| 审阅范围 | 全文 |

原始文件用于提出方向和系统清单，不再作为后续 Phase 的隐式依赖。若以后重新提供同名文件，必须先比对 SHA-256；哈希不同视为新的架构输入，不能静默覆盖本记录。

## 2. 已采纳并进入规范文档的方向

- 目标产品是 Godot 3.5.3、Windows 64 位、本地离线单人怀旧版。
- 复用现有场景与素材表现，逻辑采用渐进绞杀，不做一次性大爆炸重写。
- 使用持久 `GameRoot`，地图切换只事务式替换 `WorldRoot`。
- 全局边界收敛为六个 Autoload：GameState、SaveManager、SceneManager、ContentRegistry、EventBus、AudioManager。
- 玩家、战斗、敌人、物品、任务、经济和 Encounter 使用普通节点/Reference 领域组件，由 GameRoot 组装。
- 内容身份使用稳定 ASCII ID，中文名称只用于显示；ContentRegistry 是唯一可信资源映射入口。
- 运行状态、存档、UI 表现分离；UI 不保存第二份业务状态。
- V1 内容目标固定为 8 地图（含 2 副本）、24 任务、10 普通敌人、4 Boss、8 技能、30 装备、12 其他物品、等级 30 和确定性 +0～+10 强化。
- 开发按可回滚 Phase 和 Gate 推进，每个 Phase 都要有 Spec、Design、Implementation Plan 和 Acceptance Report。

## 3. 工程审查后对原方向的关键收紧

- 目标 Autoload 不是把所有领域都做成单例；领域服务保持可实例化、可注入和可独立测试。
- `ContentRegistry` 与稳定 ID 必须先于地图注册和规范 V2 存档，避免形成两套身份系统。
- GameRoot 迁移拆成组合根、地图事务、pilot 和批量迁移，禁止继续以 `change_scene()` 替换整个树。
- 存档加载采用 owner 两阶段 `prepare/commit`，不允许某个 owner 失败后留下半加载状态。
- Godot 3.5.3 Windows 的覆盖式 `Directory.rename()` 存在先删目标的窗口，因此存档采用 A/B 双世代提交，而不是宣称单文件覆盖原子。
- EncounterDirector 只持有当前瞬时 run；Boss/副本完成和首通 ledger 由 WorldState 持久化。
- 确定性功能测试使用 `--fixed-fps`；真实性能测试使用最低配置上的 Release 构建和真实时钟，两者证据不能互相替代。
- 内容计数同时校验总数、子类型和交叉表；总数相同但分布错误不能通过。

## 4. 后续规范入口

- [V1 Master Spec](./2026-07-20-qqsanguo-v1-master-spec.md)
- [V1 Architecture Design](./2026-07-20-qqsanguo-v1-architecture-design.md)
- [V1 Roadmap](../plans/2026-07-20-qqsanguo-v1-roadmap.md)
- [Phase Spec / Design / Plan / Acceptance Template](./phase-spec-design-template.md)

后续 Phase 不需要读取 worktree 外的原始 `arch.md`。如果本记录与上述规范文档冲突，按 Master Spec 中的文档优先级和 `Supersedes` 规则处理。

## 5. 验证命令

在原始文件仍存在时，可用 PowerShell 复核：

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath 'D:\AI coding\QQSanGuo\arch.md'
```

预期哈希必须等于第 1 节记录值。
