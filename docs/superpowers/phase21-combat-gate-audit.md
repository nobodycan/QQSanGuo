# Phase 21 Combat Gate Audit

## Available Foundations

- PlayerIntent, PlayerStats, Vitals, targeting, hit deduplication, damage, effects, CombatAction, SkillBook, EnemyBrain, and SpawnerScope each have focused regression coverage.
- Unit lane coverage currently validates their contracts independently.

## Gate Status: Not Yet Passed

- A deterministic two-skill by two-enemy CombatAction matrix now passes in the integration lane.
- A fixed-seed 12-tick encounter trace now exercises TargetRegistry selection, EnemyBrain transitions, and SpawnerScope ownership; it reproduces for the same seed and differs for the two pilot AI roles.
- A 54,000-tick (15-minute at 60 Hz) soak now validates target continuity, temporary-effect expiry, idempotent defeat handling, and one reward per encounter.
- Steve and Snake now route their legacy `injury` entry points through CombatAction and Vitals while preserving existing animation and UI callbacks. The two remaining cross-object calls retain the `injury` name as compatibility adapters rather than writing HP directly.
- A project-started scene fixture now instances the real Steve and Snake scenes with the required UI contract, verifies both adapter directions, HP/UI synchronization, Vitals-backed death, and one reward signal.
- The scene-test runner keeps script and runtime diagnostics strict, while classifying only Godot 3.5's two known project-Autoload process-teardown resource lines separately.
- CombatDriver now sends manual and automation PlayerIntent sources through one SkillBook and CombatAction path; both produce the same two-skill by two-enemy matrix.
- Steve's live skill input and automation routes have not yet been bound to CombatDriver.

## Next Vertical Slice

1. Bind Steve's live skill input and automation routes to CombatDriver, then extend the real-scene fixture with the two-skill by two-enemy matrix.
2. Re-run the soak against the migrated scene adapters and publish the Combat Acceptance Report.
