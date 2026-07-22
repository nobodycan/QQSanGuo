# Release Notes

## Unreleased

### Phase 04 - ContentRegistry Pilot

- Added versioned pilot packs for one item, skill, and map using stable ASCII IDs with legacy-name aliases.
- Added `content_registry_audit` to validate pack presence, ID format/uniqueness, and referenced scene or icon paths.

### Phase 03 - Global Boundary Foundation

- Added `ContentRegistry`, `EventBus`, and `AudioManager` as the remaining target Autoloads.
- Added a versioned legacy-reference baseline and resource-lane static gate that rejects new legacy global references, direct scene switches, and unsafe runtime APIs.

### Phase 01 Follow-up - Cold Import and Icon Fallback Safety

- Replaced the `SkillsFactory.gd` fallback texture `preload()` with runtime `load()` so the script can parse before a project's first Godot import.
- Added `startup_import_safety` to the resource lane, preventing a reintroduction of the cold-import-unsafe preload.
- Fixed `ItemIconResolver` to check the source `.png` file instead of treating an orphaned `.png.import` sidecar as a valid icon.
- Updated the icon resolver regression test to assert raw-file absence, matching the intended fallback contract.

### Verification

- A clean isolated Godot 3.5.3 import completed with 16,099 generated cache files and no temporary import files.
- The `SkillsFactory` cold-import regression test and the post-import icon fallback regression test pass.

### Phase 02 - Test Orchestration and Structured Diagnostics

- Added `scripts/test_runner.ps1` as the single test entry point with lane selection, watchdogs, isolated test homes, UTF-8 logs, JSON reports, and JUnit output.
- Added protocol self-tests for pass, explicit failure, timeout, and false-green error logs.
- Added `tests/TestProtocol.gd` and migrated current GDScript tests to emit `TEST_RESULT` instead of using bare `assert`.
- Added a versioned test manifest covering unit, integration, resource, and scene tests.
- Godot executable discovery uses `-GodotPath` or `GODOT_BIN`; when unavailable, Godot tests are reported as blocked rather than passing.

### Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1 -SelfTest` passes.
- Full Godot lanes require a Godot 3.5.3 executable and remain pending on machines without it.
