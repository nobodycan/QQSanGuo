# Phase 01: Resource Closure and Repeatable Clean Import Spec

**Status:** Approved
**Owner:** nobodycan
**Depends on:** Phase 00
**Master requirements:** NFR-01, NFR-02, NFR-04
**Supersedes:** None

## 1. Outcome

A clean detached checkout can import the project with Godot 3.5.3 without a missing plugin, Parser Error, missing resource, or unresolved static/dynamic resource reference.

## 2. Problem and evidence

- `project.godot:51-53` enables `codeandweb.texturepacker`, but `addons/` does not exist.
- Existing `.import` files can conceal missing source resources and platform-case errors.
- Scenes and scripts contain many `res://` paths; there is no deterministic report that proves all referenced files are present with exact case.

## 3. User flows

1. A developer runs the resource audit from the repository root and receives one JSON report with every scanned path, missing path, case mismatch, and parser candidate.
2. A developer runs it after changing a scene or dynamic resource manifest; any missing or case-mismatched resource exits nonzero before a Godot import is attempted.
3. CI or a release worker creates a temporary clean checkout, imports it with the pinned Godot editor, reruns the audit, and receives a zero-error terminal result.

## 4. In scope

- Remove the unavailable TexturePacker editor plugin declaration.
- Add a PowerShell resource audit for `.gd`, `.tscn`, `.tres`, and JSON dynamic-resource manifest entries.
- Check `res://` references exist and have case-exact Windows paths by resolving each segment from directory entries.
- Add a dynamic resource manifest for runtime-loaded image/audio files.
- Instantiate all loadable scenes in a test harness for two idle and two physics frames after static closure succeeds.
- Verify first and second clean-checkout imports without claiming unrelated user-worktree changes as Phase output.

## 5. Out of scope

- Gameplay architecture, scene migration, test orchestration, save behavior, and removal of legacy `change_scene` calls.
- Broadly regenerating or committing tracked `.import` sidecars; any importer mechanical update requires a separate explicitly scoped commit.

## 6. Functional requirements

### P01-FR-01 Missing-plugin removal

Given the tracked project configuration, when Godot opens the editor, then no enabled editor plugin lacks its repository directory.

### P01-FR-02 Static resource closure

Given every tracked `.gd`, `.tscn`, and `.tres` file, when the audit extracts literal `res://` paths, then each path exists, uses exact path case, and is reported once in canonical sort order.

### P01-FR-03 Dynamic resource closure

Given the tracked dynamic resource manifest, when the audit runs, then each declared image/audio resource exists with exact case; an invalid manifest entry is a hard failure.

### P01-FR-04 Scene-load smoke

Given a statically closed resource set, when every `.tscn` is loaded and instantiated, then each scene reaches two idle and two physics frames without Parser Error, missing resource, or missing plugin diagnostics.

### P01-FR-05 Repeatable clean import

Given two fresh detached checkouts at the same commit, when each runs Godot 3.5.3 `--editor --no-window --audio-driver Dummy --quit`, then both commands exit 0 and their classified logs contain zero Parser Error, missing resource, or missing plugin lines.

## 7. Data and content contract

- `Data/resource_manifest.json` has schema version `1` and arrays `images`, `audio`, and `other`; every value is a unique, canonical UTF-8 `res://` string. JSON `\\uXXXX` escapes are permitted for repository paths containing non-ASCII characters.
- `scripts/resource_audit.ps1` emits one JSON object to stdout: `RESOURCE_AUDIT_RESULT` with `ok`, counts, `missing`, `case_mismatch`, `invalid_manifest`, and `references` fields.
- Error identifiers are ASCII: `missing_resource`, `case_mismatch`, `invalid_manifest`, `missing_plugin`.

## 8. Failure modes

| Failure | Expected result | User sees | State mutation allowed |
|---|---|---|---|
| Plugin enabled but directory absent | Audit fails before import | `missing_plugin` | None |
| Literal path absent | Audit exits 1 | `missing_resource` and owner file | None |
| Case mismatch | Audit exits 1 | `case_mismatch` and segment | None |
| Invalid manifest | Audit exits 1 | `invalid_manifest` | None |
| Scene import/load diagnostic | Smoke test exits 1 | classified log line and scene path | Temporary checkout only |

## 9. Acceptance criteria

- Resource audit returns exit 0, `ok:true`, empty failure arrays, and deterministic path ordering.
- The enabled TexturePacker plugin declaration is absent.
- All scenes load/instance through the required four frames with no classified resource/parser/plugin diagnostic.
- Two clean import runs are individually exit 0 and produce no unclassified Phase 01 errors.
- The Phase commit stages no `.import` file unless the acceptance report names an explicitly reviewed mechanical importer delta.

## 10. Evidence required

- Red/green output for the audit tests.
- JSON audit report and dynamic manifest validation result.
- Two clean-checkout command logs and before/after Git diffs.
- Scene smoke result with scene count and error classifier output.

## 11. Rollback and compatibility

Rollback is the pre-Phase commit. Removing a stale editor-plugin declaration does not alter runtime resources. The audit and manifest are additive; no save format or scene runtime API changes occur.

## 12. Decisions

| ID | Decision | Reason | Rejected alternative |
|---|---|---|---|
| P01-D-01 | Remove stale plugin declaration | Plugin files are absent and the project has no dependency on its editor UI | Reintroduce an unpinned third-party plugin |
| P01-D-02 | Audit paths before Godot import | Produces actionable exact failures rather than cache-dependent editor logs | Trusting `.import` cache |
| P01-D-03 | Keep audit report machine-readable JSON | Phase 02 can consume it without parsing localized console text | Human-only checklist |

NO UNRESOLVED DECISIONS
