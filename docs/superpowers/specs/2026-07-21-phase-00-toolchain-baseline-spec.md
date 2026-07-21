# Phase 00: Toolchain and Repository Baseline Spec

**Status:** Approved
**Owner:** nobodycan
**Depends on:** None
**Master requirements:** NFR-01, NFR-02, NFR-03, NFR-04, NFR-05, NFR-06
**Supersedes:** None

## 1. Outcome

Every later Phase can reproduce the same Godot 3.5.3 toolchain, identify the exact input architecture, distinguish pre-existing failures from regressions, and avoid committing local engine artifacts.

## 2. Problem and evidence

- The repository uses Godot 3.5.3, but the editor binary and export templates were not both recorded in tracked project documentation.
- `.tools/` contains a local Godot archive, executable, and test logs but was not ignored by `.gitignore`.
- The working tree already contains thousands of generated or user-owned differences; Phase work must not stage them.
- `D:\AI4coding\QQSanGuo\arch.md` is an external architecture input. Its SHA-256 must remain tied to the approved architecture input record.
- Later resource, save, and gameplay phases need a fixed inventory of the existing project before they can prove deltas.

## 3. User flows

1. A developer opens the baseline manifest, obtains the pinned Windows editor and export-template identifiers, and verifies local SHA-256 values before running Godot.
2. A developer starts a Phase, compares repository HEAD, input hash, content counts, and dirty-worktree policy with this baseline, then runs the specified test lane.
3. If a local executable, template archive, test log, `.import` product, or unrelated scene changes, Git leaves it unstaged unless the Phase explicitly owns it.

## 4. In scope

- Pin the Godot 3.5.3 Windows x86_64 editor and the matching non-.NET export templates by version, source URL, size, and SHA-256.
- Record repository identity, existing content counts, 13 legacy autoload entries, and the `arch.md` SHA-256.
- Record the Windows hardware, GPU driver, display, renderer policy, and performance-lane constraints.
- Add a repository ignore rule for `.tools/` and create machine-readable baseline/provenance artifacts.
- Verify a temporary clean checkout contains the project without claiming that all resources import cleanly.

## 5. Out of scope

- Repairing broken resources or changing `.tscn`, `.tres`, `.import`, or gameplay code; those start in Phase 01 and later.
- Replacing the 13 legacy autoloads; this begins in Phase 03.
- Establishing a passing full test suite; Phase 02 owns test classification and cleanup.

## 6. Functional requirements

### P00-FR-01 Reproducible engine pin

- Given a fresh Windows workstation, when it reads the baseline manifest, then it can verify the exact Godot editor and export-template archive with SHA-256 and source URL.
- A missing or mismatched local artifact is a hard failure for release/export work; it must not silently substitute another Godot version.

### P00-FR-02 Immutable architecture input

- Given `D:\AI4coding\QQSanGuo\arch.md`, when its SHA-256 differs from `arch-input-record.md` or the baseline manifest, then Phase execution stops before consuming the changed input.

### P00-FR-03 Baseline inventory

- Given the tracked gameplay project at baseline HEAD, when the inventory command runs, then it reports 75 scenes, 73 GDScript files, 3 JSON files under `Data/`, 8 `.tres` files, and 13 autoload entries.

### P00-FR-04 Dirty-worktree protection

- Given a local tool or generated Godot artifact, when Git status runs, then `.tools/` is ignored and Phase commits use explicit paths only.

### P00-FR-05 Test-lane contract

- Deterministic/resource tests use Godot 3.5.3 with `--no-window --audio-driver Dummy`; add `--fixed-fps 60` only when frame determinism is required.
- Performance evidence uses a visible Windows Release build with real time, real rendering driver, and neither `--no-window` nor `--fixed-fps`.

### P00-FR-06 Clean-checkout discovery

- Given a detached temporary checkout of baseline HEAD, when checked without launching the editor, then `project.godot` and the baseline document paths exist.

## 7. Data and content contract

- `docs/superpowers/baselines/phase-00-toolchain-baseline.json` is UTF-8 JSON with version `1`, source URLs, SHA-256 hashes, baseline commit, content counts, and dirty-worktree policy.
- `docs/superpowers/baselines/phase-00-performance-provenance.json` is UTF-8 JSON with version `1`, Windows/CPU/GPU/RAM/display facts and lane policy.
- SHA-256 is uppercase hexadecimal with 64 characters. Stable IDs and paths are ASCII except recorded Windows display strings.

## 8. Failure modes

| Failure | Expected result | User sees | State mutation allowed |
|---|---|---|---|
| Editor/version hash mismatch | Fail the verification command | Exact expected and actual values | None |
| Export templates absent | Download only the pinned official asset, then verify its hash | Download status and pinned path | `.tools/` only |
| `arch.md` hash mismatch | Stop Phase execution | Input integrity failure | None |
| Existing dirty files | Preserve and exclude from stage | Explicit excluded-path policy | None |
| Temporary checkout lacks project file | Fail clean-checkout test | Missing path | Temporary checkout only |

## 9. Acceptance criteria

- `Godot_v3.5.3-stable_win64.exe --version` returns exactly `3.5.3.stable.official.6c814135b` with exit code 0.
- The editor and export template archive hashes in the manifest equal freshly calculated SHA-256 values.
- The architecture input hash is `8731C8420DC4898D3F23F5CC5D2174BE3F45F3313C846594B30593DBB409F397`.
- `.tools` is ignored by `git check-ignore -q .tools` with exit code 0.
- Both JSON artifacts parse successfully and the clean detached checkout contains `project.godot` and all four Phase 00 documents.

## 10. Evidence required

- Exact PowerShell commands and captured exit results in the acceptance report.
- SHA-256 output for both local engine artifacts and `arch.md`.
- A clean-checkout path and discovery result.
- Explicit list of Phase-owned paths staged for the commit.

## 11. Rollback and compatibility

- Rollback point: `db2daee15d3cf49e097e48633ab555b90848902b` before Phase 00 implementation.
- The only tracked behavior change is ignoring `.tools/`; it does not alter Godot scenes, saves, content, or runtime APIs.
- Phase 01 may change the inventory after recording a new acceptance delta, never by overwriting this immutable baseline.

## 12. Decisions

| ID | Decision | Reason | Rejected alternative |
|---|---|---|---|
| P00-D-01 | Pin standard (non-.NET) Godot 3.5.3 assets | The project uses GDScript and the current Windows editor is standard | Silently using the latest Godot or .NET build |
| P00-D-02 | Keep engine artifacts in ignored `.tools/` | Keeps local binaries reproducible without bloating history | Committing executable/template archives |
| P00-D-03 | Treat existing test errors as baseline evidence, not a Phase 00 pass claim | Phase 02 owns classified test reliability | Hiding or deleting pre-existing diagnostics |

NO UNRESOLVED DECISIONS
