# Phase 17 Targeting Foundation

- Added stable actor IDs and faction-tagged target registration independent of scene node names.
- Added deterministic nearest-target selection with friendly filtering and actor-ID tie breaking.
- Target removal is explicit; the next selection observes no released target.
- Added a hit resolver that rejects friendly/self targets and consumes each stable hit ID at most once.

`test_target_registry` covers registration, faction filtering, deterministic ties, and target release. `test_hit_resolver` covers hostile, friendly, self, and duplicate-hit paths.
