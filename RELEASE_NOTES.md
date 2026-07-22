# Release Notes

## Unreleased

### Phase 25 - Deterministic Enhancement Foundation

- Added persisted per-instance enhancement levels from `+0` through `+10`, with safe equipment v1-to-v2 migration.
- Added explicit 10000-to-14000 basis-point multipliers, deterministic rounding, derived enhanced modifiers, and a stable `power_score`.
- Added regression coverage for every enhancement level, cap rejection, independent same-name instances, and V2 JSON round-trip migration.
- Added a three-tier enhancement quote and atomic wallet, material, and equipment transaction with idempotent operation handling.
- Extended the legacy equipment bridge with per-slot enhancement and presenter-safe name, level, and power-score projection.

### Phase 24 - Economy Foundation

- Added versioned WalletState with non-negative balance preflight, bounded idempotency ledger, atomic delta application, and v0 migration.
- Added GameStateV2 wallet section v1 with safe initialization for older envelopes and explicit future/lossy migration rejection.
- Added a legacy wallet bridge that projects idempotent wallet operations back to the existing money and juntuan UI fields.
- Routed Steve reward updates through PlayerInventory wallet operations, preserving legacy calls while supporting explicit idempotent reward IDs.
- Added EconomyTransaction preflight for atomic wallet debit plus inventory credit; duplicate, overdraft, and full-inventory paths leave both states unchanged.
- Added RewardService for idempotent atomic wallet and optional item rewards; full inventory prevents partial reward grants.

### Phase 23 - Equipment Foundation

- Added a versioned 10-slot EquipmentState with job/level validation, equip/swap/unequip commands, and base-derived modifier aggregation without stat drift.
- Promoted GameStateV2 equipment to section v1 with safe empty-v0 migration and explicit rejection of lossy or unsupported versions.
- Added deterministic PlayerStats and EquipmentState composition so equipment modifiers apply after level-derived base stats without drift.
- Added idempotent EquipmentState v0 migration with explicit aliases and stable slot-distinct identities for repeated legacy equipment names.
- Added a legacy equipment bridge that converts existing item JSON fields into canonical modifiers, validates eligibility, and projects equipped names to the current UI shape.

### Phase 22 - Inventory Identity Foundation

- Added stable ItemTemplate IDs plus explicit stack and non-stack ItemInstance identities as the basis for command-driven inventory state.
- Added a versioned 50-slot InventoryState with deterministic stack insertion and full-capacity rejection without partial mutation.
- Added command-model slot movement and stack splitting with quantity-conservation regression coverage.
- Added inventory consumption with final-stack cleanup and quest-item consumption protection.
- Added canonical inventory export and idempotent v0-to-v1 migration using legacy item-name aliases.
- Promoted the GameStateV2 inventory section to v1 with safe empty-v0 migration and explicit rejection of unknown or lossy sections.
- Added a deterministic 1,000-command inventory regression that proves move/split quantity conservation and export/import canonical equivalence.
- Added a legacy inventory bridge that imports explicit aliases, applies canonical move/split commands, and projects the state back to the existing UI dictionary format.
- Routed PlayerInventory pickup insertion through the legacy bridge when metadata is available, preserving the existing UI projection while enforcing canonical capacity rules.
- Routed legacy inventory take, place, and quantity adjustments through the command bridge; hotbar behavior remains unchanged pending its separate migration.
- Replaced remaining inventory UI dictionary mutations with PlayerInventory command calls for consumption, deletion, and legacy slot drag operations.
- Legacy non-stack inventory imports now mint distinct ItemInstance identities, preserving same-name equipment separation across migration.

### Phase 21 - Combat Gate Audit

- Recorded the Combat Gate as pending and identified the missing two-skill by two-enemy deterministic scenario coverage.
- Added a passing deterministic two-skill by two-enemy CombatAction integration matrix.
- Added a fixed-seed 12-tick encounter trace covering target selection, enemy state transitions, and spawn ownership; matching seeds reproduce and distinct pilot roles diverge.
- Added a 54,000-tick combat soak covering continuous targeting, effect expiry, idempotent defeats, and one-time rewards across 60 encounters.
- Routed the legacy Steve and Snake `injury` entry points through CombatAction and Vitals while retaining animation and UI compatibility callbacks.
- Added project-started scene coverage for real Steve/Snake adapter damage, health-bar synchronization, death signaling, and reward presentation.
- Extended the test runner with a project-scene mode so Autoload-backed scenes can be tested while retaining strict runtime and script diagnostics.
- Added CombatDriver so manual and automation PlayerIntent sources share SkillBook and CombatAction resolution for the two-skill by two-enemy matrix.
- Routed Steve's auto-chase and hit callbacks through CombatDriver, with real-scene coverage for manual/basic and automation/active skills against two Snake instances.
- Removed Steve's legacy magic-to-health setter and routed self-heal HP/MP recovery through Vitals.
- Added the Phase 21 Combat Gate acceptance report, documenting verified evidence and the remaining real-scene soak requirement.
- Added a 54,000-tick real Steve/Snake adapter-scene soak covering 60 encounters and 120 shared-driver dispatches.
- Made real Snake death idempotent and added scene coverage proving repeated death grants the money reward once.
- Expanded the real Steve/Snake fixture to cover the complete manual and automation two-skill by two-enemy matrix.
- Routed Steve's remaining injury signal through the CombatAction/Vitals compatibility adapter.
- Routed dengmao Boss incoming damage through CombatAction and Vitals while preserving legacy presentation.
- Added project-scene coverage for dengmao resolved damage and Vitals-backed HP synchronization.
- Recorded Phase 21 Combat Gate acceptance after the final 33-test Godot Gate and 75-scene smoke check passed.

### Phase 20 - EnemyBrain Foundation

- Added deterministic idle/chase/attack/return/dead enemy AI transitions with 10,000 tick regression coverage.
- Added scoped spawn ownership and one-time defeat reward protection.
- Added two pilot enemy definitions with distinct combat signatures for the Combat Gate matrix.

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
