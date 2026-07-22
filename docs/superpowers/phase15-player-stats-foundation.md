# Phase 15 PlayerStats Foundation

## Implemented

- Added versioned player section v1 with level, current experience, capped overflow experience, base attributes, and derived attributes.
- Added an explicit 1–30 XP table and a deterministic multi-level grant operation.
- Added a level-30 hard cap: no operation can produce level 31; post-cap XP is retained as overflow.
- Added a compatibility adapter that mirrors derived values into legacy `PlayerInventory`.
- Updated V2 envelopes to declare player section version 1 and provide a normalized default player state.
- Added idempotent player section v0-to-v1 migration, including the legacy `exprience` spelling.
- Routed Steve experience grants through PlayerStats and mirrored resulting derived stats into legacy PlayerInventory for compatibility.

## Verification

- `test_player_stats` verifies N-1/N/N+1 XP behavior for every level, cumulative multi-level progression, the level cap, overflow XP, normalization, and repeated v0-to-v1 migration.
- `test_game_state_v2` verifies player v0 upgrade, repeat normalization, and PlayerStats v1 persistence inside a V2 envelope.
