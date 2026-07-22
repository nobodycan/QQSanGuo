# Phase 21 Combat Gate Audit

## Available Foundations

- PlayerIntent, PlayerStats, Vitals, targeting, hit deduplication, damage, effects, CombatAction, SkillBook, EnemyBrain, and SpawnerScope each have focused regression coverage.
- Unit lane coverage currently validates their contracts independently.

## Gate Status: Not Yet Passed

- No runtime integration currently executes two skills against two EnemyDefinition-backed enemies through CombatAction.
- No fixed-seed encounter trace has been recorded.
- No 15-minute combat soak or migration of legacy Steve/Snake combat calls has been completed.

## Next Vertical Slice

1. Add two EnemyDefinition pilot records with different AI and combat signatures.
2. Add a deterministic combat scenario driver that joins SkillBook, TargetRegistry, CombatAction, Vitals, EnemyBrain, and SpawnerScope.
3. Use the scenario driver to prove the two-skill by two-enemy matrix before claiming the Combat Gate.
