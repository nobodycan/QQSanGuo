# Phase 20 EnemyBrain Foundation

- Added pure enemy AI states for idle, chase, attack, return, and dead.
- State decisions depend on target validity, distance, aggro range, attack range, and alive state.
- The 10,000 tick regression validates state-machine closure under repeated target loss and death transitions.
