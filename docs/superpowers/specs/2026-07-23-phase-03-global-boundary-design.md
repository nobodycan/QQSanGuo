# Phase 03 Design: Global Boundary

## Contracts

- `ContentRegistry`: read-only `get_entry`, `has_entry`, and `validate_id`; it initially returns structured `content_not_found` results.
- `EventBus`: owns named cross-domain signals and offers idempotent `subscribe`/`unsubscribe` wrappers keyed by emitter, signal, target, and method.
- `AudioManager`: owns `settings.cfg` access and exposes no-op-safe `set_bus_volume` and `play_bgm` entry points.
- Result dictionaries use `{ ok, operation_id, error_code, data }`; successful results use an empty `error_code`.

## Static Gate

`scripts/phase03_static_gate.ps1` scans runtime `.gd` files, excluding `tests/` and its own allowlist. `tests/phase03_legacy_baseline.json` stores the exact current legacy matches. A new match, direct `change_scene`, network API, process execution, unsafe dynamic load, or non-`user://` runtime write produces `TEST_RESULT` failure with a stable rule ID.

## Migration Rule

The legacy entries remain registered for compatibility, but new code may reference only the six target Autoloads. The ledger may shrink but must never grow.
