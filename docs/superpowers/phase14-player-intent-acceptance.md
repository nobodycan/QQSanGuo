# Phase 14 Player Intent Acceptance

## Scope Evidence

- `actors/PlayerIntent.gd` is the shared manual and automation command value.
- `actors/PlayerInputSampler.gd` samples the Godot input map and resolves any non-idle manual command ahead of automation.
- `actors/PlayerMovementModel.gd` owns direction, climbing, jump, and movement-lock decisions.
- `actors/PlayerAnimationAdapter.gd` maps movement decisions to the legacy `idle`, `run`, `jump`, and `clim` animation-tree states.
- `Character/Steve.gd` consumes resolved intents and model output; it no longer directly reads movement actions.

## Verification Evidence

- `tests/test_player_intent.gd` exercises manual interruption of automation, walking, climb exit jump, locking, animation selection, and 600 transition frames.
- The 600-frame loop asserts a temporary lock produces no movement and that the next unlocked frame moves again.
- The complete Godot runner is the final regression gate for Phase 14.
