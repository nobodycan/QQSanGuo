# Phase 15 PlayerStats Boundary Audit

## Accepted Authority Boundary

- Level progression, current XP, overflow XP, base stats, and level-derived stats are owned by `actors/PlayerStats.gd`.
- Steve grants XP through PlayerStats and mirrors the result to `PlayerInventory` only for legacy UI and gameplay compatibility.
- V2 envelopes normalize player v0 data to player section v1 before use.

## Deferred Legacy Boundary

- `PlayerInventory.gd` still mutates attributes while applying and removing equipment item properties.
- This is intentionally retained until Phase 23, which owns Equipment slots and Modifier recomputation. Moving it earlier would create a second incomplete equipment authority.
- New Phase 15 code must not introduce direct level-growth or XP-growth writes to `PlayerInventory`.

## Evidence

- `test_player_stats` covers all XP thresholds, multi-level behavior, the level cap, and repeated migration.
- `test_game_state_v2` covers player section migration inside V2 envelopes.
- The full runner passed after Steve was routed through PlayerStats.
