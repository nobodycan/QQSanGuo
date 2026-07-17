# Game State、存档与场景切换设计

## 目标

为 Godot 3.x 单机项目建立稳定的“进入地图、游戏、保存、退出、加载、恢复”的状态闭环，同时保留现有 UI 和战斗逻辑。

第一期保存并恢复：

- 当前地图和玩家坐标；
- 玩家等级、经验、货币、基础属性、HP、MP；
- 背包和快捷栏；
- 装备槽；
- 已学技能与已装备技能。

## 范围

本期只新增三个 Autoload：`GameState`、`SaveManager`、`SceneManager`。现有 `PlayerInventory`、`SaveState`、`SceneChange` 和 UI 脚本不会被整体重写；迁移期间只由新模块调用或适配它们。

不在本期范围内：任务、NPC 剧情、掉落表、自动打怪、职业、宠物、家园、副本、Godot 4 迁移和 UI 全面解耦。

## 架构

```text
Steve + PlayerInventory + 装备/技能 UI
                    | snapshot / apply
                    v
               GameState
                    | JSON dictionary
                    v
               SaveManager
                    | user://save_game.json
                    v
               SceneManager
                    | change_scene + idle-frame restore
                    v
                当前游戏场景
```

### GameState

`GameState` 是内存中的唯一可序列化模型。它不保存节点路径、`Node`、`Texture` 或场景对象，只保存基础 JSON 类型。

```text
{
  "version": 1,
  "map_path": "res://Level1.tscn",
  "player": {
    "position": { "x": 0, "y": 0 },
    "level": 1,
    "experience": 0,
    "health": 1000,
    "magic": 1000,
    "money": 0,
    "juntuan": 0,
    "attributes": { ... }
  },
  "inventory": { "0": ["物品名", 1] },
  "hotbar": { "0": ["物品名", 1] },
  "equipment": { "Sword": "物品名" },
  "skills": { "known": [], "equipped": [] }
}
```

它提供两类操作：从现有运行时对象采集快照，以及在场景和 UI 就绪后应用快照。装备槽通过固定槽位名称保存物品 ID；技能不读取技能定义文件，而保存角色拥有/装备的技能 ID。

### SaveManager

`SaveManager` 只处理文件格式：写入、读取、JSON 解析、版本检测、字段校验和备份。

- 主存档为 `user://save_game.json`；
- 覆盖前将上一份有效主存档复制为 `user://save_game.backup.json`；
- 无存档、损坏 JSON、未知版本或缺少必需字段时返回明确失败状态，不切场景，也不修改运行时状态；
- V1 仅接受版本 `1`；今后由显式迁移函数处理旧版本。

### SceneManager

`SceneManager` 是地图切换的唯一新入口。它接收合法的 `res://*.tscn` 地图路径，调用 Godot 3 场景切换 API，并通过空闲帧/场景树就绪状态恢复存档，而不使用固定一秒延迟。

恢复顺序：切换场景 -> 等待新场景进入场景树 -> 应用 `PlayerInventory` 数据 -> 还原装备和技能状态 -> 更新背包/快捷栏 UI -> 找到 Steve 并写入位置与属性。

## 兼容策略

- `PlayerInventory` 继续为现有 UI 提供背包、快捷栏、数值字段；
- `GameState` 是存档边界的规范格式，而不是立即替换所有旧调用；
- 旧 `SaveState` 的按钮入口改为调用 `SaveManager`，旧的逐节点 `.save` 格式不再写入；
- 现有 `SceneChange` 可继续用于普通过场，但存档恢复只经 `SceneManager`；
- 存档加载失败时保留当前场景及运行状态。

## 错误处理与验收

必须覆盖：无存档、损坏存档、未知版本、地图不存在、Steve 节点不存在、空背包、空快捷栏、缺失装备槽、技能列表为空，以及正常保存/加载。

验收流程：在任一支持地图修改位置、属性、背包、快捷栏、装备和技能；保存后重启游戏并加载；地图、位置和所有上述状态恢复；连续重复三次不丢状态、不依赖固定延时。

## 测试策略

优先为纯数据逻辑编写 GDScript 单元测试：数据规范化、版本验证、存档解析、缺失字段和备份选择。场景恢复采用 Godot 集成测试或可重复的手工冒烟清单，验证场景树就绪后的恢复顺序。

## 实施顺序

1. 确认 Godot 3.5.3 能导入项目并建立基线。
2. 建立可测试的 `GameState` 数据模型和 V1 规范化。
3. 建立 `SaveManager`，完成写入、读取、备份和错误返回。
4. 建立 `SceneManager`，迁移存档恢复路径并移除固定等待。
5. 将保存/加载按钮接入新入口，完成验收流程。
