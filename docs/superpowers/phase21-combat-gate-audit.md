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
- Steve's auto-chase entry and hit callback now call CombatDriver. The project-started scene fixture verifies manual basic and automation active skills against two real Snake instances.
- Steve's legacy `magic` health setter has been removed and the self-heal timer now uses Vitals.recover; the real-scene fixture verifies simultaneous HP/MP recovery.
- The real-scene fixture now simulates 54,000 ticks with 60 encounters and 120 migrated adapter dispatches without Vitals or health-bar divergence.
- Real Snake death now owns its idempotency guard; repeated death presentation grants money once in the project-scene fixture.
- Steve's remaining injury signal now delegates to the CombatAction/Vitals adapter rather than directly mutating HP.
- `Character/dengmao.gd` still owns a separate direct HP/damage model, so the all-enemy CombatAction/Vitals hard requirement is not yet evidenced.

## Next Vertical Slice

1. Migrate the dengmao boss HP and damage paths through CombatAction and Vitals.
2. Re-run the hard-gate audit and create the `combat-vertical-slice` tag only if every requirement has evidence.
