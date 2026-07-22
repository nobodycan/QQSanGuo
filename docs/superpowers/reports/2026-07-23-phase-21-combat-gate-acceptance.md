# Phase 21: Combat Gate Acceptance Report

## Status

Accepted. The final hard-gate audit found all remaining runtime damage paths routed through CombatAction/Vitals adapters; the final full Gate passed on Godot `3.5.3`.

## Evidence

- `tests/test_combat_matrix.gd` verifies the deterministic two-skill by two-enemy matrix through SkillBook and CombatAction.
- `tests/test_combat_trace.gd` verifies a fixed-seed trace through TargetRegistry, EnemyBrain, and SpawnerScope.
- `tests/test_combat_soak.gd` runs 54,000 ticks, validating no missing target, effect expiry, one defeat, and one reward per encounter.
- `tests/test_legacy_combat_scene.gd` starts the project with Autoloads, instances real Steve and two real Snake scenes, and verifies the complete two-skill by two-enemy matrix for both manual and automation CombatDriver paths, Vitals HP/MP sync, and legacy adapter directionality.
- The same project-scene fixture simulates 54,000 ticks across 60 encounters and 120 real Steve-to-Snake adapter dispatches, verifying both adapters remain synchronized with Vitals and health bars.
- The project-scene fixture defeats a real Snake, invokes death twice, and verifies the money reward is presented once; Snake now owns its death idempotency guard.
- The project-scene fixture verifies dengmao Boss resolved damage and Vitals-backed HP synchronization.
- `scripts/test_runner.ps1 -Lane all` completed successfully on Godot `3.5.3`; 33 manifest tests passed and `resource_scene_smoke` loaded 75 scenes.

## Scope Decisions

- Godot 3.5 emits two project-Autoload process-teardown resource diagnostics for project-started scene tests. The runner classifies only these exact teardown lines separately; all script, parser, missing-resource, and runtime diagnostics remain failures.
- The tracked `tests/test_skills_factory_cold_import.gd` experiment and generated artifacts are not part of this report or commit.

## Remaining Gate Work

The `combat-vertical-slice` tag marks this accepted Gate.
