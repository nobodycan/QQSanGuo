# Release Notes

## Unreleased

### Phase 20 - EnemyBrain Foundation

- Added deterministic idle/chase/attack/return/dead enemy AI transitions with 10,000 tick regression coverage.
- Added scoped spawn ownership and one-time defeat reward protection.

### Phase 19 - Skills Foundation

- Added data-driven skill unlock, MP cost, and cooldown validation for basic and active pilot skills.

### Phase 18 - Damage Foundation

- Added deterministic damage resolution with multiplier, critical, defense, finite-number validation, and a non-negative floor.
- Added deterministic stackable effect state with refresh and expiry behavior.
- Added CombatAction to compose hit deduplication, damage calculation, and Vitals resolution.

### Phase 17 - Targeting Foundation

- Added faction-aware target registration with stable nearest-target selection and release handling.
- Added hit resolution that rejects friendly/self targets and deduplicates stable hit IDs.

### Phase 16 - Vitals Foundation

- Added a versioned Vitals model for HP/MP clamp, recovery, idempotent death, and revival.
- Added regression coverage for overkill, duplicate death prevention, dead recovery, and revival bounds.
- Added an explicit adapter for legacy negative-damage and positive-recovery health deltas.
- Routed Steve healing and injury signals through Vitals while preserving legacy death presentation.
- Recorded Phase 16 acceptance after the full 19-test Godot Gate passed.

### Phase 15 - PlayerStats Foundation

- Added a versioned PlayerStats v1 model with explicit 1–30 XP progression, derived stats, and level-cap overflow XP.
- Added a PlayerInventory compatibility adapter and upgraded the V2 player section default to version 1.
- Added per-level N-1/N/N+1 regression coverage, multi-level progression, and level-30 cap validation.
- Added idempotent player v0-to-v1 migration for legacy experience and attribute fields.
- Routed Steve experience rewards through PlayerStats instead of directly incrementing legacy level and attributes.
- Added V2 envelope coverage for player v0 migration and repeat-normalization equivalence.
- Recorded the Phase 15 authority boundary; legacy equipment attribute mutation remains explicitly deferred to Phase 23.

### Phase 14 - Player Intent Foundation

- Added `PlayerIntent`, `PlayerInputSampler`, and a deterministic `PlayerMovementModel` for future shared manual and automation control.
- Updated the legacy Steve adapter to consume resolved movement intents; non-idle manual input interrupts automation in the same physics frame.
- Added a movement animation adapter for the legacy idle, run, jump, and climb animation-tree states.
- Added a 600-frame movement state-transition regression that proves temporary movement locks do not persist.
- Recorded Phase 14 acceptance evidence for shared intent entry, movement/animation extraction, and manual interruption of automation.
- Added regression coverage for intent arbitration, climbing jumps, and movement locking.

### Phase 13 - Foundation Gate Audit

- Foundation Gate now passes all 16 manifest tests on Godot `3.5.3`, including 75 `PackedScene` resource smoke checks.
- Removed test-owned state and scene resources before shutdown, eliminating process-exit resource leaks without suppressing errors.
- Added a minimal scene-restore fixture and focused scene smoke coverage on `PackedScene` loadability rather than legacy gameplay side effects.
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
