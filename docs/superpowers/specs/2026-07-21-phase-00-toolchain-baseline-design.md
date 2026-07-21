# Phase 00: Toolchain and Repository Baseline Design

**Status:** Approved
**Implements:** `docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-spec.md`
**Architecture constraints:** Master Design §1–2, §15 test lanes, §17 release evidence

## 1. Existing code reused

| Existing path/symbol | Reuse, adapt, or retire | Why |
|---|---|---|
| `project.godot` | Reuse read-only | Source of existing autoload inventory |
| `docs/superpowers/specs/2026-07-20-arch-input-record.md` | Reuse read-only | Records the architecture-input decision and original source hash |
| `.tools/godot-3.5.3/Godot_v3.5.3-stable_win64.exe` | Reuse, ignore | Pinned local editor; never stage it |
| `.gitignore` | Modify | Exclude local engine files, archives, and logs |

## 2. Component boundaries

```text
official Godot release URL ──download──> ignored .tools/ archive
                                      └─SHA-256─> tracked baseline manifest
project.godot + git metadata ──read──> tracked baseline manifest
Windows CIM + renderer policy ──read──> tracked performance provenance
arch.md SHA-256 + input record ──cross-check──> Phase 00 acceptance report
```

The two JSON files are evidence-only; they are never loaded by the game. The acceptance report owns the human-readable command results. `.tools/` owns local binaries and no tracked project state.

## 3. Target file map

| File | Create/Modify/Retire | Single responsibility |
|---|---|---|
| `.gitignore` | Modify | Keep local tooling out of Git |
| `docs/superpowers/baselines/phase-00-toolchain-baseline.json` | Create | Machine-readable engine, input, and project inventory pin |
| `docs/superpowers/baselines/phase-00-performance-provenance.json` | Create | Machine-readable Windows/performance-lane provenance |
| `docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-spec.md` | Create | Observable scope and acceptance contract |
| `docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-design.md` | Create | Boundary and verification design |
| `docs/superpowers/plans/2026-07-21-phase-00-toolchain-baseline-implementation.md` | Create | Executable small-step record |
| `docs/superpowers/reports/2026-07-21-phase-00-toolchain-baseline-acceptance.md` | Create | Evidence and rollback record |

## 4. Public API and events

None. Phase 00 adds no runtime API, event, autoload, or scene entry point.

## 5. Data model

`phase-00-toolchain-baseline.json` has `schema_version`, `baseline_commit`, `engine`, `export_templates`, `architecture_input`, `project_inventory`, and `workspace_policy` objects. `phase-00-performance-provenance.json` has `schema_version`, `captured_on`, `host`, and `test_lanes` objects. All source paths are explicit strings; all hashes are SHA-256 strings.

## 6. State machines and sequencing

`inspect -> pin editor -> acquire template -> hash artifacts -> write manifests -> validate manifests -> clean-checkout discovery -> accept -> commit`.

Each transition either leaves only ignored `.tools/` download state or adds a tracked evidence document. A hash mismatch terminates before acceptance; no runtime state is involved.

## 7. Happy-path data flow

PowerShell reads Git/Godot/CIM data, calculates hashes, and writes the two JSON manifests through a reviewed patch. Validation parses JSON and recalculates the same values. A temporary detached checkout is inspected without editor launch, then removed after its paths are proven.

## 8. Error handling

| Error code | Detection point | Rollback | Visible recovery |
|---|---|---|---|
| `P00_ENGINE_MISMATCH` | `--version` or SHA-256 check | None needed | Reacquire pinned editor |
| `P00_TEMPLATE_MISMATCH` | Template SHA-256 check | Delete only the explicit ignored archive and reacquire | Re-download official asset |
| `P00_INPUT_MISMATCH` | `Get-FileHash arch.md` | None | Review and intentionally regenerate architecture input record |
| `P00_MANIFEST_INVALID` | JSON parser | Revert only Phase 00 tracked files | Correct the evidence document |
| `P00_CLEAN_CHECKOUT_INVALID` | Existence checks | Remove explicit temporary checkout | Inspect checkout/commit selection |

## 9. Idempotency and concurrency

The template download targets one fixed ignored path; an existing complete archive is hashed instead of replaced. Tracked manifests are regenerated only from observed values in this Phase and use fixed schema keys. No concurrent game process or save mutation is permitted by Phase 00.

## 10. Save and migration impact

None. No save owner, schema, or content revision changes.

## 11. Security and trust boundary

- Engine artifacts come only from the official Godot release URL recorded in the manifest.
- Hashes are computed from local bytes after acquisition; an unverified template cannot satisfy release readiness.
- `arch.md` is treated as an external, read-only input; it cannot select executable paths or scripts.
- JSON manifests contain facts and URLs only, never executable commands from untrusted content.

## 12. Performance budget

Phase 00 performs no benchmark. It records the hardware and prohibits synthetic `--no-window`/`--fixed-fps` measurements from being used as release performance evidence.

## 13. Test design

| Case | Lane | Evidence |
|---|---|---|
| Editor pin | Toolchain | Exact `--version` string and SHA-256 |
| Export template pin | Toolchain | File size and SHA-256 |
| Input integrity | Static | `arch.md` hash equals record/manifest |
| Manifest format | Static | PowerShell `ConvertFrom-Json` success |
| Ignore policy | Git | `git check-ignore -q .tools` exit 0 |
| Clean checkout discovery | Git | Detached checkout has required paths |

## 14. Rollout and strangler steps

No runtime rollout. The `.tools/` ignore rule applies immediately; later phases inherit this baseline and must stage explicit paths.

## 15. Rollback

Revert the Phase 00 commit to restore the prior documentation and ignore policy. Ignored downloads can be removed only by targeting their exact file paths; game data remains untouched.

## 16. Alternatives considered

| Alternative | Benefit | Cost/risk | Decision |
|---|---|---|---|
| Commit engine/template archives | Offline convenience | Large binary history and accidental platform drift | Reject |
| Record only version strings | Short document | Cannot prove bytes used for export | Reject |
| Launch editor in clean checkout | Deeper import signal | Generates artifacts and exceeds Phase 00 scope | Reject |

## 17. Self-review

- Every Spec requirement maps to the manifest, provenance, ignore rule, or acceptance evidence.
- No new Autoload, runtime state, untrusted executable path, or Godot 4 API is introduced.
- All operations are bounded by exact local paths and hashes.
- No save/data migration exists in this Phase.

NO UNRESOLVED DECISIONS
