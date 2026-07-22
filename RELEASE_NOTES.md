# Release Notes

## Unreleased

### Phase 13 - Foundation Gate Audit

- Added an evidence-based Foundation Gate audit; resource checks pass, while legacy Godot exit resource leaks correctly block the gate.
- Removed the V1 save test's intentional invalid-JSON engine error without weakening backup recovery coverage.

### Phase 12 - Settings and Audio Foundation

- Added isolated `settings.cfg` persistence for master audio volume through `AudioManager`.
- Added an audio settings round-trip test; existing Godot exit resource-leak logs remain visible to the strict runner.

### Phase 11 - V1 to V2 Migration Aliases

- Added versioned aliases for pilot V1 map paths, Chinese item names, and skill names.
- Added migration regression coverage that rejects unresolved legacy values explicitly.

### Phase 10 - Dual-Generation Save Foundation

- Added isolated V2 `save_a/save_b` generation selection and non-active generation writes.
- Added regression coverage for alternating generations and recovery from an invalid higher generation.

### Phase 09 - V2 State Envelope Foundation

- Added an isolated V2 JSON-safe state envelope with section versions and stable map/spawn location fields.
- Added a Godot regression test for schema rejection and V2 JSON round-trip normalization.

### Phase 08 - Map Migration Inventory

- Added a machine-readable inventory of five candidate maps, their embedded Player/UI nodes, and direct scene-change usage.

### Phase 07 - Map Definition Pilot

- Added stable map, spawn, and portal definitions for the Level1 and JiangLin pilot maps.
- Extended content auditing to reject missing default spawns, portal target maps, and portal target spawns.

### Phase 06 - Transactional World Replacement Foundation

- Added `SceneManager.replace_world`, which validates and instances a candidate before replacing the existing `WorldRoot` child.
- Added a regression test proving missing candidates preserve the current world without emitting an engine error.

### Phase 05 - Persistent Runtime Root Foundation

- Added the compatibility-first `GameRoot` scene with stable service, world, player, runtime actor, UI, and transition containers.
- Added a Godot lifecycle regression test for the root session ID and empty compatibility container invariants.

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
