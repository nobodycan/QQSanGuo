# Phase 03 Spec: Global Boundary

## Goal

Freeze the six permitted runtime Autoloads: `GameState`, `SaveManager`, `SceneManager`, `ContentRegistry`, `EventBus`, and `AudioManager`. New runtime code must not add legacy global references or direct scene changes.

## Scope

- Add the three missing Autoload shells and their stable public methods.
- Return structured results with ASCII `ok`, `error_code`, and `operation_id` fields.
- Add a static gate for new legacy Autoload references, `SceneTree.change_scene()`, unsafe execution/network APIs, and runtime writes outside `user://`.
- Baseline existing legacy hits in a versioned ledger; the gate permits baseline hits only and rejects additions.

## Acceptance

- `project.godot` registers exactly the six target Autoloads in addition to legacy entries.
- EventBus duplicate connections do not produce duplicate events.
- A fixture for each forbidden pattern fails the static gate.
- Existing repository baseline passes; an added legacy reference fails with a precise rule identifier.

## Non-goals

- Migrating all legacy callers, replacing scene loading, or introducing ContentRegistry data packs. Those belong to later phases.
