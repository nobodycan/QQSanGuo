# Phase 18 Damage Foundation

- Added pure DamagePipeline calculation with explicit multiplier, critical, defense, and non-negative clamp order.
- Rejects negative inputs and non-finite multipliers before resolution.
- Phase 17 HitResolver remains responsible for stable hit-ID deduplication.
- Added deterministic effect state stacking, refresh, tick power, and expiry removal.
- Added CombatAction as the single pure entry that composes hit validation, damage calculation, and Vitals mutation.

`test_damage_pipeline` covers normal, critical, defense floor, invalid input, and non-finite numeric boundaries. `test_effect_state` covers stacking, refresh, tick, and expiry.

`test_combat_action` proves one action resolves into Vitals once and that repeat action IDs cannot produce a second defeat.
