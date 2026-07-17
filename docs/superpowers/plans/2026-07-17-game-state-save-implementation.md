# Game State Save Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fragile node-path save files with a versioned JSON save that restores map, player, inventory, hotbar, equipment, and skill state without a fixed delay.

**Architecture:** `GameState` owns a JSON-only snapshot; `SaveManager` validates, backs up, and reads/writes it; `SceneManager` changes maps and restores only after the new scene has entered the tree. Existing `PlayerInventory` remains the runtime data source during this migration and receives explicit equipment/skill collections.

**Tech Stack:** Godot 3.5.3, GDScript, Godot `File`, `Directory`, `JSON`, Autoload, JSON files in `user://`.

---

## File structure

- Create: `autoload/GameState.gd` — V1 schema, snapshot/apply, JSON-safe normalization.
- Create: `autoload/SaveManager.gd` — save-file read/write, backup, validation result.
- Create: `autoload/SceneManager.gd` — scene change and deferred state restore.
- Create: `tests/test_game_state.gd` — script-runner tests for pure state normalization.
- Create: `tests/test_save_manager.gd` — script-runner tests for save-file failures and backup behavior.
- Modify: `project.godot:26-37` — register the three new Autoloads after legacy Autoloads.
- Modify: `PlayerInventory.gd:1-140` — make equipment and skill ownership explicit runtime data.
- Modify: `Item.gd:158-178` — update the runtime equipment map when equipment changes.
- Modify: `SaveState.gd:1-81` — replace the legacy line-by-line writer/loader with compatibility forwarding.
- Modify: `SaveAndLoad.gd:6-17` — call the new save/load entry points and display their failure state.
- Modify: `Inventory.gd:31-39` and `Hotbar.gd:29-35` — provide idempotent refresh functions used after loading.

## Task 1: Establish an executable Godot 3 baseline

**Files:**
- Modify: none
- Test: manual baseline checklist

- [ ] **Step 1: Install or unpack the official Windows Godot 3.5.3 editor and export templates.**

Use the official archive version, not Godot 4. Record the absolute executable path in the terminal session as `$godot`.

```powershell
$godot = 'C:\Tools\Godot_v3.5.3-stable_win64.exe'
& $godot --version
```

Expected: the command prints a `3.5.3` version string.

- [ ] **Step 2: Import and run the untouched project.**

```powershell
& $godot --editor --path . project.godot
```

Expected: Godot imports the project. In the editor, run `Scene/bajun.tscn` and record every parse, missing-resource, or plugin error before changing code.

- [ ] **Step 3: Run the baseline gameplay checklist.**

Verify movement, combat, item pickup, inventory, hotbar, map transfer, save, and load. Save the error list in the implementation notes for the next task; do not silently fix unrelated behavior.

- [ ] **Step 4: Commit the baseline notes only if they are added to the repository.**

```powershell
git add docs/
git commit -m "docs: record Godot 3 baseline"
```

Expected: either a documentation-only commit exists, or there is no commit when no notes file was added.

## Task 2: Add explicit runtime equipment and skill state

**Files:**
- Modify: `PlayerInventory.gd:1-140`
- Modify: `Item.gd:158-178`
- Test: `tests/test_game_state.gd`

- [ ] **Step 1: Write a failing test for the V1 default equipment and skill fields.**

Create `tests/test_game_state.gd` with a script that exits non-zero if an assertion fails.

```gdscript
extends SceneTree

func _init():
	var state = preload("res://autoload/GameState.gd").new()
	var data = state.new_save_data()
	assert(data["equipment"].has("Sword"))
	assert(data["equipment"]["Sword"] == "")
	assert(data["skills"]["known"] == [])
	assert(data["skills"]["equipped"] == [])
	quit()
```

- [ ] **Step 2: Run the test and verify the intended failure.**

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
```

Expected: FAIL because `autoload/GameState.gd` does not exist.

- [ ] **Step 3: Add explicit collections to `PlayerInventory.gd`.**

Add these members near the existing inventory and hotbar dictionaries. Use all actual equipment node names from `Inventory.tscn`, including `Mask`.

```gdscript
const EQUIPMENT_SLOTS = ["Head", "Up_Body", "Necklace", "Hand", "Sword", "Boot", "Down_Body", "Wing", "Mask", "Ring"]

var equipment = {
	"Head": "", "Up_Body": "", "Necklace": "", "Hand": "", "Sword": "",
	"Boot": "", "Down_Body": "", "Wing": "", "Mask": "", "Ring": ""
}
var known_skills = []
var equipped_skills = []
```

Update `Item.exchange_equipment(catagory)` so every equip and unequip writes the selected item ID to `PlayerInventory.equipment[catagory]` before refreshing text. Do not serialize textures or item nodes.

- [ ] **Step 4: Run the test and verify the expected intermediate failure.**

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
```

Expected: still FAIL because `GameState.new_save_data()` is absent; the new runtime fields compile without parse errors.

- [ ] **Step 5: Commit the explicit runtime state.**

```powershell
git add PlayerInventory.gd Item.gd tests/test_game_state.gd
git commit -m "feat: track equipment and skill state"
```

## Task 3: Implement and test the V1 GameState schema

**Files:**
- Create: `autoload/GameState.gd`
- Modify: `tests/test_game_state.gd`
- Modify: `project.godot:26-37`

- [ ] **Step 1: Extend the failing tests with normalization cases.**

Append tests that verify a complete valid dictionary is accepted, missing required keys return `null`, and malformed inventory entries are discarded.

```gdscript
	var valid = state.new_save_data()
	valid["map_path"] = "res://Level1.tscn"
	valid["inventory"] = {"0": ["铁剑", 1], "bad": ["", 0]}
	var normalized = state.normalize(valid)
	assert(normalized != null)
	assert(normalized["inventory"].has("0"))
	assert(!normalized["inventory"].has("bad"))
	valid.erase("player")
	assert(state.normalize(valid) == null)
```

- [ ] **Step 2: Run the test and confirm it fails because the schema API is missing.**

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
```

Expected: FAIL at `new_save_data` or `normalize`.

- [ ] **Step 3: Implement the minimal JSON-only GameState API.**

Create `autoload/GameState.gd` as an `extends Node` Autoload. Its public API is `new_save_data()`, `normalize(raw)`, `capture_from_scene(scene_root)`, and `apply_to_scene(scene_root, snapshot)`. The production implementation is constrained by the test cases in Steps 1 and 3: it returns the complete V1 dictionary, returns `null` for invalid input, copies only JSON primitives, and applies data only when the scene root, `UserInterFace`, and `Steve` are present.

`normalize` must require `version == 1`, a non-empty `res://` map path, `player`, `inventory`, `hotbar`, `equipment`, and `skills`. It must convert dictionary slot keys to strings in saved JSON, reject quantities less than one, preserve empty equipment slots as `""`, and only retain string skill IDs.

Register `GameState="*res://autoload/GameState.gd"` in `[autoload]`.

- [ ] **Step 4: Run the GameState tests and verify they pass.**

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
```

Expected: exit code `0` with no parser errors or assertion failures.

- [ ] **Step 5: Commit the V1 schema.**

```powershell
git add autoload/GameState.gd tests/test_game_state.gd project.godot
git commit -m "feat: add versioned game state schema"
```

## Task 4: Implement SaveManager with validation and backup

**Files:**
- Create: `autoload/SaveManager.gd`
- Create: `tests/test_save_manager.gd`
- Modify: `project.godot:26-37`

- [ ] **Step 1: Write failing tests for missing, corrupt, and backup save cases.**

Create `tests/test_save_manager.gd`. Use a dedicated test filename and clean it before and after each case.

```gdscript
extends SceneTree

func _init():
	var manager = preload("res://autoload/SaveManager.gd").new()
	manager.save_path = "user://test_game_state.json"
	manager.backup_path = "user://test_game_state.backup.json"
	assert(manager.load_data()["ok"] == false)
	assert(manager.load_data()["error"] == "missing_save")
	quit()
```

- [ ] **Step 2: Run the save tests and verify the expected failure.**

```powershell
& $godot --headless --path . -s res://tests/test_save_manager.gd
```

Expected: FAIL because `autoload/SaveManager.gd` does not exist.

- [ ] **Step 3: Implement SaveManager with structured results.**

Create `autoload/SaveManager.gd` using this result contract in every public method:

```gdscript
{ "ok": true, "data": snapshot }
{ "ok": false, "error": "missing_save" }
```

Implement `save_current_scene()`, `save_data(snapshot)`, `load_data()`, and `load_into_current_scene()`. `save_data` must normalize through `GameState`, copy an existing valid main save to `backup_path` before writing, write JSON in one operation, and return `invalid_state` rather than write invalid data. `load_data` must parse main then backup, returning `corrupt_save` when neither parses and `unsupported_version` when JSON parses but `GameState.normalize` rejects the version.

Register `SaveManager="*res://autoload/SaveManager.gd"` after `GameState`.

- [ ] **Step 4: Add and run the remaining backup tests.**

Add cases that write a valid save, overwrite it with another valid save, corrupt the main file, then assert `load_data()` returns the backup snapshot. Run both scripts.

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
& $godot --headless --path . -s res://tests/test_save_manager.gd
```

Expected: both commands exit `0`.

- [ ] **Step 5: Commit the save manager.**

```powershell
git add autoload/SaveManager.gd tests/test_save_manager.gd project.godot
git commit -m "feat: add validated save manager"
```

## Task 5: Restore scenes without a fixed delay

**Files:**
- Create: `autoload/SceneManager.gd`
- Modify: `SaveState.gd:1-81`
- Modify: `project.godot:26-37`
- Test: manual scene restore checklist

- [ ] **Step 1: Write a failing scene-restore smoke script.**

Create a small test scene script that sets a V1 snapshot with `map_path = "res://Level1.tscn"`, requests restore, waits two idle frames, and asserts that the current scene path equals the requested map path. Do not use a timer in this test.

```gdscript
yield(get_tree(), "idle_frame")
yield(get_tree(), "idle_frame")
assert(get_tree().current_scene.filename == "res://Level1.tscn")
```

- [ ] **Step 2: Run the smoke test and verify it fails because SceneManager is absent.**

```powershell
& $godot --headless --path . -s res://tests/test_scene_restore.gd
```

Expected: FAIL with a missing `SceneManager` or missing restore method error.

- [ ] **Step 3: Implement SceneManager and forwarding compatibility methods.**

Create `autoload/SceneManager.gd` with `restore_snapshot(snapshot)` and `change_to_map(map_path)`. Reject any map path that does not begin with `res://` or does not end in `.tscn`. After `get_tree().change_scene(map_path)`, yield `idle_frame` until `get_tree().current_scene` exists, then call `GameState.apply_to_scene(current_scene, snapshot)`. Return a structured `{ "ok": bool, "error": String }` result. Never call `create_timer(1.0)`.

Replace `SaveState.save_game()` with `return SaveManager.save_current_scene()` and replace `SaveState.load_game()` with: load data through `SaveManager`, return its error if failed, otherwise call `SceneManager.restore_snapshot(result["data"])`.

Register `SceneManager="*res://autoload/SceneManager.gd"` after `SaveManager`.

- [ ] **Step 4: Run the scene smoke test and manually verify restoration.**

```powershell
& $godot --headless --path . -s res://tests/test_scene_restore.gd
```

Then in the editor, save from Level1, return to Login, load, and confirm the map is restored without a one-second pause.

- [ ] **Step 5: Commit the deferred restore path.**

```powershell
git add autoload/SceneManager.gd SaveState.gd tests/test_scene_restore.gd project.godot
git commit -m "feat: restore saved state after scene readiness"
```

## Task 6: Connect UI, rebuild views, and perform end-to-end acceptance

**Files:**
- Modify: `SaveAndLoad.gd:6-17`
- Modify: `Inventory.gd:31-39`
- Modify: `Hotbar.gd:29-35`
- Test: manual end-to-end checklist

- [ ] **Step 1: Write a failing UI refresh assertion.**

Add a scene test that restores inventory and hotbar dictionaries with one item each, calls the new refresh functions, and asserts their corresponding slot nodes contain an item.

- [ ] **Step 2: Run the UI refresh test and verify it fails.**

```powershell
& $godot --headless --path . -s res://tests/test_scene_restore.gd
```

Expected: FAIL because idempotent `refresh_from_player_inventory()` methods do not yet exist.

- [ ] **Step 3: Implement idempotent UI refresh and user-visible errors.**

Add `refresh_from_player_inventory()` to `Inventory.gd` and `Hotbar.gd`. Each function must remove previously instantiated item children from its slots, then call the existing initialization loop once. Update `SaveAndLoad.gd` to call `SaveState.save_game()` and `SaveState.load_game()`, inspect the returned result, print `result["error"]` on failure, and only print `save` or `load` when `result["ok"]` is true.

- [ ] **Step 4: Run all automated scripts.**

```powershell
& $godot --headless --path . -s res://tests/test_game_state.gd
& $godot --headless --path . -s res://tests/test_save_manager.gd
& $godot --headless --path . -s res://tests/test_scene_restore.gd
```

Expected: all commands exit `0`.

- [ ] **Step 5: Run the end-to-end acceptance sequence three times.**

In a supported map: change position, level/HP/MP, currency, inventory, hotbar, every equipment slot, and skills. Save, return to Login, load, and verify all state. Repeat three times. Also verify missing and intentionally malformed test saves produce a readable error while leaving the current scene unchanged.

- [ ] **Step 6: Commit the UI integration and acceptance evidence.**

```powershell
git add SaveAndLoad.gd Inventory.gd Hotbar.gd tests/
git commit -m "feat: connect save state to game UI"
```

## Verification matrix

| Case | Expected result |
|---|---|
| No save | `missing_save`; current scene unchanged |
| Invalid JSON | backup loads if valid; otherwise `corrupt_save` |
| Unknown version | `unsupported_version`; current scene unchanged |
| Invalid map | `invalid_map`; no scene switch |
| Empty inventory/hotbar | empty UI, no errors |
| Missing equipment slot | skipped safely; state remains valid |
| Empty skills | saved and restored as empty arrays |
| Normal round trip | map, player, inventory, hotbar, equipment, skills restore |

## Self-review

- Spec coverage: Tasks 2-6 cover every persisted state category, versioning, backup, validation, no fixed delay, UI refresh, and end-to-end acceptance.
- Scope: no task adds quests, combat rework, jobs, pets, home, dungeon, or Godot 4 migration.
- Environment blocker: Godot 3.5.3 is not currently available on PATH; Task 1 must complete before implementation testing.
