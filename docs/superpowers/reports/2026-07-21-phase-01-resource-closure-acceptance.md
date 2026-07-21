# Phase 01: Resource Closure and Repeatable Clean Import Acceptance Report

**Status:** Accepted

**Verified commit:** `daad3c94`

## Evidence

- `tests/test_resource_audit.ps1` completed with `TEST_RESOURCE_AUDIT_PASS`.
- Project audit completed with `ok:true`, `scanned_files:152`, `references:2189`, and empty `missing`, `case_mismatch`, `invalid_manifest`, and `missing_plugin` arrays.
- The dynamic manifest declares 61 resolvable image resources. UTF-8 paths are JSON-escaped; duplicate entries, terminal slashes, scalar array fields, traversal, and invalid types are rejected.
- `tests/test_item_icon_resolver.gd` exited 0 under Godot 3.5.3. The missing `龙泉剑` source icon is handled by the deterministic existing `铁剑.png` fallback, so no missing resource is loaded.
- Scene smoke command: `Godot_v3.5.3-stable_win64.exe --path <checkout> --no-window --audio-driver Dummy --fixed-fps 60 -s res://tests/resource_scene_smoke.gd` returned `RESOURCE_SCENE_SMOKE_RESULT {"failures":[],"loaded_count":75,"ok":true,"scene_count":75}`. Classifier totals were Parser Error=0, missing resource=0, missing plugin=0.

## Clean import proof

Two fresh detached worktrees at `daad3c94` ran:

```powershell
& $godot --editor --no-window --audio-driver Dummy --quit
```

Both runs completed. Each classified stdout/stderr log had Parser Error=0, missing resource=0, and missing plugin=0. Their only Git status entries were the two untracked capture logs; no tracked file, including `.import`, changed. The temporary worktrees are removed after this report is committed.

## Classified non-Phase diagnostics

The scene isolation runner emitted legacy node-tree assumptions and shutdown leak diagnostics (for example missing `bajun/Steve`, `PopupMenu`, and ObjectDB/resource cleanup warnings). They are neither Parser Error nor missing-resource/plugin diagnostics and occur when independently instantiating legacy scenes without their full world tree. They are recorded for later scene-ownership work and are not Phase 01 resource-closure failures.

## Scope controls

- The stale TexturePacker declaration is absent.
- Generated `.import` normalization commit `c6065a39` remains isolated on `codex/phase01-import-normalization` and is deliberately excluded from this Phase deliverable.
- Only Phase-owned source, test, manifest, and documentation paths are staged.
