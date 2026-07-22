# Phase 14 Player Intent Foundation

## Implemented

- Added a pure `PlayerIntent` command value for horizontal movement, vertical movement, and jump input.
- Added `PlayerInputSampler`, which gives any non-idle manual intent priority over an automation intent.
- Added a pure `PlayerMovementModel` for deterministic movement-lock and climbing/jump state decisions.
- Added `PlayerAnimationAdapter` to translate movement state into the legacy idle, run, jump, and climb animation-tree names.
- Updated the legacy `Steve.gd` adapter to consume resolved intents and `PlayerMovementModel` state rather than reading movement actions directly.

## Compatibility

- Existing Godot physics, collision, animation-tree, combat chase, and UI behavior remain owned by `Steve.gd`.
- `set_automation_intent()` is an opt-in bridge for the future auto-combat controller; manual input interrupts it in the same physics frame.

## Verification

- `test_player_intent` covers automation while manual input is idle, manual interruption, walking state, climb exit jump, and movement locking.
- The full test runner remains the Phase 14 regression gate.
