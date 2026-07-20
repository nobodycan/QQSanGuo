# QQSanGuo V1 Architecture Design

**状态：** 已确认总体方向，供 Phase Design 细化\
**对应 Spec：** `docs/superpowers/specs/2026-07-20-qqsanguo-v1-master-spec.md`\
**引擎约束：** Godot 3.5.3，不使用 Godot 4 API

---

## 1. 架构结论

采用“持久游戏壳 + 六个跨场景 Autoload + 领域组件 + 数据注册表 + 渐进绞杀”方案。

核心判断：

- 保留现有素材、动画、地图场景和 UI 视觉。
- 新逻辑进入清晰的领域模块，不继续扩张 `Steve.gd`、`Snake.gd`、地图脚本或 UI 脚本。
- 不做一次性大重写；每个旧入口先适配到新接口，再在对应 Gate 后删除。
- `GameState` 是规范存档模型，不是承载全部业务规则的 God Object。
- `EventBus` 只传跨 SceneTree 分支事件；同一场景内部优先用局部信号和直接依赖注入。
- 所有内容身份使用稳定 ASCII ID；中文名称只用于显示。

Godot 官方的场景组织建议是以一个 Main 入口持有 World 和 GUI，并在换关时只替换 World 子节点；同时，修改其他系统数据的逻辑应使用普通脚本/节点，而不是继续增加 Autoload。该模式与本项目的持久 `GameRoot` 一致：

- [Godot 3.5 Scene organization](https://docs.godotengine.org/en/3.5/tutorials/best_practices/scene_organization.html)
- [Godot 3.5 Autoloads versus regular nodes](https://docs.godotengine.org/zh-cn/3.5/tutorials/best_practices/autoloads_versus_internal_nodes.html)

## 2. 运行时总图

```text
root
├── GameState             Autoload：规范快照与 schema
├── SaveManager           Autoload：双世代文件事务、恢复、迁移入口
├── SceneManager          Autoload：地图加载事务与回滚
├── ContentRegistry       Autoload：稳定 ID、数据和受信任资源映射
├── EventBus              Autoload：跨分支领域事件
├── AudioManager          Autoload：跨地图音乐和全局 UI 音效
└── GameRoot              唯一主场景，整个游戏会话不释放
    ├── Services
    │   ├── WorldState
    │   ├── QuestService
    │   ├── EconomyService
    │   ├── EncounterDirector
    │   └── AutoCombatController
    ├── WorldRoot
    │   └── CurrentMap    仅替换这一支
    ├── PlayerRoot
    │   └── Player
    ├── RuntimeActors
    ├── UIRoot
    ├── TransitionRoot
    └── DebugOverlay
```

### 2.1 生命周期

| 节点/服务 | 生命周期 | 所有者 | 可否跨地图保留 |
|---|---|---|---|
| 六个 Autoload | 进程 | SceneTree root | 是 |
| GameRoot | 游戏会话 | SceneTree current scene | 是 |
| Services | 游戏会话 | GameRoot | 是 |
| Player | 新档/读档后到返回主菜单 | PlayerRoot | 是 |
| UIRoot | 游戏会话 | GameRoot | 是 |
| CurrentMap | 单次地图停留 | WorldRoot | 否 |
| 地图敌人/掉落 | 单次地图或 Encounter | CurrentMap/RuntimeActors | 否 |
| Boss/副本 Encounter | 遭遇 | EncounterDirector | 否 |

## 3. 六个 Autoload 的边界

### 3.1 GameState

职责：

- 创建 V2 默认快照。
- 规范化和验证 JSON 基础类型。
- 组合各领域服务导出的状态段。
- 按固定顺序把状态段导入领域服务。
- 生成可比较的 canonical JSON 和状态 hash。

禁止：

- 查找任意地图节点路径。
- 计算伤害、任务奖励、强化或商店价格。
- 保存 Texture、Node、Resource、NodePath 或 PackedScene。
- 直接刷新 UI。

### 3.2 SaveManager

职责：

- A/B 双世代选择、临时文件写入、刷新、回读验证和崩溃安全提交。
- 区分 missing、corrupt、unsupported、migration、write、apply 等错误。
- 调用明确的 V1→V2 迁移器。
- 返回结构化结果，不在内部切地图或改业务状态。

### 3.3 SceneManager

职责：

- 接收调用方的 `map_id + spawn_id`，由 SceneManager 生成并拥有唯一 `transition_token`，通过 accepted/terminal 结构化结果返回。
- 通过 `ContentRegistry` 获取受信任 PackedScene 路径。
- 加载、实例化、验证地图契约并事务式替换 `WorldRoot` 子节点。
- 协调淡出、加载进度、玩家定位、淡入、输入锁和失败回滚。

禁止：

- 允许调用方传任意 `res://` 路径。
- 继续调用 `SceneTree.change_scene()` 替换整个 GameRoot。
- 无期限等待 `_ready()` 或 `current_scene`。

Godot 3.5 提供 `ResourceLoader.exists/load/load_interactive` 和 `PackedScene.instance()`；地图切换使用这些内建能力，不自造资源格式：

- [ResourceLoader 3.5](https://docs.godotengine.org/en/3.5/classes/class_resourceloader.html)
- [PackedScene 3.5](https://docs.godotengine.org/en/3.5/classes/class_packedscene.html)

### 3.4 ContentRegistry

职责：

- 按 manifest 加载 JSON 内容包。
- 校验 ID、schema、枚举、范围、跨表引用、任务 DAG 和地图连通性。
- 提供只读查询：`get_item(id)`、`get_map(id)` 等。
- 将 legacy 中文名/路径映射到稳定 ID。
- 生成内容计数和引用闭包报告。

禁止：

- 修改玩家状态。
- 根据显示名做业务查询。
- 在发布包中扫描未知目录并动态执行内容。

### 3.5 EventBus

职责：只声明和转发跨分支事件，例如：

```text
map_transition_started/completed/failed
player_stats_changed
inventory_changed
equipment_changed
wallet_changed
combat_resolved
actor_defeated
item_acquired
quest_state_changed
world_flag_changed
encounter_started/completed/failed
save_completed/failed
runtime_error_reported
```

规则：

- 事件名使用已发生的过去式语义。
- 每个可重试副作用带唯一 `operation_id` 或 `event_id`。
- 局部 Actor 组件不得为方便而把所有调用绕到 EventBus。
- UI 只订阅事件并查询 presenter，不在事件回调内实现业务规则。

### 3.6 AudioManager

职责：

- 地图 BGM 切换/淡入淡出。
- 全局 UI 音效。
- 必要的短音效播放器池。
- 读取独立设置中的总音量、音乐和音效音量。

角色攻击、受击和局部环境音优先由所属场景持有；AudioManager 不是全部音效的全局路由器。

### 3.7 结构化错误报告

所有保存、加载、传送、奖励和 Encounter 失败都发出同一机器 schema；中文 message 只是附加上下文，不能替代字段：

```json
{
  "schema": "runtime_error.v1",
  "error_code": "MAP_SCENE_MISSING",
  "operation_id": "transition_000001",
  "map_id": "map_bajun",
  "content_id": null,
  "frame": 1200,
  "recent_events": [
    {"event_id": "event_000031", "type": "map_transition_started", "frame": 1194}
  ],
  "message": "地图资源不存在"
}
```

- `error_code/schema/operation_id/event_id/type` 使用 ASCII；即使没有地图或内容上下文，`map_id/content_id` 也必须显式为 `null`。
- `recent_events` 是每个 operation 的有界 ring buffer，最多 32 项，按 frame/event ID 稳定排序；不得把任意 Node、Resource 或存档原文塞入日志。
- 每个 operation 只发一个 terminal success/failure；错误报告必须先落到捕获器，再允许 UI 展示。
- 测试/发布日志分类器把缺字段、未知 error code、超过 32 项或 operation 没有唯一终态视为失败。

## 4. 目标目录结构

不移动现有大批素材；新逻辑和新内容进入独立目录，旧目录按 Phase 逐步退役。

```text
autoload/
├── GameState.gd
├── SaveManager.gd
├── SceneManager.gd
├── ContentRegistry.gd
├── EventBus.gd
└── AudioManager.gd

src/
├── core/                 Result、ID、事件、验证、时钟/RNG 接口
├── game/                 GameRoot 与组合根
├── player/               Intent、Controller、Stats、Vitals、Skills
├── combat/               Action、Target、Hitbox、Damage、Effect
├── inventory/            Item、Inventory、Equipment、Enhancement
├── world/                Map、Portal、WorldState、NPC、Dialogue
├── quest/                QuestDefinition、QuestService、objectives
├── economy/              Wallet、Transaction、Shop、Reward、Loot
├── encounter/            Encounter、Boss、Dungeon、Spawner
├── automation/           AutoCombatController
└── ui/                   presenter 与常驻 UI adapter

content/v1/
├── manifest.json
├── maps/
├── items/
├── skills/
├── enemies/
├── loot_tables/
├── npcs/
├── dialogues/
├── quests/
├── shops/
└── dungeons/

tests/
├── unit/
├── integration/
├── scenes/
├── e2e/
├── soak/
├── resource/
├── fixtures/
└── tools/
```

新路径全部使用小写 ASCII `snake_case`。现有中文素材路径可以保留，但必须由内容表映射，业务代码不得继续拼接路径。

## 5. 内容数据设计

### 5.1 Manifest

`content/v1/manifest.json` 是唯一加载入口，包含：

```json
{
  "schema_version": 1,
  "content_revision": "v1.0.0",
  "packs": {
    "maps": ["maps/chapter_01.json", "maps/chapter_02.json", "maps/chapter_03.json"],
    "items": ["items/tier_01.json", "items/tier_02.json", "items/tier_03.json"],
    "skills": ["skills/swordsman.json"]
  },
  "expected_counts": {
    "map": {"total": 8, "normal": 6, "dungeon": 2},
    "quest": {
      "total": 24,
      "main": 18,
      "side": 6,
      "per_chapter": [
        {"chapter": 1, "main": 6, "side": 2},
        {"chapter": 2, "main": 6, "side": 2},
        {"chapter": 3, "main": 6, "side": 2}
      ]
    },
    "enemy": {"ordinary": 10},
    "boss": {"total": 4, "main_map": 2, "dungeon": 2},
    "skill": {"total": 8, "zero_cost_basic": 1, "active": 7},
    "gear": {"total": 30, "slots": 10, "tiers": 3, "per_slot_tier": 1},
    "other_item": {"total": 12, "consumable": 5, "enhance_material": 3, "quest": 4},
    "service": {"total": 3, "general_shop": 1, "equipment_shop": 1, "blacksmith": 1}
  }
}
```

实际 manifest 还需列出其余分类；上例展示格式，不作为删减许可。
`map.total=8` 统计全部可玩地图，`map.dungeon=2` 是其中带副本定义的子集，不额外增加到 10 张地图；Registry 必须验证两个副本各引用一个已登记的 `map_id`。Validator 同时检查总数、子类型和交叉表，不能用 24 个支线、8 个主动技能、同一槽位的 30 件装备或重复服务类型满足总量。

### 5.2 ID 规则

- 正则：`^[a-z][a-z0-9_]{2,63}$`。
- 分类前缀：`map_`、`spawn_`、`portal_`、`item_`、`skill_`、`enemy_`、`boss_`、`loot_`、`npc_`、`dialogue_`、`quest_`、`shop_`、`dungeon_`。
- ID 一经进入已发布存档不得复用或改变语义。
- 重命名通过 alias 表迁移，旧 ID 至少保留到下一个大版本。
- 中文名、描述和资源路径可以改变，不影响身份。

### 5.3 数据与表现分离

| 内容 | JSON 定义 | `.tscn` / `.tres` 表现 |
|---|---|---|
| 地图 | ID、scene、出生点、传送边、等级、BGM、自动战斗区域 | TileMap、碰撞、装饰、锚点 |
| 技能 | ID、`unlock_level`、消耗、冷却、倍率、范围、段数、效果、命中时点 | 动画、特效、音效适配 |
| 敌人 | 属性、AI profile、奖励、掉落表、scene | Sprite、Animation、碰撞 |
| 物品 | 类型、槽位、等级、属性、价格、icon path | 可选拾取/装备表现 |
| Boss | 阶段和技能调度参数、奖励、scene | Boss 场景和预警表现 |
| 任务 | 前置、目标、奖励、解锁、对话引用 | 任务 UI 只做展示 |

复杂的编辑器可视资源可使用 `.tres`；大量可审查表格优先 JSON。所有 JSON 必须在 Windows 导出 preset 中显式包含，并在导出 PCK 内再次通过 manifest 校验。

### 5.4 运行时信任与离线边界

- 存档、设置和内容 JSON 都按不可信数据处理；只接受 JSON 基础类型，经 schema/范围/枚举校验后才能进入 staged state。
- 存档只携带稳定 ID；只有 ContentRegistry 能把已登记 ID 映射到固定 `res://` 资源，调用方不得把存档字符串直接传给 `load()`。
- Release 运行路径禁止 HTTP/WebSocket/TCP/UDP、下载、`OS.execute/shell_open`、动态脚本解析/执行和可执行对象反序列化；编辑器工具若确有需要必须在不导出的 allowlist 中。
- 进度与设置写入只能经 SaveManager/Settings adapter 落到规范化后的 `user://`；运行时不得写 `res://`、绝对路径、Release 目录或由 JSON 指定的路径。
- Phase 3 静态门禁扫描源码和导出路径，Phase 39 再以 outbound-deny/连接监控和文件系统差分验证“零联网尝试、零越界写入”。

### 5.5 语义内容门禁

- 技能 `unlock_level` 范围为 1～30，最终按稳定 ID 排序后的计划必须精确为 `[1,3,6,10,14,18,23,28]`；SkillBook 在等级不足时不得解锁、装备或施放。
- Validator 为每个普通敌人生成不含名称/贴图/scene 的 `encounter_signature`，其输入至少包含规范化 stats、loot、telegraph profile 和 AI role。10 个普通敌人的 signature 必须两两不同；完全相同而只换表现的定义被拒绝。
- 每个敌人还必须声明一个 `primary_encounter_difference`，Phase 38 生成 10 行差异矩阵，并以固定种子行为 trace 证明声明不是空标签。
- 推进关键装备显式标记 `progression_critical=true`、`required_before_quest_id` 和 `guaranteed_source_ids`。任务奖励、固定商店库存或首通奖励可作为保证来源；概率掉落不能。内容图验证至少一个来源在首次门槛前可达。
- 随机掉落可补充金币、材料或替代装备，但不得成为主线解锁、Boss 数值门槛或必需任务的唯一来源。

## 6. 地图切换事务

### 6.1 状态机

```text
IDLE
  │ request(map_id, spawn_id) → accepted(token)
  v
VALIDATING ──invalid──> FAILED
  v
FADING_OUT
  v
LOADING ──timeout/load error──> ROLLING_BACK
  v
INSTANTIATING ──contract error──> ROLLING_BACK
  v
BINDING
  v
POSITIONING_PLAYER
  v
COMMITTING ── replace old CurrentMap only here
  v
FADING_IN
  v
IDLE

ROLLING_BACK → restore old world/input/overlay → FAILED → IDLE
```

### 6.2 事务规则

1. 每次请求生成唯一 token。
2. `IDLE` 以外的重复 portal 触发不得启动第二个事务。
3. 新地图加载和契约校验完成前，旧地图保持可回滚。
4. 地图契约至少要求合法 root、声明的 spawn、地图 ID 一致、无内嵌 Player/UI。
5. 只有 token 仍为当前请求时才允许 commit，防止旧异步结果覆盖新请求。
6. 成功后释放旧地图；失败后释放候选地图。
7. 300 帧或 5 秒没有终态即超时失败。
8. 终态后一个物理帧内解除输入锁和传送去抖。

### 6.3 地图定义

```json
{
  "map_id": "map_bajun",
  "display_name": "巴郡",
  "scene_path": "res://Scene/bajun.tscn",
  "recommended_level": [1, 10],
  "default_spawn_id": "spawn_bajun_center",
  "spawn_ids": ["spawn_bajun_center", "spawn_bajun_west_gate"],
  "portal_ids": ["portal_bajun_to_west"],
  "auto_combat_zone_ids": [],
  "bgm_id": "bgm_bajun"
}
```

## 7. 规范运行时状态与存档 V2

### 7.1 状态所有权

```text
PlayerStats       owns level/xp/base and derived stats
Vitals            owns current hp/mp and alive state
Inventory         owns slots, stacks and equipment instances
Equipment         owns equipped instance IDs
SkillBook         owns unlocked/equipped skill IDs
Wallet            owns coin
WorldState        owns flags, map unlocks, checkpoints, boss/dungeon completion and first-clear ledger
QuestService      owns quest states/objective progress/reward ledger

GameState asks each known owner to export/import its section.
UI owns none of the above.
EncounterDirector owns only the current transient run and exports no save section;
it submits idempotent completion/reward commands to WorldState and EconomyTransaction.
```

每个状态 owner 实现同一两阶段协议：

这里的 GameStateCoordinator 是 `GameState` Autoload 内部的协调职责，不是第七个 Autoload 或第二份状态存储。

```text
export_state() -> JSON-safe Dictionary
prepare_import(section, ImportContext) -> ImportResult(prepared_state | error)
commit_import(prepared_state) -> void
after_import(operation_id) -> void
```

- `prepare_import` 只解析、规范化、解析稳定 ID、计算派生值并创建隔离的完整 `prepared_state`，不得修改 canonical state、SceneTree、Timer、信号或 UI。
- GameStateCoordinator 按固定 owner 顺序收集所有 prepared state，并同时保留当前 owner state 引用和 canonical hash；任一 prepare 失败即丢弃全部 staged data。
- `commit_import` 只交换已验证的内存状态，不做文件 I/O、资源加载、`yield`、外部回调或可失败计算；整个 commit 段暂停领域事件分发，并在同一帧完成。
- 全部 owner 和候选 World 提交后才调用 `after_import`；它只做表现重绑和发送一次 `state_restored`，不得再修改 canonical state 或执行可失败业务计算；UI 只响应这个终态事件。
- 防御性回滚保留提交前状态引用；若内部不变量在开发构建中失败，按相反 owner 顺序恢复旧引用、恢复旧 World，并将该次加载标为失败。发布构建不允许依赖部分回滚掩盖 prepare 漏检。

### 7.2 V2 顶层 schema

```json
{
  "metadata": {
    "schema_version": 2,
    "content_revision": "v1.0.0",
    "section_versions": {
      "player": 1,
      "wallet": 1,
      "inventory": 1,
      "equipment": 1,
      "skills": 1,
      "quests": 1,
      "world": 1
    },
    "save_id": "slot_01",
    "generation": 0,
    "operation_id": "save_00000001",
    "created_unix": 0,
    "updated_unix": 0,
    "playtime_seconds": 0,
    "checksum_algorithm": "sha256",
    "checksum": ""
  },
  "location": {
    "map_id": "map_bajun",
    "spawn_id": "spawn_bajun_center",
    "fallback_position": {"x": 0.0, "y": 0.0}
  },
  "player": {
    "level": 1,
    "xp": 0,
    "hp": 1000,
    "mp": 1000
  },
  "wallet": {"coin": 0},
  "inventory": {
    "slots": [],
    "equipment_instances": {}
  },
  "equipment": {"slots": {}},
  "skills": {"unlocked": [], "equipped": []},
  "quests": {"states": {}, "reward_ledger": []},
  "world": {
    "flags": [],
    "unlocked_map_ids": [],
    "defeated_boss_ids": [],
    "dungeons": {}
  },
  "legacy": {}
}
```

Phase 9 只冻结顶层 envelope、`section_versions`、空/default section、JSON-safe/稳定 ID 约束和两阶段 owner 协议；尚未实现领域的 section 使用 version 0 空段。Player、Skill、Inventory、Equipment、Wallet、World、Quest 的内部字段分别由其所属 Phase 冻结并提供 `0→1` 有界迁移，不能让 Phase 9 反向依赖尚未完成的领域实现。

顶层 `schema_version=2` 只在 envelope 不兼容时升级；领域内部兼容变化升级自己的 section version。运行时遇到高于支持版本的 section 必须返回 `UNSUPPORTED_SECTION_VERSION` 并保留原文件，不能忽略未知字段后覆盖。以下跨领域决定不可逆转：稳定 ID、装备实例身份、持久奖励 ledger、schema/content/section 分版本、设置独立文件、禁止节点路径身份。

### 7.3 装备实例

```json
{
  "instance_id": "gear_00000001",
  "item_id": "item_sword_tier_01",
  "enhance_level": 4
}
```

实例 ID 在创建时生成并在其生命周期内不变；同名装备可以有不同强化等级。所有派生属性从 `ItemDefinition + enhance_level` 重算，不保存已加总结果作为第二真相源。

### 7.4 设置文件

音量、显示和按键使用 `user://settings.cfg` 的 `ConfigFile`，不进入进度存档。Godot 官方保存指南也建议用户配置使用 `ConfigFile`：

- [Godot 3.5 Saving games](https://docs.godotengine.org/en/3.5/tutorials/io/saving_games.html)

### 7.5 崩溃安全的 A/B 双世代写入

```text
capture owners
  → normalize V2
  → scan/validate save_a.json + save_b.json
  → active = highest valid generation; target = the other slot
  → generation = active.generation + 1
  → canonical JSON + checksum
  → write save_<target>.tmp
  → flush + close
  → read/parse/normalize/check checksum
  → Directory.rename(temp, inactive save_<target>.json)
  → read/validate final target
  → emit one terminal result
```

逻辑上只有一个存档槽，物理上始终保留两个世代候选。加载器不读取可变的“当前指针”，而是同时校验 A/B 并选择 `generation` 最大的有效文件；相同 generation 视为冲突并进入可诊断恢复，不按时间戳猜测。

Godot 3.5 文档说明 `Directory.rename()` 会覆盖目标，但 3.5.3-stable 的 Windows 实现会先删除已存在目标，再调用 `_wrename`，因此覆盖式 rename 本身不能视为原子替换。本设计只允许 rename 覆盖**非活动世代**：即使进程在删除目标与重命名之间退出，另一文件仍是最后已提交世代。

- [Directory 3.5](https://docs.godotengine.org/en/3.5/classes/class_directory.html)
- [Godot 3.5.3 Windows `DirAccessWindows::rename` 源码](https://github.com/godotengine/godot/blob/3.5.3-stable/drivers/windows/dir_access_windows.cpp)

Checksum 规则固定如下：把 `metadata.checksum` 置空，递归按 ASCII key 排序、数组保持语义顺序，以无多余空白的 UTF-8 canonical JSON 序列化，再计算 SHA-256 十六进制；写入 checksum 后生成最终文件。Checksum 只检测损坏，不提供防篡改或反作弊能力；加载后仍必须执行 schema、范围和 ContentRegistry 信任边界校验。

中断不变量：写/校验 temp 失败时活动世代不变；替换非活动世代期间失败时活动世代不变；最终文件完整但调用方未收到结果时，下次加载会按更高 generation 选择它。任何清理只能删除 `.tmp` 或 generation 更低且已有另一有效世代的文件，不得先删除当前最高有效世代。

### 7.6 加载事务

1. 同时读取 `save_a.json`、`save_b.json`，分别完成 checksum/schema/content 校验，并选择 generation 最高的有效候选；不存在有效 V2 时才进入 legacy V1 恢复/迁移路径。
2. 解析、schema、范围、内容引用、checksum 全部成功才成为候选。
3. V1 候选先迁移到内存 V2；原文件保留。
4. SceneManager 加载并验证目标 World 候选，但保留旧 World；任何 owner 尚未修改。
5. GameStateCoordinator 对每个 owner 调用 `prepare_import`，收集全部 prepared state；任一步失败就释放候选 World/staged data，并保持当前规范状态 hash 不变。
6. 输入与领域事件分发锁定后，在一个不 `yield` 的临界段按固定顺序交换 owner state 与 CurrentMap；该段只做已验证引用交换。
7. 解除领域事件抑制，按固定顺序执行 `after_import`，重绑表现并只发一个终态结果；之后释放旧 World。
8. 防御性不变量失败恢复提交前 owner 引用和旧 World；不得把部分导入后的状态继续运行或写回磁盘。
9. 从较低有效世代恢复或发生 alias 替换时，向玩家显示恢复摘要。

## 8. V1→V2 迁移

### 8.1 映射

| V1 | V2 |
|---|---|
| `map_path` | alias → `map_id` |
| 中文物品名 | alias → `item_id` |
| `equipment[slot] = name` | 创建 `equipment_instance`，强化默认为 0 |
| `skills.known/equipped` 中文或旧键 | alias → `skill_id` |
| `player.attributes` 已加总值 | 迁入基础兼容值并在 Phase 15 后重算 |
| `juntuan` | `legacy.archived_juntuan`，不进入 wallet |
| 缺失任务/世界字段 | 使用空默认值和初始地图解锁 |

### 8.2 未知值策略

- 未知地图：加载失败并保留当前状态，迁移报告给出路径。
- 未知普通物品：进入 `legacy.unresolved_items`，不静默删除。
- 未知已装备物品：取消装备并进入 unresolved；不应用属性。
- 未知技能：进入 unresolved；不占用技能栏。
- 每次迁移保存 alias 命中和 unresolved 清单。
- 迁移函数必须幂等；再次输入已迁移 V2 不产生变化。
- V1 原文件和其旧备份只读保留；候选完成 schema/content/World/owner prepare 后，首次规范 V2 写入 `save_a.json` generation 0。失败不得创建半个 V2 世代；再次启动优先读取有效 A/B，不重复消费 V1。

## 9. 战斗架构

### 9.1 统一数据流

```text
ManualInput / AutoCombat
          │
          v
    PlayerIntent
          │ validate movement/skill request
          v
    SkillController ── cooldown / MP / target / state
          │
          v
      CombatAction
          │ animation hit marker or Hitbox overlap
          v
    CombatExecutor
          │
          v
  DamageEffectPipeline
    ├ attacker snapshot
    ├ defender snapshot
    ├ seeded RNG
    ├ damage/effect rules
    └ CombatResult
          │
          v
       Vitals
          │
          ├── combat_resolved
          └── actor_defeated ── Reward/Quest/Encounter
```

### 9.2 规则

- `CombatAction` 是不可变请求，包含 action ID、source actor ID、target actor ID、skill ID、命中序号和种子上下文。
- `DamageEffectPipeline` 是纯逻辑；不播放动画、不查 UI、不发金币。
- `Vitals` 是唯一 HP/MP 写入口；HP clamp 到 `[0, max_hp]`，MP clamp 到 `[0, max_mp]`。
- 伤害、状态、死亡分别有结果对象；失败也返回结果。
- `actor_defeated` 带唯一 defeat event ID，Reward、Quest、Encounter 各自用 ledger 防重复。
- 玩家和敌人通过 `Faction/Targetable` 发现关系，不依赖节点必须叫 `Steve` 或 `Sprite`。
- SkillDefinition 的 `unlock_level` 是施放/装备前置；等级提升跨过门槛时由 SkillBook 幂等解锁一次。V1 八项门槛固定为 1、3、6、10、14、18、23、28。

### 9.3 状态效果

V1 引擎支持：即时恢复、持续恢复、持续伤害、移动速度修正、减速和短时控制。每个效果定义持续时间、tick、叠层上限、刷新规则、互斥组和来源。实际 8 个技能只使用内容表声明的子集。

## 10. 物品、装备、经济与奖励

### 10.1 Inventory Command

所有变更通过命令返回结构化结果：

```text
add_stack(item_id, quantity)
add_equipment(instance)
remove_stack(item_id, quantity)
move_slot(from, to)
consume(item_id, quantity)
equip(instance_id, slot_id)
unequip(slot_id)
```

UI 不直接改 Dictionary。每条命令先模拟容量和不变量，成功后一次 commit 并发出一个事件。

### 10.2 EconomyTransaction

```text
validate all inputs
  ├ coin balance
  ├ material quantities
  ├ inventory capacity
  ├ item permissions
  ├ enhancement range
  └ operation_id not committed
          ↓
build delta
          ↓
commit wallet + inventory + equipment together
          ↓
append ledger + emit one result
```

失败时任何参与者的 canonical state hash 都不变。

### 10.3 强化

- 级别 0～10。
- 必定成功，不消耗随机数。
- 各级倍率 basis points 显式表为 `[10000,10400,10800,11200,11600,12000,12400,12800,13200,13600,14000]`，只作用于非负主属性；结果使用 `floor((base × bps + 5000) / 10000)` 做统一四舍五入。
- Phase 23 为每种主属性冻结 `power_score` 权重；每个槽位都必须满足 `下一档 +2 power_score ≤ 上一档 +10 power_score ≤ 下一档 +3 power_score`。
- 成本按装备档位和目标强化级别显式配置。
- 一件同档装备从 +0 到 +10 的总金币必须为基础买价的 1.90～2.10 倍，并使用 8～12 个同档材料。
- 标准全清路线扣除主线必需消费后，保证可完成 1～2 件终档 +10；全身 +10 是可选刷取目标。
- 装备卖价统一为 `max(1, floor(base_buy_price × 0.25))`，不计入强化投入。

### 10.4 掉落

- 掉落表项定义 `item_id`、概率或权重、数量范围、是否保证、任务条件。
- 任务关键物在激活任务时保证掉落。
- 背包满时拾取保持在世界中并给出提示；任务计数不静默吞掉。
- 敌人死亡只产生一个 Reward 请求；Spawner 不重复发奖。

## 11. 世界、对话和任务

### 11.1 WorldState

持有：

- `flags`
- `unlocked_map_ids`
- `defeated_boss_ids`
- `dungeon_state`
- `checkpoint_ids`
- 一次性世界奖励 ledger

WorldState 必须在 QuestService 前落地，因为任务前置、对话条件、地图解锁和一次性奖励都依赖它。

### 11.2 QuestDefinition

```json
{
  "quest_id": "quest_main_001",
  "type": "main",
  "chapter": 1,
  "prerequisite_ids": [],
  "accept_npc_id": "npc_guide_01",
  "turnin_npc_id": "npc_guide_01",
  "objective_ids": ["objective_main_001_talk"],
  "reward_id": "reward_quest_main_001",
  "unlock_ids": ["map_bajun"],
  "dialogue_ids": ["dialogue_main_001_accept", "dialogue_main_001_turnin"]
}
```

### 11.3 任务状态机

```text
locked
  │ prerequisites true
  v
available
  │ accept
  v
active
  │ every objective complete
  v
completable
  │ atomic turn-in + reward ledger
  v
completed
```

状态只单向前进。重复事件、重复对话、读档后旧回调或双击交付不得产生第二份奖励。

## 12. Encounter、Boss 与副本

### 12.1 EncounterDirector

负责一个作用域内的生成、开始、胜利、失败、重置、退出、清理和奖励。地图只声明 Encounter anchor，不自己写 Boss 业务。

```text
INACTIVE → PREPARING → ACTIVE → VICTORY
                     ├────────→ FAILURE
                     └────────→ ABORTED

VICTORY/FAILURE/ABORTED → CLEANING → INACTIVE
```

每个 Encounter 有唯一 run ID；所有 Actor、Timer、信号和掉落归属该 run，清理时按 run ID 回收。
EncounterDirector 不持有长期完成状态，也不把瞬时 run 写入存档。VICTORY 只以 `run_id + encounter_id` 向 WorldState 和 EconomyTransaction 提交一次幂等完成命令；是否首通及奖励是否已发由持久 ledger 决定。

### 12.2 Boss

```text
INTRO → PHASE_1 → TRANSITION → PHASE_2 → DEFEATED
   └──────── player leave/death ─────────→ RESETTING
```

Boss 技能必须有预警、可取消时点和阶段边界。阶段条件由生命百分比或明确事件驱动，不依赖动画帧猜测。EncounterDirector 只请求一次完成事务，WorldState/Reward ledger 保证奖励不会重复。

### 12.3 副本

- 每个副本 2～3 波普通敌人 + 1 个独立 Boss。
- 进入前验证地图解锁和状态；不设现实日期/每日次数。
- 玩家死亡按检查点策略重试。
- 主线外退回入口；不保存战斗中的瞬时敌人位置。
- 首通和重复奖励分别配置并分别去重。
- 副本基准时长按“输入解锁、Encounter 进入 ACTIVE”开始，到 VICTORY 终态结束；暂停菜单和系统阻塞 UI 停表，加载/淡入淡出不计，死亡后的重试游玩计入。推荐等级、标准装备、固定路线的 active time 必须各为 10～15 分钟。

## 13. 自动战斗

### 13.1 状态机

```text
OFF
 │ enable in allowed zone
 v
SEARCHING → APPROACHING → ATTACKING
   ↑             │             │
   ├── LOOTING ← defeated ─────┤
   ├── RECOVERING ← low hp/mp ─┤
   └── UNSTUCK ← no progress ──┘

any state → STOPPING(reason) → OFF
```

### 13.2 约束

- 只通过 `PlayerIntent`、SkillController、Inventory Command 调用公开接口。
- 目标仅来自当前 `auto_combat_zone_id`，按距离、稳定 actor ID 排序，固定种子下可复现。
- 目标销毁后 2 帧内清除；关闭后 1 帧内恢复手动控制。
- 不跨平台做通用寻路；地图作者提供活动边界和巡逻锚点。
- 2 秒没有位置进展进入 UNSTUCK；有限次脱困失败后停止并提示。
- stop reason 固定包括：manual、inventory_full、death、recovery_consumable_missing、quest_target_completed、zone_exit、activity_radius_exit、no_reachable_target、transition、pause_or_blocking_ui、boss_or_dungeon。
- 任一 stop reason 触发后 1 个物理帧内进入 OFF 并恢复手动控制；不得再创建新的 CombatAction、拾取或奖励事务，已提交命中只能按原 operation ID 完成一次。
- 不使用隐藏奖励折扣；在相同地图、装备、药品和固定种子下，依靠寻路与技能决策效率使每分钟金币 + 经验产出落在手动基准的 70%～90%。

## 14. UI 架构

UI 使用常驻壳和逐领域 presenter，不保存业务状态。

```text
Domain owner
   │ event says what changed
   v
EventBus
   │
Presenter queries canonical read model
   │
   v
View renders
   │ user command
   v
Presenter validates/dispatches domain command
```

Phase 12 只建立常驻壳、生命周期和 adapter；背包、装备、任务、商店 presenter 随对应领域 Phase 迁移。这样避免在领域 API 尚未稳定时一次性重写全部 UI。

## 15. 测试和自验证架构

### 15.1 层级

| 层级 | 目标 |
|---|---|
| Unit | schema、ID、伤害、成长、强化、任务状态机、经济事务 |
| Integration | GameState、SaveManager、SceneManager、Inventory、Quest、Encounter 协作 |
| Resource | 干净导入、所有定义/场景/脚本/动态资源闭包、导出 PCK |
| Scene | Player、敌人、Boss、8 地图、2 副本的实例化和有界运行 |
| E2E | 新档到任务/掉落/交易/强化/Boss/副本/保存重启 |
| Soak | 传送、存读档、自动战斗、遭遇重置、泄漏和性能 |

### 15.2 确定性功能进程协议

Godot 3.5.3 Windows 的功能测试规范命令使用 `--no-window` 和 `--fixed-fps 60`：

```powershell
$godot = Resolve-Path '.tools\godot-3.5.3\Godot_v3.5.3-stable_win64.exe'
& $godot --no-window --audio-driver Dummy --fixed-fps 60 --path $repo `
  -s res://tests/run_unit.gd
```

每个进程必须：

- 使用隔离的 `APPDATA/LOCALAPPDATA`，不触碰真实存档。
- Unit 30 秒、Integration 60 秒、Scene 120 秒、E2E 10 分钟外部超时。
- 显式 `quit(0)` 或 `quit(1)`，不依赖裸 `assert`。
- 最后输出唯一 `TEST_RESULT {json}`；缺失视为失败。
- 捕获完整 stdout/stderr；未允许的 `ERROR:` 即使退出 0 也失败。
- Windows 编排器按 UTF-8 解码原始输出；机器字段和错误码保持 ASCII，中文只作为附加上下文。
- 固定随机种子；业务测试路径不得自行 `randomize()`。
- 需要重置 Autoload 的测试各用独立 Godot 进程。

该 lane 验证确定性、状态和超时帧数，不能用于 NFR-02 的 median/1% low 或真实耗时结论，因为 `--fixed-fps` 不按真实墙钟同步。

### 15.3 性能 lane

- 使用 Phase 0 记录的最低配置、Windows Release 导出、800×600 固定窗口和固定场景/种子。
- 禁止 `--fixed-fps`、`--no-window` 和编辑器运行；关闭 VSync 后按真实墙钟采集渲染/物理帧时长，另做一次 VSync 开启的玩家体验复核。
- 预热 5 分钟后采集至少 30 分钟；报告 median FPS、1% low、最大帧、保存 p50/p95/max、加载/传送 p50/p95/max、CPU/GPU/RAM 和构建哈希。
- SceneManager 以结构化事件标记加载区间的开始/结束；只有该有界区间可从“非加载最大单帧 ≤250 ms”统计中排除，普通战斗/菜单/自动战斗尖峰不得伪装成加载。
- 性能 lane 只改变测量方式，不改变 AI、掉落、地图或内容参数；若场景和功能 lane 的 canonical 终态不一致，性能报告无效。
- 功能测试的通过不能替代性能通过，性能抖动也不能通过添加 `--fixed-fps` 隐藏。

### 15.4 无人值守流水线

```text
clean temporary checkout
  → verify Godot hash/version
  → no-window fresh import
  → static dependency/Autoload/change_scene scan
  → content schema/ref/count/graph validation
  → unit
  → integration
  → resource
  → scene
  → E2E with real process restart
  → deterministic fixed-seed soak + heartbeat
  → release export
  → run same manifest from PCK
  → real-clock performance lane on minimum target
  → 30-minute autonomous exported build
  → JUnit/JSON/log/evidence bundle
```

逻辑正确性不依赖截图；使用稳定 ID、事件 ledger、规范状态 hash、节点/Timer/信号计数、transition token 和帧 deadline 判定。截图只用于视觉回归和人工审美验收。

## 16. 绞杀旧系统

| 旧入口 | 新边界 | 允许存在到 | 删除条件 |
|---|---|---:|---|
| `SceneChange` / 各处 `change_scene()` | SceneManager + MapDefinition | Phase 13 Gate | 静态扫描仅剩 SceneManager 内建加载实现 |
| `SaveState` | SaveManager compatibility adapter | Phase 13 Gate | V1 fixture 全部迁移、UI 已改新入口 |
| `PlayerInventory` 属性字段 | PlayerStats/Vitals | Phase 21 Gate | 战斗/UI 不再写旧字段 |
| `PlayerInventory` 背包/装备 | Inventory/Equipment | Phase 31 Gate | 存档、UI、商店、掉落全走命令接口 |
| `SkillsFactory` / `SkillBase` | ContentRegistry + SkillController | Phase 21 Gate | 截至该 Gate 的全部启用技能和调用方已迁移，旧工厂调用为 0；后续技能只能走 Registry |
| `Snake.gd` 直接找 `Steve` | Targetable/CombatAction/EnemyBrain | Phase 21 Gate | 敌人最小夹具可独立实例化 |
| 地图内 Player/UI | GameRoot PlayerRoot/UIRoot | Phase 13 Gate | 截至该 Gate 的全部现有可玩地图已迁移；后续地图由 scene contract 阻断内嵌 Player/UI |
| `buy_and_sell.gd` 直接改金币/背包 | ShopPresenter + EconomyTransaction | Phase 31 Gate | 买卖/满包/余额/幂等测试通过 |

新代码静态门禁：只能引用六个目标 Autoload。旧依赖放在带到期 Phase 的 allowlist 中，清单只减不增；Phase 39 必须归零。
Phase 38 另做最终内容静态门：8 个启用技能全部来自 Registry，8 个启用地图全部通过无内嵌 Player/UI 的 scene contract；不得用早期 Gate 的较小内容数冒充最终覆盖。

## 17. 主要失败模式与恢复

| 失败 | 防护 | 玩家结果 |
|---|---|---|
| 传送双触发/旧请求晚完成 | token、单事务、deadline | 一次成功或回到原地图，输入恢复 |
| 场景/出生点缺失 | Registry + preflight + 候选实例校验 | 不释放旧地图，显示错误 ID |
| 存档截断/断电 | temp、checksum、A/B 双世代、最高有效 generation | 恢复最后有效世代并提示来源 |
| 迁移未知 ID | alias + unresolved 清单 | 不静默丢物；阻断关键地图，隔离未知物品 |
| 重复 apply | owner import 幂等、派生值重算、连接去重 | 状态不叠加，UI/Timer 不重复 |
| 双击买卖/领奖 | operation/event ledger | 只提交一次 |
| Actor 在异步回调前已释放 | run ID、weak validity check、取消 token | 忽略过期结果，不修改新世界 |
| 自动战斗目标不可达 | zone、进展监控、有限脱困 | 停止并恢复手动，不无限忙等 |
| 背包满 | 事务 preflight | 不扣钱、不吞物，给出可恢复提示 |
| Boss 永久无敌/阶段卡住 | 显式状态、阶段 deadline、reset | 遭遇失败并可重试，不软锁存档 |

## 18. 性能策略

- 不在 `_process()` 每帧全树搜索；目标列表由 Encounter/Spawner 注册维护。
- 不在战斗中动态拼接/加载图标和音效路径；ContentRegistry 启动时验证并缓存定义，表现资源按场景缓存。
- 掉落、飘字、短音效使用有上限的池或明确生命周期。
- SceneManager 用 `ResourceInteractiveLoader` 分帧加载大地图并记录进度。
- 每 600 帧记录一次节点、Timer、信号、内存和规范状态摘要，不在每帧写日志。
- 优化以 profiler 和固定场景基准为依据，不为了抽象提前引入线程、ECS 或行为树。

## 19. 架构决策摘要

| 决策 | 采用 | 拒绝及原因 |
|---|---|---|
| 迁移策略 | 渐进绞杀 | 大爆炸重写会同时破坏表现、地图和存档 |
| 主场景 | 持久 GameRoot、只换 World 子节点 | `change_scene()` 会释放玩家/UI 并重复创建 |
| 全局服务 | 仅六个 Autoload | 继续增加 Manager 会形成隐藏全局耦合 |
| 领域结构 | 普通节点/Reference 组件，由 GameRoot 组装 | Inventory/Quest 全局单例会难测且变成第二 GameState |
| 数据身份 | ASCII 稳定 ID | 中文名、路径、节点名会随表现重构变化 |
| 内容格式 | JSON 为表格主数据，`.tscn/.tres` 为表现 | 全部写场景难审查；全部写 JSON 不适合动画/碰撞 |
| 存档 | JSON V2 + canonical hash + A/B 双世代提交 | 覆盖式 rename 在 Godot 3.5.3 Windows 存在删除窗口；数据库对单机 V1 又是额外复杂度 |
| 设置 | 独立 ConfigFile | 随读档回滚音量/按键体验错误 |
| 强化 | 确定性 +0～+10 | 失败制会鼓励读档并放大经济模拟范围 |
| 战斗 AI | 显式有限状态机 | 行为树对 10 敌人/4 Boss 是过度设计 |
| 自动战斗 | 前台、普通野外、公共 Intent API | 离线/Boss/副本自动化会破坏闭环和测试边界 |
| 测试 | 轻量 GDScript 进程 runner + PowerShell orchestrator | 立即引入第三方插件会增加缺失插件风险 |

## 20. 设计自审结论

- `ContentRegistry` 已提前到地图定义和 V2 存档之前，避免双重 ID 系统。
- GameRoot 迁移拆成组合根、SceneManager 事务、pilot 地图和批量地图四步，控制爆炸半径。
- V2 拆成 DTO、文件事务和 V1 迁移，不推翻已完成的 V1 脚手架。
- UI 只先迁持久壳，领域 presenter 随系统迁移，避免提前冻结错误 API。
- 强化前明确引入装备实例和经济事务。
- WorldState/Flags 在 Quest 前完成。
- Boss/副本前建立 EncounterDirector。
- 每个异步/可重试副作用都有 token、deadline、ledger 或事务边界。
- 发布验证同时检查退出码、终结记录和错误日志，消除当前“测试退出 0 但仍有 ERROR”的假绿。
