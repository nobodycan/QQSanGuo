# QQSanGuo V1 40-Phase Roadmap

> **For agentic workers:** 每个 Phase 在实施前必须从 Phase 模板生成独立 Spec、Design 和 Implementation Plan；Implementation Plan 必须使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 逐任务执行。不得把本路线图当成跳过详细计划的许可。

**Goal:** 在 Godot 3.5.3 上，将当前战斗原型渐进改造成可从新档完整通关、稳定存读档的本地单人 V1。\
**Architecture:** 持久 GameRoot 只替换 World 子场景；六个 Autoload 处理跨场景基础设施；领域状态由普通组件/服务持有；稳定 ID 和 ContentRegistry 位于地图、存档和内容系统之前。\
**Tech Stack:** Godot 3.5.3、GDScript、JSON、ConfigFile、PowerShell 测试编排、Windows 64 位导出。

---

## 1. 路线图使用规则

### 1.1 Phase 编号

本路线图共 40 个 Phase，编号为 0～39。编号稳定；若以后插入工作，使用 `Phase 18A` 之类的附加编号，避免所有文档链接漂移。

### 1.2 四个硬 Gate

```text
Phase 0～12  → Phase 13 Foundation Gate
Phase 14～20 → Phase 21 Combat Gate
Phase 22～30 → Phase 31 RPG Loop Gate
Phase 32～38 → Phase 39 V1 Release Gate
```

Gate 不增加新功能，只验证前面累计成果。Gate 失败时回到造成失败的最早 Phase 修复，不能把失败列为“以后再说”。

### 1.3 跨 Phase 硬规则

1. 每个提交后游戏仍可启动。
2. 每个 Phase 最多引入一次有界数据迁移。
3. 新代码只允许引用目标六 Autoload；legacy allowlist 只减不增。
4. 禁止新增直接 `SceneTree.change_scene()`、中文名业务 ID、显示路径身份和地图根节点硬编码。
5. 结构改动与行为改动分开提交。
6. 测试必须同时检查退出码、`TEST_RESULT` 和未分类错误日志。
7. 内容 Phase 必须通过 schema、引用、计数、图连通和导出包校验。
8. 涉及状态时必须验证重复 apply、跨进程 round-trip 和失败原子性。
9. `.import`、`.tools`、场景自动帧变化等生成差异不得混入业务提交。
10. 每个 Gate 后创建本地 tag 和 Acceptance Report。

## 2. 总依赖图

```text
工具链/资源闭包/测试
        │
        v
六 Autoload 契约 → ContentRegistry/稳定 ID
        │                    │
        v                    v
持久 GameRoot → 地图事务/MapDefinition
        │                    │
        └──────────┬─────────┘
                   v
           GameState V2/双世代存档/迁移
                   │
                   v
             常驻 UI 与 Foundation Gate
                   │
                   v
 Intent → Stats → Vitals → Target/Hit → Damage/Effect
                                      │
                            Skill → Enemy/Spawner
                                      │
                                      v
                                 Combat Gate
                                      │
        Item/Instance → Equipment → Economy → Enhancement/Loot
                                      │
                  WorldFlags → NPC/Dialogue → Quest → Shop
                                      │
                                      v
                                 RPG Loop Gate
                                      │
          EncounterDirector → Boss → Dungeon → AutoCombat
                                      │
                         Content A → B → C
                                      │
                                      v
                                 V1 Release Gate
```

## 3. Phase 0～4：可信工程基线

### Phase 0：固定工具链、仓库和输入基线

**结果：** 任意后续执行者能确认自己使用完全相同的引擎、分支、命令和规划输入。

**范围：**

- 固定 Godot `3.5.3.stable.official.6c814135b` Windows 64 位可执行文件和对应 Windows export templates 的来源、版本及 SHA-256。
- 记录工作树、HEAD、远端、现有 13 个 Autoload、现有测试和内容计数。
- 记录最低性能机 CPU、GPU、RAM、Windows 版本、显卡驱动、GLES3 renderer、800×600 显示/VSync 模式和基线构建哈希；没有该 provenance 的性能结果无效。
- 把 `.tools/` 加入本地/仓库忽略策略，不提交引擎二进制。
- 验证仓库内架构输入记录的原始 `arch.md` 哈希和采纳决策；后续执行不依赖 worktree 外的未跟踪文件，Master Spec 成为可追踪范围来源。
- 明确 Windows 行尾和 Godot sidecar 策略；新增文本统一 LF。
- 记录当前所有工作树差异，不覆盖用户已有 `.import/.tscn/.tres` 修改。

**验证：**

- `Godot --version` 精确匹配。
- 引擎/导出模板哈希、HEAD、`git status`、内容基线和完整性能机 provenance 进入 Acceptance Report；哈希不匹配时禁止测试/导出。
- 新建干净临时 checkout 能找到项目文件，但本 Phase 不声称资源已全绿。

**退出物：** Phase 0 Acceptance Report、工具链说明、基线 manifest、最低性能机 provenance JSON。\
**依赖：** 无。\
**回滚点：** 当前 `2b59a3d` 或执行时记录的 HEAD。

### Phase 1：资源闭包与可重复干净导入

**结果：** fresh checkout 不依赖旧 `.import` 缓存也能完成导入，所有代码/场景/资源引用可解析。

**范围：**

- 禁用声明存在但仓库缺失的 `codeandweb.texturepacker` 插件。
- 建立独立资源扫描脚本，枚举 `.gd/.tscn/.tres/.json`、动态图标/音效 manifest 和跨表路径。
- 所有场景 load、instance，并运行至少 2 idle + 2 physics frame。
- 检查 Windows 大小写不敏感可能掩盖的路径大小写问题。
- 分类约 8,124 个 tracked `.import` sidecar；Godot 3.5.3 新增 importer 字段只允许在专门机械提交中固化。
- 修复资源缺失、脚本 Parser Error 和导出时不会被打入 PCK 的动态文件。

**验证：**

- fresh checkout 执行 `--editor --no-window --audio-driver Dummy --quit` 成功。
- 资源 manifest 引用解析率 100%，场景实例化成功率 100%。
- 导入完成后的第二次导入不再产生新的非预期 diff。
- 日志中 Parser Error、missing resource、missing plugin 为 0。

**退出物：** 资源扫描器、动态资源 manifest、导入策略、资源错误清单归零。\
**依赖：** Phase 0。\
**Gate tag：** `baseline-godot-3.5.3`。

### Phase 2：统一测试编排与结构化诊断

**结果：** 测试不会因退出码假绿、真实存档污染或无限等待而误判。

**范围：**

- PowerShell orchestrator + GDScript runner。
- Unit、Integration、Resource、Scene、E2E、Soak 分类。
- 每进程独立 `APPDATA/LOCALAPPDATA`。
- Unit 30 秒、Integration 60 秒、Scene 120 秒、E2E 10 分钟 watchdog。
- 确定性功能 lane 使用固定 FPS 60 和固定 RNG seed；性能 lane 使用 Release 构建、真实时钟且禁止 `--fixed-fps`。
- 唯一 `TEST_RESULT {json}` 终结协议、JUnit/JSON 汇总、heartbeat。
- Windows runner 以 UTF-8 捕获原始 stdout/stderr；结构化字段和错误码使用 ASCII，中文上下文不得乱码。
- 未分类 `ERROR:`、`SCRIPT ERROR:`、Parser Error、missing resource 即失败。
- 把现有 4 个测试迁入 runner，消除裸 `assert` 和依赖真实 `user://` 的路径。
- 为“通过、显式失败、挂起、退出 0 但打印 ERROR”建立 runner 自测夹具。

**验证：** 四个 runner 自测分别得到 pass/fail/timeout/log-error；当前测试产生机器可读报告。\
**退出物：** 单一测试命令、报告目录约定、日志 allowlist 格式。\
**依赖：** Phase 1。

### Phase 3：绞杀契约、六 Autoload 和旧依赖门禁

**结果：** 新代码从此只有一个明确的全局边界，不再增加第 14 个 Manager。

**范围：**

- 冻结六 Autoload API：GameState、SaveManager、SceneManager、ContentRegistry、EventBus、AudioManager。
- 定义结构化 Result、operation ID、event ID、deadline 和错误码规则。
- 冻结 `runtime_error.v1`：ASCII `error_code/operation_id`、显式 nullable `map_id/content_id`、frame、最多 32 项 recent-event ring 和中文附加 message；每个 operation 只有一个终态。
- 建立 EventBus 跨分支事件清单；局部组件继续使用局部信号。
- 建立 AudioManager 最小壳和独立 `settings.cfg` 读取边界。
- 为当前 13 个 Autoload 建立 legacy allowlist、负责人、替代模块和到期 Phase。
- 静态扫描新增 `change_scene()`、旧 Autoload 引用、硬编码 `Steve/UserInterFace/Level1` 和中文键身份。
- 建立运行时离线/写入静态禁令：禁止 HTTP/WebSocket/TCP/UDP 等网络客户端或服务端 API，禁止 `OS.execute/shell_open`、下载/动态解析脚本、对存档值执行 `load/preload`，禁止进度数据使用对象反序列化；动态资源路径只能由 ContentRegistry 的稳定 ID 白名单产生。
- 运行时文件写入必须经 SaveManager/Settings adapter 且规范化后位于 `user://`；开发工具脚本单列 allowlist，不得进入导出运行路径。

**验证：**

- 一个故意引用第七个 Autoload 的夹具被静态门禁拒绝。
- legacy 基线命中数可重复，后续提交不得增加。
- EventBus 重复连接测试不会多发事件。
- 保存/传送/奖励/Encounter 各一个故意失败夹具都产生字段齐全的 `runtime_error.v1`；缺字段、未知错误码、33 项 recent events 和双终态夹具被拒绝。
- 网络 API、`OS.execute`、存档驱动动态加载/执行、对象反序列化和非 `user://` 写入各有一个故意违规夹具，并均被静态门禁拒绝。

**退出物：** Autoload ADR、事件合同、legacy ledger、静态扫描器。\
**依赖：** Phase 2。

### Phase 4：ContentRegistry、稳定 ID 和内容校验

**结果：** 地图、存档和所有后续领域共享一个内容真相源。

**范围：**

- 建立 `content/v1/manifest.json` 和分类 pack 加载顺序。
- 实施 ID 正则、分类前缀、唯一性、schema、枚举和范围校验。
- 实施总数 + 子类型 + 交叉表计数：6 普通地图 + 2 副本地图、18 主 + 6 支且每章 6+2、2 主线 Boss + 2 副本 Boss、1 普攻 + 7 主动、10 槽 × 3 档、其他物品 5+3+4、杂货/装备/铁匠服务各 1。
- 实施跨表引用、场景/图标/音效存在性、任务 DAG、地图图校验接口。
- 实施技能解锁等级计划、普通敌人 encounter signature/差异矩阵、推进关键装备保证来源及最晚可达节点校验。
- 建立 legacy 中文物品名、技能名和地图路径 alias。
- 先迁入少量现有 item/skill/map 作为 pilot，旧 JSON 暂由 adapter 读取。
- 生成内容计数、引用闭包和来源/消费覆盖报告。

**验证：** 重复 ID、坏枚举、断引用、alias 冲突、任务环和缺场景夹具全部被拒绝；正常 pilot pack 可查询。\
**退出物：** Registry、manifest、validator、alias 表、内容审计报告。\
**依赖：** Phase 3。

## 4. Phase 5～13：持久运行时与存档基础

### Phase 5：持久 GameRoot 组合根

**结果：** 游戏有唯一 Main，World、Player、UI 和服务的生命周期可观察、可验证。

**范围：**

- 建立 `GameRoot/Services/WorldRoot/PlayerRoot/RuntimeActors/UIRoot/TransitionRoot/DebugOverlay`。
- 将当前主场景作为 legacy world 候选挂入 WorldRoot，不立即迁完所有地图。
- GameRoot 负责依赖注入，不把领域服务变成 Autoload。
- 建立节点计数探针和会话 instance ID。

**验证：** 重载 pilot world 100 次，GameRoot、PlayerRoot、UIRoot 各 1 个且 GameRoot instance ID 不变。\
**退出物：** GameRoot scene/script、最小服务组合、生命周期测试。\
**依赖：** Phase 4。

### Phase 6：SceneManager 地图加载事务

**结果：** 地图失败不会释放整个游戏或永远黑屏。

**范围：**

- 从 `change_scene()` 改为 `ResourceInteractiveLoader → PackedScene.instance → candidate validate → replace WorldRoot child`。
- 实施 transition token、单事务、输入锁、淡出/淡入、300 帧/5 秒 deadline。
- 旧地图保留到候选完成 commit；失败释放候选并恢复旧地图。
- A→B 未完成又请求 C、同帧双请求、旧异步结果晚到均有明确定义。

**验证：** 双触发、三连请求、加载失败、实例契约失败、超时、传送中暂停/死亡夹具均在 deadline 内返回一次终态。\
**退出物：** SceneManager V2、TransitionResult、故障注入测试。\
**依赖：** Phase 5。

### Phase 7：MapDefinition、Portal、SpawnPoint 与 pilot 地图

**结果：** 第一张地图完全由 `map_id/portal_id/spawn_id` 进入持久壳。

**范围：**

- MapDefinition 声明 scene、等级、spawn、portal、BGM 和自动战斗区。
- Portal 只发送目标 ID 请求，不直接切场景。
- SpawnPoint 校验 ID、位置和碰撞安全。
- 迁一张现有地图，移除其中 Player/UI 副本。
- 玩家死亡在该图使用定义的复活点。

**验证：** 每个 portal edge 往返 20 次；双触发不重复；出生坐标误差不超过 2 px；场景内没有 Player/UI。\
**退出物：** map/portal/spawn 合同和 pilot。\
**依赖：** Phase 6。

### Phase 8：迁移全部现有可玩地图到 GameRoot

**结果：** 现有地图都通过同一入口运行；不再按地图名称查 UI 或玩家。

**范围：**

- 为所有现有可玩地图创建 MapDefinition、spawn 和 portal edge。
- 移除地图内嵌 Player/UI/Camera 和地图脚本直接切换。
- 未完成传送口显式标成 disabled 并给出玩家提示，不能保留 `pass`。
- 建立从起始地图可达的有向图；Debug/test scene 不进入正式图计数。

**验证：** 所有现有 map ID 可 load/instance/enter/exit；直接 `change_scene()` 业务调用为 0；地图图无断边。\
**退出物：** 现有地图迁移清单、地图连通报告。\
**依赖：** Phase 7。

### Phase 9：规范 GameState V2 DTO

**结果：** 长期存档先获得不冻结文件路径、中文名或节点结构的 V2 顶层 envelope，而不提前假装未来领域字段已经完成。

**范围：**

- 冻结 metadata、location、player、wallet、inventory、equipment、skills、quests、world、legacy 顶层段及 `section_versions`；未实现领域使用 version 0 的空/default section。
- 定义 schema version、section version 与 content revision 的独立语义；高于当前支持的 section version 明确拒绝且不覆盖原档。
- 只冻结稳定 ID、JSON-safe、ItemInstance 最小身份和 ledger 幂等键等跨领域不变量；QuestProgress、dungeon state 等内部字段由所属领域 Phase 冻结并实施 `0→1` 迁移。
- Phase 9 时已存在的 owner 实施 `export_state / prepare_import / commit_import / after_import` 两阶段接口；未来 owner 必须遵守同一注册合同，GameStateCoordinator 显式按固定顺序组合，commit 段不 I/O、不加载、不 `yield`、不发中间事件。
- canonical JSON 排序和状态 hash。

**验证：** 1,000 组 envelope/已冻结 section 生成状态 encode→decode→normalize 完全等价；version 0 空段无损往返，高版本 section 被拒绝且文件不改；错型、越界、重复实例、等级 31、强化 11 被拒绝；逐现有 owner 注入 prepare 失败时 canonical hash、节点、Timer、信号和当前地图均不变。\
**退出物：** V2 envelope schema、section-version registry、当前 DTO/normalizer、property-based data generator。\
**依赖：** Phase 4、Phase 8。

### Phase 10：SaveManager 崩溃安全双世代文件事务

**结果：** 写入任一点失败都能恢复最后一次完整提交。

**范围：**

- `save_a.json/save_b.json` 扫描、有效 generation 选择和冲突诊断。
- 非活动世代 `.tmp` 写入、flush/close、canonical SHA-256 回读校验，再仅替换非活动世代文件。
- 明确 Godot 3.5.3 Windows 覆盖 rename 的删除窗口；任何一步都不得先删除最高有效 generation。
- 错误分类：missing、read、parse、schema、checksum、content、write、generation_conflict、replace_inactive。
- 保存与地图切换/奖励事务的互斥和一致性快照。
- 磁盘满、只读、temp 截断、校验后/rename 删除窗口/最终校验前中断、双文件冲突等故障注入点。

**验证：** 每个故障点 20 次，始终至少保留并加载一个有效世代；若更高 generation 已完整落盘则选择它，否则选择先前活动世代；失败保存不破坏最后已提交快照。\
**退出物：** SaveManager V2、双世代选择器、fault injector、崩溃安全测试。\
**依赖：** Phase 9。

### Phase 11：V1→V2 迁移与正式切换

**结果：** 现有已完成 V1 存档脚手架成为兼容输入，而不是第二套长期格式。

**范围：**

- map path、中文物品/技能名、装备名、旧属性和 `juntuan` 的明确映射。
- 原 V1 文件只读备份、迁移报告、unresolved 隔离。
- 迁移候选全部 prepare/验证成功后才写 `save_a.json` generation 0；失败不产生 V2 世代，成功后再次启动优先 A/B 且不重复迁移 V1。
- 未知地图阻断；未知物品/技能不静默丢失。
- 旧 SaveState 只做 forwarding adapter；新 UI 入口使用 SaveManager。
- 正式新写入只产生 V2。

**验证：** 所有 V1 golden fixture 成功迁移或返回精确 unresolved；迁移重复两次结果相同；失败迁移不改当前状态。\
**退出物：** migrator、golden fixtures、迁移 UX、cutover 记录。\
**依赖：** Phase 10。

### Phase 12：启动路由、常驻 UI 壳、Presenter 与设置/音频接入

**结果：** 玩家从可诊断的主菜单新建或继续；切地图不再重建 UI，UI 不成为第二份业务状态。

**范围：**

- 常驻 HUD、背包/快捷栏容器、对话/任务/商店占位入口和错误提示层。
- BootRouter 和主菜单状态：无档时“新游戏”可用而“继续”禁用；有效 V2/可迁移 V1 时“继续”可用；最高世代坏但另一世代有效时显示恢复来源；全部候选无效时禁用“继续”并提供错误码和新游戏动作。
- Presenter 接口和 legacy adapter；领域 presenter 随后续 Phase 逐个替换。
- EventBus 连接生命周期和重复连接保护。
- `settings.cfg` 的音量、显示、键位基础；AudioManager 跨地图 BGM。
- 保存/加载失败、较低有效世代恢复和迁移摘要的可见 UI。

**验证：** 100 次 world 替换后 UI 仍 1 份；信号/Timer 净增长 0；重复 refresh 不生成重复 Item 节点。隔离用户目录下分别运行无档、有效 V2、可迁移 V1、坏高世代 + 有效低世代、全部坏档五个启动夹具；按钮状态、路由、恢复摘要和终态错误码符合定义，0 黑屏/无限等待。\
**退出物：** UIRoot、Presenter contract、Settings/Audio adapter。\
**依赖：** Phase 11。

### Phase 13：Foundation Gate

**结果：** 可以安全开始重写战斗领域。

**硬门槛：**

- 连续运行 30 分钟，未分类 Error 为 0。
- 现有每条 portal edge 至少 100 次，0 hang；GameRoot/Player/UI 各 1 个。
- 100 次 V2 save/load + 20 次真实进程重启，规范状态一致。
- 同一快照 apply 1、2、10 次后状态 hash、派生字段、节点/信号/Timer 增量为 0。
- 所有 V1 fixture 按预期迁移；未知值策略有测试。
- SceneManager 外直接 `change_scene()` 为 0。
- 新代码违反六 Autoload 合同的命中为 0；legacy allowlist 较 Phase 3 只减不增。
- 从隔离的空用户目录启动可进入新游戏主菜单；有效档和损坏档夹具分别进入继续或恢复终态，0 黑屏/无限等待。

**退出物：** Foundation Acceptance Report。\
**依赖：** Phase 0～12。\
**Gate tag：** `foundation-v2`。

## 5. Phase 14～21：统一 Actor 与战斗纵切片

### Phase 14：PlayerIntent、移动组件和动画适配

**结果：** 手动输入和未来自动战斗共用一条命令入口，移动逻辑从 `Steve.gd` 抽出。

**范围：** Intent 类型、输入采样、移动/跳跃/爬梯/下平台、输入锁、动画适配；保持现有手感基准。\
**验证：** 每个移动状态 600 帧；状态切换无永久锁；手动 Intent 可中断模拟自动 Intent。\
**依赖：** Phase 13。

### Phase 15：PlayerStats 与 1～30 级成长

**结果：** 等级/经验/基础与派生属性只有一个权威来源。

**范围：** 显式 XP 表、跨多级、30 封顶、基础属性、派生计算器、旧 PlayerInventory 属性 adapter；冻结 player section v1 并提供 v0→v1 迁移。\
**验证：** 每级 XP 的 N-1/N/N+1、一次跨多级、满级溢出；不得出现 31；player v0 fixture 迁移/重复 apply/V2 round-trip。\
**依赖：** Phase 14。

### Phase 16：Vitals、恢复、死亡与复活

**结果：** HP/MP、alive、恢复和死亡/复活使用一致状态机。

**范围：** clamp、恢复 tick、死亡去重、复活点查询、死亡时取消攻击/自动控制/交互。\
**验证：** 0/负/超上限值、重复死亡事件、切图中死亡、检查点缺失均有终态。\
**依赖：** Phase 15。

### Phase 17：Faction、Targetable、Hitbox/Hurtbox

**结果：** Actor 不再依赖节点必须名为 `Steve` 或敌人必须有 `Sprite` 子节点。

**范围：** Actor ID、阵营、目标注册、稳定选择顺序、Hitbox/Hurtbox 命中事件、目标释放处理。\
**验证：** Player/Enemy/Boss 在最小夹具独立实例化；目标释放后 2 帧内清除；友军不被攻击。\
**依赖：** Phase 16。

### Phase 18：Damage/Effect/状态管线

**结果：** 所有 Actor 共享可注入 RNG 的纯战斗计算。

**范围：** CombatAction、DamageResult、EffectResult、暴击/防御/倍率顺序、状态 tick/叠层/刷新/互斥、defeat event ID。\
**验证：** 边界表、固定种子复现、无 NaN、HP/MP 不越界；重复 hit ID 不二次结算。\
**依赖：** Phase 17。

### Phase 19：技能框架与两个 pilot 技能

**结果：** 技能数据真正控制消耗、冷却、命中和表现，而不只切动画。

**范围：** SkillDefinition（含 `unlock_level`）、SkillBook、SkillController、施法验证、MP、cooldown、取消、命中 marker、动画/音频 adapter；迁入等级 1 普攻和等级 3 主动技能；冻结 skills section v1 并提供 v0→v1 迁移。\
**验证：** 等级 0/1 与 2/3 的 locked→unlocked 边界、重复升级幂等、未解锁装备/施放拒绝、消耗、冷却、MP 不足、目标失效、取消、重复 marker；每个命中时点严格一次；skills v0 fixture 迁移和 round-trip。\
**依赖：** Phase 18。

### Phase 20：EnemyDefinition、EnemyBrain 与 Spawner

**结果：** 两个 pilot 敌人通过定义和统一管线工作，Spawner 不再固定 preload Snake。

**范围：** AI 状态、发现/追击/攻击/脱战/不可达/死亡/重生、生成作用域、`encounter_signature`/`primary_encounter_difference`、两个现有敌人迁移。\
**验证：** 两个 pilot 的 stats/loot/telegraph/AI role signature 不同且固定种子 trace 证明主差异；10,000 AI tick；目标销毁、玩家离图、边缘、脱战、重复 death；Spawner 只生成/清理不发第二份奖励。\
**依赖：** Phase 19。

### Phase 21：Combat Gate

**硬门槛：**

- 2 技能 × 2 敌人的完整手动和自动驱动测试通过。
- 玩家和敌人伤害 100% 经过 CombatAction/DamageEffect/Vitals。
- 固定种子输出完全可复现。
- 15 分钟战斗浸泡中无空目标、永久状态、双击杀或双奖励。
- `Steve.gd`/`Snake.gd` 新战斗逻辑命中数为 0；legacy adapter 命中继续下降。

**退出物：** Combat Acceptance Report。\
**依赖：** Phase 14～20。\
**Gate tag：** `combat-vertical-slice`。

## 6. Phase 22～31：物品、经济、世界与任务闭环

### Phase 22：ItemTemplate、ItemInstance 与 Inventory Command

**结果：** 堆叠物和装备实例有正确身份，UI 不再直接改背包 Dictionary。

**范围：** 50 槽背包、stack/instance、容量、移动、拆分、消耗、任务物品规则、canonical export/import；冻结 inventory section v1 并提供 v0→v1 迁移。\
**验证：** 1,000 次随机命令保持数量守恒；满包、叠堆、同名不同实例、重复 apply；inventory v0→v1 迁移重复两次和 round-trip 等价。\
**依赖：** Phase 21。

### Phase 23：Equipment、槽位和 Modifier 重算

**结果：** 10 槽穿脱从基础值重算，不再靠增减属性。

**范围：** 槽位/职业/等级校验、equip/swap/unequip、Modifier 聚合、派生属性、Inventory/Equipment presenter；冻结 equipment section v1 并提供 v0→v1 迁移。\
**验证：** 每槽全路径；同一序列重复 10 次属性不漂移；equipment v0→v1 迁移重复两次和存读档后等价。\
**依赖：** Phase 22。

### Phase 24：Wallet、Reward 与原子 EconomyTransaction

**结果：** 金币、物品、材料和一次性奖励可全成或全败。

**范围：** wallet、delta、preflight、commit ledger、RewardService、故障注入；冻结 wallet section v1 并提供 v0→v1 迁移；建立 XP/金币来源消费和经济模拟器基础。\
**验证：** 容量/余额/材料/重复 operation/中途失败；任何失败前后规范 hash 不变；wallet v0→v1 迁移重复两次和 round-trip 等价。\
**依赖：** Phase 23。

### Phase 25：确定性强化 +0～+10

**结果：** 两件同名装备可有不同强化等级，成本和属性均可存档。

**范围：** 11 个等级、10000～14000 basis-points 显式倍率、统一四舍五入、三档成本表、`power_score`、材料消费、+10 拒绝 +11、强化 UI presenter。\
**验证：** 每级倍率和取整、金币/材料不足、重复 operation、V2 往返；每槽位断言“上一档 +10 夹在下一档 +2/+3”；每件总金币为买价 1.90～2.10 倍且材料 8～12；无失败/降级分支。\
**依赖：** Phase 24。

### Phase 26：LootTable、奖励结算和拾取

**结果：** 敌人、Boss、任务和副本使用统一奖励，背包满不吞物。

**范围：** 保证/概率掉落、数量、任务条件、固定 seed、world pickup、满包、唯一 defeat event；推进关键装备的 `progression_critical/required_before_quest_id/guaranteed_source_ids`。\
**验证：** Monte Carlo 分布容差、关键任务物 100%、每件推进关键装备至少一个非随机来源在门槛前可达、双 death/Spawner 不双发、拾取后数量守恒。\
**依赖：** Phase 24、Phase 25。

### Phase 27：WorldState、Flags 和地图解锁

**结果：** 任务、NPC、Boss 和副本共享可存档的世界真相源。

**范围：** flags、unlocked maps、defeated bosses、checkpoints、dungeon state、一次性 ledger；MapDefinition 条件；冻结 world section v1 并提供 v0→v1 迁移。\
**验证：** 重复 flag、重复首通、锁图传送、存读档和失败回滚；world v0→v1 迁移重复两次等价。\
**依赖：** Phase 26。

### Phase 28：NPC 注册、交互锁与对话树

**结果：** NPC 不靠地图节点路径，交互和条件对话可重放。

**范围：** NPCDefinition、DialogueDefinition、交互半径、单交互锁、World/Quest 条件、对话 presenter。\
**验证：** NPC 消失、玩家离开、双击、切图、条件分支、关闭 UI 后输入恢复。\
**依赖：** Phase 27。

### Phase 29：QuestService 与 pilot 任务链

**结果：** 一条完整主线/支线 pilot 可接取、推进、交付、奖励和存档。

**范围：** 五态状态机、prerequisite DAG、talk/kill/collect/enter_map/boss/dungeon objectives、幂等奖励、quest presenter、任务图校验器；冻结 quests section v1 并提供 v0→v1 迁移。\
**验证：** 100 次重复事件只奖励一次；前置环/孤儿拒绝；任务每个状态存读；满包任务物策略；quests v0→v1 迁移重复两次等价。\
**依赖：** Phase 28。

### Phase 30：商店服务与交易 UI

**结果：** 杂货、装备和铁匠三种服务通过 EconomyTransaction 工作。

**范围：** ShopDefinition、buy/sell/price/permission、容量/余额、`max(1,floor(base_price×0.25))` 卖价、强化入口、三种 presenter。\
**验证：** 卖价取整边界、负余额、满包扣钱、复制/吞物、贴图同名、买卖套利、双击交易均被阻止。\
**依赖：** Phase 29。

### Phase 31：RPG Loop Gate

**硬门槛：**

```text
新档 → 接任务 → 战斗 → 任务掉落 → 装备
     → 买卖 → 强化 → 交任务 → 解锁地图
     → 保存 → 真正结束进程 → 加载继续
```

- 上述路径 20～30 分钟内自动和人工各完成一次。
- 同一 checkpoint 连续三次跨进程恢复 canonical hash 一致。
- 交易、任务、掉落和强化所有副作用有 ledger，重复操作无第二次收益。
- legacy PlayerInventory 背包/装备写入口不再被新代码调用。

**退出物：** RPG Loop Acceptance Report。\
**依赖：** Phase 22～30。\
**Gate tag：** `rpg-loop-vertical-slice`。

## 7. Phase 32～39：Encounter、内容波次和发布

### Phase 32：EncounterDirector

**结果：** Boss、副本和波次有统一的作用域、重置和奖励语义。

**范围：** run ID、prepare/start/victory/failure/abort/cleanup、作用域生成、Timer/信号/Actor 归属、向 WorldState/EconomyTransaction 的幂等完成命令、调试命令；当前 run 不进入存档。\
**验证：** 进入、退出、死亡、重入、双完成、地图切换、旧回调晚到各 100 次；作用域资源净增长 0。\
**依赖：** Phase 31。

### Phase 33：Boss 框架与邓茂 pilot

**结果：** 一个现有 Boss 成为可复用阶段框架的迁移级 pilot；是否计入启用内容由后续 Content Wave 决定。

**范围：** intro、phase、transition、telegraph、技能调度、reset、arena、defeat；迁移邓茂；Boss 攻防全部适配 `CombatAction → Damage/Effect → Vitals`，完成奖励经 EncounterDirector 的幂等命令提交。\
**验证：** 20 个固定种子整场；玩家死亡/离场/切图；Boss/玩家每次伤害均有统一管线 operation trace，Boss 脚本直接写 HP/Vitals 的静态命中为 0；0 永久无敌、0 双奖励、0 残留 Actor。\
**依赖：** Phase 32。

### Phase 34：单人副本框架与一个 pilot

**结果：** 一个 10～15 分钟的开发态副本 pilot 可进入、失败、重试、首通并安全退出。

**范围：** 2～3 波、检查点、Boss、退出/恢复、首通和重复奖励、不保存瞬时敌人；pilot 默认不进入启用 manifest，在 Phase 37 以 12～16 级第一副本发布。\
**验证：** 20 次通关 + 20 次失败/重试；按 ACTIVE→VICTORY 且暂停停表的基准，推荐等级/标准装备固定路线 active time 为 10～15 分钟；副本状态不泄漏到世界；首通严格一次。\
**依赖：** Phase 33。

### Phase 35：前台普通野外自动战斗

**结果：** 自动战斗只通过公共 Intent/Skill/Inventory API 工作，并可无人值守自验证。

**范围：** search/approach/attack/recover/loot/unstuck/stop、zone/半径/巡逻锚点、手动中断、药品、满包、死亡；stop reason 固定为 manual、inventory_full、death、recovery_consumable_missing、quest_target_completed、zone_exit、activity_radius_exit、no_reachable_target、transition、pause_or_blocking_ui、boss_or_dungeon；同时完成 E2E scenario driver 和 soak heartbeat。

**验证：**

- 空目标、不可达、目标释放、无 MP、冷却、暂停、UI、传送、死亡、手动关闭。
- 满包、需要恢复但无药、任务目标完成、离开 zone、离开活动半径和无可达目标分别得到正确 stop reason；1 物理帧内恢复手动，终态后 0 新 CombatAction/拾取/奖励事务。
- 目标失效 2 帧内清除，关闭 1 帧内恢复手动。
- 60 分钟 pilot 浸泡无 hang/crash；不进入 Boss/副本。
- 相同地图、装备、药品和固定种子的 60 分钟对照中，每分钟金币 + 经验为手动场景驱动基准的 70%～90%，且奖励事务没有自动战斗专用倍率。

**依赖：** Phase 34。

### Phase 36：Content Wave A，1～10 级

**累计目标：** 3 张普通可玩地图、0 副本、8 任务（6 主 2 支）、4 普通敌人、1 个主线地图 Boss、4 技能、10 装备、4 其他物品、2 种服务组合。

**范围：** 把 Phase 33 的 Boss 框架用于第一章主线地图 Boss，完成第一章新档到章节 Boss 的可通关路径；Phase 34 副本 pilot 保持禁用；所有启用内容通过 manifest、经济模拟和资源校验。

**验证：** 3 个固定种子完成第一章；无稀有掉落门槛；章节结束约 9～10 级；所有 portal edge 往返 20 次。\
**依赖：** Phase 35。

### Phase 37：Content Wave B，11～20 级

**累计目标：** 6 地图（含 1 副本）、16 任务、7 普通敌人、2 Boss（1 主线地图 + 1 副本）、6 技能、20 装备、8 其他物品、3 种服务组合。

**范围：** 第二章、将 Phase 34 pilot 固化为 12～16 级第一副本及其 Boss、中档装备与材料、技能 5～6；调整第一章来源/消费而不破坏旧存档。

**验证：** 从 Wave A 存档升级到本内容 revision；3 个固定种子完成第二章；章节结束约 19～20 级；第一副本完成 20 次通关 + 20 次失败/重试，固定基准 active time 为 10～15 分钟。\
**依赖：** Phase 36。

### Phase 38：Content Wave C，21～30 级及 V1 内容锁定

**最终目标：** 8 地图、24 任务、10 普通敌人、4 Boss、2 副本、8 技能、30 装备、12 其他物品、3 种服务组合、等级 30、强化 +10。

**范围：** 第三章、第二个主线地图/最终 Boss、24～30 级第二副本及其 Boss、终档装备/强化材料、技能 7～8、主线结局；冻结 `content_revision=v1.0.0`。

**验证：**

- 5 个固定种子从新档完成主线，结局时 27～29 级。
- 全支线/副本首通后稳定到 30。
- 校准后的固定场景驱动记录主线路径 4～6 小时、全内容路径 6～8 小时；任何主线前置的纯刷怪区段不超过 15 分钟，并输出每段来源/消费/经验账本。
- 经济模拟逐件验证 +10 倍率/取整、跨档 power_score、1.90～2.10 倍金币成本、8～12 材料和 25% 卖价；标准全清路线扣除主线必需消费后可 +10 终档 1～2 件但不足以无刷取全身 +10。
- 24 任务全部从新档可达；前置图无环。
- 30 装备全部可获得、穿脱、卖出、强化和存读。
- 内容计数精确，引用闭包 100%，无等级超过 30 的启用物品。
- 内容子类型和交叉表精确：地图 6+2、任务 18+6 且每章 6+2、Boss 2+2、技能 1+7、装备 10 槽×3 档、其他物品 5+3+4、杂货/装备/铁匠服务各 1；任何总数相同但分布错误的夹具必须失败。
- 8 个技能解锁等级精确为 1/3/6/10/14/18/23/28，并从新档在边界前锁定、边界时幂等解锁。
- 10 个普通敌人的 encounter signature 两两不同，10 行差异矩阵均有固定种子行为 trace；纯换表现的重复 signature 夹具失败。
- 每件 `progression_critical` 装备的非随机来源在声明门槛前可达，source coverage=100%；随机掉落不计保证来源。
- 两个正式副本分别按统一 ACTIVE→VICTORY/暂停停表口径得到 10～15 分钟固定基准 active time。
- 8 个启用技能均只经 ContentRegistry/SkillController，8 个启用地图均通过无内嵌 Player/UI 的 scene contract；旧技能工厂和地图自带常驻节点调用为 0。

**依赖：** Phase 37。

### Phase 39：V1 Release Candidate、长稳与 Windows 发布

**结果：** 不是“能跑一次”，而是可重复导出和完整通关的本地 V1。

**硬门槛：**

- fresh checkout 导入、全测试、Debug export、Release export 全绿。
- 从全新 Release 目录和隔离用户目录黑盒启动：无档进入可新建主菜单；有效档可继续；坏档走已定义恢复路径，均不得黑屏或无限等待。
- 发布候选连续 10 次流水线全绿，不允许 flaky 重跑。
- 2 小时 soak：至少 1,000 传送、100 跨进程存档恢复、10,000 普通战斗。
- 未分类 `ERROR:`、Parser Error、missing resource 为 0；warning allowlist 到期项为 0。
- 每条预期失败日志都符合 `runtime_error.v1`；缺 error code/operation ID/nullable map-content 字段/recent-events 或 operation 无唯一终态时，即使退出码为 0 也阻断发布。
- GameRoot/Player/UI 始终各 1 个；节点/Timer/信号净增长 0。
- 内存增长同时不超过 5% 和 32 MiB。
- 正常战斗 median ≥60 FPS、1% low ≥45 FPS；标记加载区间之外的最大单帧 ≤250 ms；保存/加载/传送满足 Master Spec 性能门，并输出 profiler/JSON 原始证据。
- 3 次完整空档通关 + 3 次中途存读档人工/自动回归；空档通关记录真实活动时长，至少覆盖主线直达和全清路线，并证明主线 4～6 小时、全清 6～8 小时、主线强制纯刷怪单段不超过 15 分钟。
- 三次空档记录同时包含两个副本的统一 active-time 区间；每个副本每次均为 10～15 分钟，暂停/加载计时规则与固定基准一致。
- 目标六 Autoload 之外的 legacy 例外归零。
- Release PCK 内再次执行同一资源 manifest；导出程序无人值守运行 30 分钟。
- Release 构建在 outbound-deny/连接监控和隔离文件系统下复跑：尝试网络连接为 0，Release 目录写入为 0，所有运行时写入仅落在指定 `user://`；导出模板哈希与 Phase 0 一致。
- 版本号、CHANGELOG、已知限制、存档迁移说明和本地 tag 完成。

**退出物：** V1 Acceptance Report、Windows 64 位本地构建、校验和、变更日志。\
**依赖：** Phase 0～38。\
**Gate tag：** `v1.0.0-local`。

## 8. 需求到 Phase 的追踪矩阵

下面的矩阵用于防止“路线图有阶段、Master Spec 有要求，但两者没有闭环”。主实现 Phase 负责交付能力，Gate/Release Phase 负责证明能力；一个要求只有在对应验证全部通过后才算满足。

| Master Spec 要求 | 主实现 Phase | Gate / 最终验证 |
|---|---|---|
| FR-01 启动与恢复 | 0～2、6、9～12 | 13、39 |
| FR-02 常驻游戏壳 | 5、8、12 | 13、39 |
| FR-03 地图与传送 | 4、6～8 | 13、39 |
| FR-04 玩家移动与复活 | 14、16 | 21、39 |
| FR-05 属性与成长 | 15、36～38 | 21、31、39 |
| FR-06 战斗 | 14、17、18、33 | 21、39 |
| FR-07 技能 | 19、36～38 | 21、39 |
| FR-08 敌人和生成 | 20、32、36～38 | 21、39 |
| FR-09 物品与背包 | 22、26 | 31、39 |
| FR-10 装备与强化 | 23、25 | 31、39 |
| FR-11 奖励和掉落 | 24、26、32 | 31、39 |
| FR-12 世界状态、NPC 与对话 | 27、28 | 31、39 |
| FR-13 任务 | 27、29、36～38 | 31、39 |
| FR-14 商店与经济 | 24、30 | 31、39 |
| FR-15 Boss 与副本 | 32～34、36～38 | 39 |
| FR-16 自动战斗 | 35 | 39 |
| FR-17 保存与加载 | 9～11 | 13、39 |
| FR-18 设置与音频 | 3、12 | 13、39 |
| 产品节奏：主线 4～6h、全清 6～8h、强制刷怪 ≤15min | 15、29、36～38 | 38、39 |
| NFR-01 确定性与可诊断性 | 0～4、6、10、18、24、32、35 | 13、21、31、39 |
| NFR-02 性能 | 0、2、6、18、32、35 | 13、21、31、39 |
| NFR-03 稳定性 | 1、2、5、6、10、32 | 13、21、31、39 |
| NFR-04 日志质量 | 1、2；之后每个 Phase | 13、21、31、39 |
| NFR-05 离线与安全边界 | 0～4、9～11、39 | 13、39 |
| NFR-06 兼容与可回滚 | 3、4、6、9～11；之后每个迁移 Phase | 13、21、31、39 |

追踪规则：Phase Spec 必须从上表引用自己覆盖的 FR/NFR 编号；Acceptance Report 必须回填证据文件或命令。若 Phase 改变了要求或归属，先更新 Master Spec 和本表，再改实现计划。

## 9. 测试覆盖图

```text
CODE / DATA PATHS                               USER FLOWS
[Resource] fresh import + manifest              [E2E] New game
  ├─ script parse                                 ├─ create canonical V2
  ├─ scene load/instance                          ├─ enter start map
  ├─ dynamic icons/audio                          └─ accept first quest
  └─ export PCK

[Map transaction]                              [E2E] Travel + resume
  ├─ validate IDs                                 ├─ portal request
  ├─ load candidate                               ├─ map commit
  ├─ bind/spawn                                    ├─ save
  ├─ commit or rollback                            ├─ exit process
  └─ deadline                                     └─ load same state

[Combat]                                       [E2E] RPG loop
  ├─ intent                                        ├─ fight
  ├─ skill/cooldown/MP                              ├─ loot
  ├─ hit/damage/effect                              ├─ equip/enhance
  ├─ death ledger                                   ├─ quest turn-in
  └─ reward transaction                             └─ shop/map unlock

[Encounter]                                    [E2E] Endgame
  ├─ spawn/run scope                                ├─ Boss phases
  ├─ victory/failure/reset                           ├─ dungeon retry
  ├─ first-clear ledger                              └─ final quest ending
  └─ cleanup

[Automation]                                   [Soak] Stability
  ├─ target/approach/attack                          ├─ 1,000 transfers
  ├─ recover/loot/unstuck                            ├─ 100 restarts
  └─ stop/manual restore                             └─ 10,000 combats
```

## 10. Phase 级并行策略

多数基础 Phase 改动共享 `project.godot`、GameRoot 或核心 schema，应顺序执行。可并行的工作必须先冻结接口和内容 pack 边界。

| Lane | 可并行窗口 | 主要目录 | 依赖 |
|---|---|---|---|
| A 核心运行时 | 5→13、14→21 | `autoload/`, `src/core/`, `src/game/`, `src/combat/` | Registry 合同 |
| B 测试与验证 | 每个 Phase 同步推进 | `tests/` | 对应接口已冻结 |
| C 内容迁移 | 7～8、36～38 | `content/v1/`, 单独 map scene | schema/manifest 已冻结 |
| D UI presenter | 12、22～30 | `src/ui/` | 对应领域 query/command 已冻结 |

执行顺序：

1. Phase 0～4 顺序执行。
2. 每个领域 Phase 中，测试夹具和数据 pack 可在接口冻结后与实现并行；合并前跑整套门禁。
3. Content Wave 可按章节 pack 分 worktree，但共享 manifest、任务前置图和经济曲线由一条整合 lane 维护。
4. 两条 lane 若都修改 `project.godot`、同一 `.tscn` 或同一 JSON pack，必须改为顺序执行。

## 11. 每个 Phase 的文档与提交节奏

```text
1. phase-XX-spec.md         可观察行为、范围、验收
2. phase-XX-design.md       数据、API、状态机、迁移、风险
3. phase-XX-plan.md         测试先行的文件级任务
4. red test commit          仅在计划明确要求时保留
5. small implementation commits
6. phase-XX-acceptance.md   命令、证据、差异、回滚点
7. Gate phase creates tag
```

实现提交只暂存精确文件，禁止 `git add -A`。导入 sidecar 的机械更新、内容数据、逻辑代码和场景调整必须分开提交，便于审查和回滚。

## 12. 风险登记

| 风险 | 概率/影响 | 最早处理 Phase | 缓解 |
|---|---|---:|---|
| 数千 `.import` 差异污染提交 | 高/高 | 0～1 | 固定引擎、LF、专门机械提交、二次导入 clean |
| GameRoot 与旧 `change_scene()` 冲突 | 高/高 | 5～8 | pilot、事务切图、静态禁令 |
| V2 冻结中文名/路径 | 高/高 | 4、9 | Registry/alias 先行 |
| 重复 apply 造成装备属性叠加 | 高/高 | 9、23 | 基值重算、幂等测试 |
| 任务/奖励重复 | 高/高 | 24、29 | operation/event ledger、原子事务 |
| 无限刷新导致经济崩溃 | 高/高 | 20、24、26 | 单奖励源、经济模拟、收益预算 |
| 自动战斗卡死或越界 | 中/高 | 35 | zone、deadline、unstuck、公共 Intent |
| 内容达数但不可通关 | 高/高 | 36～38 | 累计波次 Gate、任务/地图图、固定种子通关 |
| 编辑器可跑但导出缺 JSON/动态资源 | 中/高 | 1、39 | manifest 在 PCK 内复跑 |
| 版权素材被误公开 | 中/高 | 39 | 本地构建、无公开 Release、文档警示 |

## 13. NOT in scope

本路线图明确不包含 Master Spec 第 7 节列出的多职业、联网、元神、家园、军团、复杂装备、失败强化、每日活动、离线收益、自动 Boss/副本、Godot 4 和公开素材包。若要增加，必须创建 V2 产品 Spec，不能插入当前 Phase 偷渡。

## 14. 工程审查摘要

### What already exists

- `autoload/GameState.gd`、`SaveManager.gd`、`SceneManager.gd` 已提供 V1 规范化、备份和场景恢复脚手架，Phase 9～11 在其上升级。
- 4 个 SceneTree 测试已覆盖少量状态、存档、恢复和资源链，Phase 2 迁入统一 runner。
- 现有 Player、Snake、邓茂、地图、背包和商店表现可作为 adapter/pilot，不按现状复制扩张。
- 现有 22 个物品和 3 个技能需要迁移、筛选和重平衡，不等于 22/3 个已完成 V1 内容。

### Architecture findings folded into this roadmap

1. Resource closure 在完整测试体系前。
2. ContentRegistry/稳定 ID 在地图注册和 V2 存档前。
3. GameRoot 拆成组合根、加载事务、pilot、批迁。
4. V2 拆成 DTO、文件事务、迁移切换。
5. UI 先壳后 presenter。
6. 战斗增加 Intent、Target、Hit、Effect 中间契约。
7. 强化前必须有 ItemInstance 和经济事务。
8. WorldFlags 在 Quest 前。
9. Boss/副本前必须有 EncounterDirector。
10. 内容波按可通关累计配额，而非文件数量。

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|---|---|---|---:|---|---|
| CEO Review | `/plan-ceo-review` | 范围与产品策略 | 0 | NOT RUN | Master Spec 已固定单机 V1，不阻断规划 |
| Codex Review | `/codex review` | 独立第二意见 | 0 | NOT RUN | 未运行外部模型审查 |
| Eng Review | `/plan-eng-review` | 架构、测试、性能 | 1 | CLEAR WITH FOLLOW-UP | 10 个依赖/边界问题已折入 Phase 0～39 |
| Design Review | `/plan-design-review` | UI/UX | 0 | DEFERRED | 在 Phase 12 常驻 UI 壳前运行 |
| DX Review | `/plan-devex-review` | 开发体验 | 0 | DEFERRED | Phase 2 runner 完成后运行 |

**VERDICT:** V1 范围、架构依赖和 40-Phase 顺序已可进入 Phase 0 详细 Spec/Design；实现前仍需逐 Phase 生成文件级计划。

NO UNRESOLVED DECISIONS
