# Phase 21 Combat Gate Audit

## Available Foundations

- PlayerIntent, PlayerStats, Vitals, targeting, hit deduplication, damage, effects, CombatAction, SkillBook, EnemyBrain, and SpawnerScope each have focused regression coverage.
- Unit lane coverage currently validates their contracts independently.

## Gate Status: Not Yet Passed

- A deterministic two-skill by two-enemy CombatAction matrix now passes in the integration lane.
- A fixed-seed 12-tick encounter trace now exercises TargetRegistry selection, EnemyBrain transitions, and SpawnerScope ownership; it reproduces for the same seed and differs for the two pilot AI roles.
- A 54,000-tick (15-minute at 60 Hz) soak now validates target continuity, temporary-effect expiry, idempotent defeat handling, and one reward per encounter.
- Migration of legacy Steve/Snake combat calls has not been completed.

## Next Vertical Slice

1. Migrate legacy Steve/Snake combat calls through CombatAction, DamagePipeline, and Vitals, then measure remaining adapter call sites.
2. Re-run the soak against the migrated scene adapters and publish the Combat Acceptance Report.
