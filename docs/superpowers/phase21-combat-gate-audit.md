# Phase 21 Combat Gate Audit

## Available Foundations

- PlayerIntent, PlayerStats, Vitals, targeting, hit deduplication, damage, effects, CombatAction, SkillBook, EnemyBrain, and SpawnerScope each have focused regression coverage.
- Unit lane coverage currently validates their contracts independently.

## Gate Status: Not Yet Passed

- A deterministic two-skill by two-enemy CombatAction matrix now passes in the integration lane.
- A fixed-seed 12-tick encounter trace now exercises TargetRegistry selection, EnemyBrain transitions, and SpawnerScope ownership; it reproduces for the same seed and differs for the two pilot AI roles.
- No 15-minute combat soak or migration of legacy Steve/Snake combat calls has been completed.

## Next Vertical Slice

1. Run the long-duration combat soak and record null-target, persistent-effect, duplicate-death, and duplicate-reward assertions.
2. Migrate legacy Steve/Snake combat calls through CombatAction, DamagePipeline, and Vitals, then measure remaining adapter call sites.
