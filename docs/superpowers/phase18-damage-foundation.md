# Phase 18 Damage Foundation

- Added pure DamagePipeline calculation with explicit multiplier, critical, defense, and non-negative clamp order.
- Rejects negative inputs and non-finite multipliers before resolution.
- Phase 17 HitResolver remains responsible for stable hit-ID deduplication.

`test_damage_pipeline` covers normal, critical, defense floor, invalid input, and non-finite numeric boundaries.
