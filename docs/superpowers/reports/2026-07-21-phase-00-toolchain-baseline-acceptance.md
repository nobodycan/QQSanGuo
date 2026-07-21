# Phase 00: Toolchain and Repository Baseline Acceptance Report

**Spec:** `docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-spec.md` (working change, committed with this report)
**Design:** `docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-design.md` (working change, committed with this report)
**Plan:** `docs/superpowers/plans/2026-07-21-phase-00-toolchain-baseline-implementation.md` (working change, committed with this report)
**Implementation range:** `db2daee15d3cf49e097e48633ab555b90848902b`..Phase 00 commit
**Godot:** `3.5.3.stable.official.6c814135b`
**Result:** PASS

## 1. Delivered scope

| Requirement | Delivered evidence | Implementation commit |
|---|---|---|
| P00-FR-01 | `phase-00-toolchain-baseline.json` pins editor and template bytes | Phase 00 commit |
| P00-FR-02 | `arch.md` SHA-256 matches the input record and manifest | Phase 00 commit |
| P00-FR-03 | Manifest records 75 scenes, 73 scripts, 3 `Data/` JSON files, 8 `.tres`, 13 autoloads | Phase 00 commit |
| P00-FR-04 | `.tools/` is ignored; explicit staging policy recorded | Phase 00 commit |
| P00-FR-05 | Performance provenance separates deterministic/resource and release lanes | Phase 00 commit |
| P00-FR-06 | Detached clean-checkout discovery completed without editor launch | Phase 00 commit |

## 2. Automated evidence

| Command | Exit | TEST_RESULT | Unclassified errors | Artifact |
|---|---:|---|---:|---|
| `Godot_v3.5.3-stable_win64.exe --version` | 0 | Exact `3.5.3.stable.official.6c814135b` | 0 | Toolchain manifest |
| `Get-FileHash` editor/template/arch input | 0 | Three hashes equal manifest/record values | 0 | Toolchain manifest |
| `ConvertFrom-Json` for both baseline artifacts | 0 | Parsed | 0 | Both JSON artifacts |
| `git check-ignore -q .tools` | 0 | Ignored | 0 | `.gitignore` |
| Detached checkout path checks | 0 | `project.godot` and architecture input record present | 0 | Clean-checkout evidence below |
| `git diff --check` on Phase-owned files | 0 | No whitespace errors | 0 | Git evidence below |

## 3. Manual evidence

- The existing deterministic test output identifies `OpenGL ES 3.0 Renderer: Intel(R) Iris(R) Xe Graphics`; its source is recorded in `phase-00-performance-provenance.json`.
- No visual/audio claim is made. Phase 39 must run visible release performance and manual visual/audio lanes.

## 4. Migration evidence

Not applicable: Phase 00 does not change saves, schemas, or content revisions.

## 5. Performance and leak evidence

- Host provenance: Windows 11 build 26200, Intel i7-1165G7 (4C/8T), 15.8 GiB RAM, Intel Iris Xe driver 30.0.100.9864, 2560x1440 display.
- This Phase records measurement rules only. It does not claim a performance pass, leak pass, frame rate, or release build benchmark.

## 6. Static gates

- Autoload baseline: 13 entries in `project.godot`; Phase 03 owns reduction to the six approved Autoloads.
- Runtime scans are intentionally deferred; Phase 00 adds no GDScript, scene, resource, `change_scene`, or stable-ID behavior.

## 7. Git and workspace hygiene

- Intentional tracked files: `.gitignore`, two baseline JSON files, Phase 00 Spec, Design, Plan, and this Acceptance Report.
- Excluded: all `.tools/` artifacts, pre-existing `.import` output, and pre-existing scene/resource differences.
- The downloaded 575,689,292-byte template archive remains in ignored `.tools/`; no binary is staged.

## 8. Known warnings

| Warning | Owner | Reason | Target Phase |
|---|---|---|---|
| Existing Godot test logs contain expected corrupt-save diagnostics and resource/leak diagnostics | Phase 02 | Phase 00 records baseline only; tests are not yet classifier-clean | Phase 02 |
| VSync state is not set in `project.godot` | Phase 39 | Release environment must record real display/vsync setting | Phase 39 |

## 9. Rollback point

- Pre-Phase rollback: `db2daee15d3cf49e097e48633ab555b90848902b`.
- Reverting the Phase 00 commit changes only evidence documents and the `.tools/` ignore boundary; save and game-content compatibility are unaffected.

## 10. Final checklist

- [x] Spec fully covered
- [x] All Phase 00 verification commands pass
- [x] No unclassified Phase 00 command errors
- [x] Migration/repeated apply/atomicity is not applicable
- [x] Documentation and implementation agree
- [x] Working tree staging contains only intentional Phase-owned files
