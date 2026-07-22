# Phase 21: Combat Gate Acceptance Report

## Status

Partial acceptance. The deterministic combat foundation, real Steve/Snake adapter boundary, component soak, and a 15-minute simulated adapter-scene soak are verified. Repeated real Snake death and reward presentation are also verified. The Combat Gate remains open pending a final hard-gate audit and tag decision.

## Evidence

- `tests/test_combat_matrix.gd` verifies the deterministic two-skill by two-enemy matrix through SkillBook and CombatAction.
- `tests/test_combat_trace.gd` verifies a fixed-seed trace through TargetRegistry, EnemyBrain, and SpawnerScope.
- `tests/test_combat_soak.gd` runs 54,000 ticks, validating no missing target, effect expiry, one defeat, and one reward per encounter.
- `tests/test_legacy_combat_scene.gd` starts the project with Autoloads, instances real Steve and two real Snake scenes, and verifies manual/basic and automation/active CombatDriver paths, Vitals HP/MP sync, and legacy adapter directionality.
- The same project-scene fixture simulates 54,000 ticks across 60 encounters and 120 real Steve-to-Snake adapter dispatches, verifying both adapters remain synchronized with Vitals and health bars.
- The project-scene fixture defeats a real Snake, invokes death twice, and verifies the money reward is presented once; Snake now owns its death idempotency guard.
- `scripts/test_runner.ps1 -Lane all` completed successfully on Godot `3.5.3`; 33 manifest tests passed and `resource_scene_smoke` loaded 75 scenes.

## Scope Decisions

- Godot 3.5 emits two project-Autoload process-teardown resource diagnostics for project-started scene tests. The runner classifies only these exact teardown lines separately; all script, parser, missing-resource, and runtime diagnostics remain failures.
- The tracked `tests/test_skills_factory_cold_import.gd` experiment and generated artifacts are not part of this report or commit.

## Remaining Gate Work

1. Perform the final hard-gate audit against the roadmap requirements.
2. Record the final decision and create the `combat-vertical-slice` tag only if every requirement is evidenced.
