# Item Drop Resource Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore parsing of `ItemDrop.tscn`, `Enemy/Snake.gd`, and the snake-containing destination map without inventing new gameplay behavior.

**Architecture:** Update four stale texture references to the files they were renamed to in Git history; the old and new filenames have identical blob hashes. Protect the full resource dependency chain and actual teleport destination switch with a Godot script-runner smoke test.

**Tech Stack:** Godot 3.5.3, GDScript, `.tscn` text resources.

---

### Task 1: Add the failing resource-chain test

**Files:**
- Create: `tests/test_item_drop_resources.gd`

- [ ] **Step 1: Add a script-runner test** that calls `ResourceLoader.load()` for `res://ItemDrop.tscn`, `res://Enemy/Snake.gd`, and `res://assets/map/guyidaoguanai.tscn`, changes to the destination map, waits two idle frames, asserts `Steve` and `UserInterFace` exist, exits with code 1 on failure, and prints `TEST_ITEM_DROP_RESOURCES_PASS` on success.
- [ ] **Step 2: Run** `Godot_v3.5.3-stable_win64.exe --no-window --path ../.. -s res://tests/test_item_drop_resources.gd` from `.tools/godot-3.5.3`.
- [ ] **Step 3: Confirm RED:** the test exits nonzero because `res://UI/item_drop/32207-4.png` cannot be loaded through `ItemDrop.tscn`.

### Task 2: Repair references and verify

**Files:**
- Modify: `ItemDrop.tscn`
- Test: `tests/test_item_drop_resources.gd`

- [ ] **Step 1: Change ExtResource IDs 6-9** from `32207-4/1/2/3.png` to `速度-4/1/2/3.png`, preserving frame order.
- [ ] **Step 2: Re-run the resource-chain test and confirm** exit code 0 with `TEST_ITEM_DROP_RESOURCES_PASS`.
- [ ] **Step 3: Run** `test_game_state.gd`, `test_save_manager.gd`, and `test_scene_restore.gd`; require all PASS markers and exit code 0.
- [ ] **Step 4: Inspect the Git diff** and commit only `ItemDrop.tscn`, the test, and these two design/plan documents. Do not stage `.import` files or `.tools/`.
