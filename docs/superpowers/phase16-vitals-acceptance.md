# Phase 16 Vitals Acceptance

- Vitals owns bounded HP/MP, alive state, recovery, revival, and idempotent death transitions.
- Legacy negative-damage and positive-recovery deltas are translated explicitly before state mutation.
- Steve routes its main healing and injury signal through Vitals while retaining legacy death presentation.
- Full Godot Gate passed all 19 tests after the Steve adapter change.

Checkpoint lookup and death-scene routing remain explicit integration work for the map/portal migration path; the current legacy scene transition is retained as an adapter rather than duplicated in Vitals.
