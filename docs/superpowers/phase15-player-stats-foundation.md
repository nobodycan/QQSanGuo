# Phase 15 PlayerStats Foundation

## Implemented

- Added versioned player section v1 with level, current experience, capped overflow experience, base attributes, and derived attributes.
- Added an explicit 1–30 XP table and a deterministic multi-level grant operation.
- Added a level-30 hard cap: no operation can produce level 31; post-cap XP is retained as overflow.
- Added a compatibility adapter that mirrors derived values into legacy `PlayerInventory`.
- Updated V2 envelopes to declare player section version 1 and provide a normalized default player state.

## Verification

- `test_player_stats` verifies N-1/N/N+1 XP behavior for every level, cumulative multi-level progression, the level cap, overflow XP, and normalization.
