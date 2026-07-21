# Phase 01: Resource Closure and Repeatable Clean Import Design

**Status:** Approved
**Implements:** `docs/superpowers/specs/2026-07-21-phase-01-resource-closure-spec.md`
**Architecture constraints:** Master Design §15 test lanes and §17 release evidence

## 1. Existing code reused

| Existing path | Role |
|---|---|
| `project.godot` | Editor-plugin declaration source |
| `Data/` | Existing content JSON location and dynamic manifest home |
| `tests/` | Godot script-test conventions |
| `.worktrees/` | Ignored temporary clean-import workspace root |

## 2. Component boundaries

```text
tracked text resources + Data/resource_manifest.json
    -> scripts/resource_audit.ps1 -> RESOURCE_AUDIT_RESULT JSON
    -> tests/test_resource_audit.ps1 -> red/green process exit assertion
    -> temporary clean checkout -> Godot editor import -> log classifier
    -> tests/resource_scene_smoke.gd -> load/instance/four-frame report
```

The audit never writes into `res://`. Only temporary clean checkouts may receive Godot importer output. The manifest is data, not an executable path selector.

## 3. Target file map

| File | Change | Responsibility |
|---|---|---|
| `project.godot` | Modify | Remove only unavailable editor plugin declaration |
| `Data/resource_manifest.json` | Create | Enumerate dynamic resource roots/paths |
| `scripts/resource_audit.ps1` | Create | Static and dynamic path audit, JSON terminal result |
| `tests/test_resource_audit.ps1` | Create | Audit behavior fixtures and process assertions |
| `tests/resource_scene_smoke.gd` | Create | Scene load/instance/four-frame smoke runner |
| Phase 01 documents | Create | Contract, plan, and acceptance evidence |

## 4. Public API and events

`resource_audit.ps1 [-ProjectRoot <path>] [-ManifestPath <path>]` writes exactly one terminal line prefixed `RESOURCE_AUDIT_RESULT ` and exits 0 only if all arrays are empty. No Godot runtime API/event is introduced.

## 5. Data model

```json
{"schema_version":1,"images":[],"audio":[],"other":[]}
```

All arrays contain unique, canonical ASCII `res://` relative paths. Audit output uses sorted arrays of `{owner,path,code}` objects.

## 6. Sequencing and errors

`validate manifest -> enumerate supported files -> extract literal paths -> resolve exact path segments -> emit report -> scene smoke -> clean import twice`. Any static failure prevents scene/import work. A later failure does not modify project files.

## 7. Save/migration impact

None.

## 8. Security and trust boundary

The audit rejects paths outside `res://`, `..` segments, non-string JSON manifest values, and script-like manifest content. It never executes or imports user-supplied strings.

## 9. Performance budget

The audit is linear in tracked candidate text and referenced paths. It must complete in under 30 seconds on the Phase 00 baseline machine; scene/import timing is recorded, not assumed.

## 10. Test design

| Behavior | Test |
|---|---|
| Missing plugin fails | fixture project config points to missing plugin |
| Missing static path fails | fixture `.tscn` reference points to absent resource |
| Case mismatch fails | fixture directory has different path segment case |
| Invalid manifest fails | fixture has non-`res://` entry |
| Closed fixture passes | fixture references existing exact-case path |
| Project smoke | scene runner counts every `.tscn` and reports terminal JSON |

## 11. Rollout and rollback

The audit is additive. Remove the Phase commit to revert. No `.import` files are committed by default.

## 12. Alternatives considered

| Alternative | Decision |
|---|---|
| Use only Godot import logs | Reject: logs are cache-dependent and localized |
| Commit generated importer sidecars | Reject: only a separate mechanical audit may authorize it |
| Depend on TexturePacker plugin | Reject: it is absent and unpinned |

## 13. Self-review

Static closure, dynamic closure, scene smoke, and two clean imports have separate evidence paths; no Autoload, scene runtime ownership, or save state changes are introduced.

NO UNRESOLVED DECISIONS
