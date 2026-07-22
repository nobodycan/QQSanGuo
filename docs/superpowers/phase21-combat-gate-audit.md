# Phase 21 Combat Gate Audit

## Available Foundations

- PlayerIntent, PlayerStats, Vitals, targeting, hit deduplication, damage, effects, CombatAction, SkillBook, EnemyBrain, and SpawnerScope each have focused regression coverage.
- Unit lane coverage currently validates their contracts independently.

## Gate Status: Not Yet Passed

- A deterministic two-skill by two-enemy CombatAction matrix now passes in the integration lane.
- No fixed-seed encounter trace has been recorded.
- No 15-minute combat soak or migration of legacy Steve/Snake combat calls has been completed.

## Next Vertical Slice

1. Add a fixed-seed encounter trace that includes targeting, EnemyBrain, and SpawnerScope.
2. Run the long-duration combat soak and migrate legacy Steve/Snake combat calls.
