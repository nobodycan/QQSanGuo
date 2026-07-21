# Phase 00: Toolchain and Repository Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reproducible, verified Godot 3.5.3 and repository baseline without altering runtime game content.

**Architecture:** Read existing Git, Godot, and Windows facts into two tracked JSON evidence files; keep engine binaries/templates under the ignored `.tools/` boundary. Cross-check the external architecture input by SHA-256 and prove a clean checkout can discover the project without triggering imports.

**Tech Stack:** Godot 3.5.3, GDScript, PowerShell test orchestrator

---

## File structure

- `.gitignore` — ignores local engine/tool artifacts.
- `docs/superpowers/baselines/phase-00-toolchain-baseline.json` — toolchain/input/inventory facts.
- `docs/superpowers/baselines/phase-00-performance-provenance.json` — hardware and lane policy facts.
- Phase 00 Spec, Design, and Acceptance Report — contract and evidence.

### Task 1: Pin and isolate the local toolchain

**Files:**
- Modify: `.gitignore`
- Create: `docs/superpowers/baselines/phase-00-toolchain-baseline.json`

- [x] **Step 1: Inspect the current editor and the matching official release asset**

Run from `D:\AI4coding\QQSanGuo\.worktrees\game-state-save`:

```powershell
& .\.tools\godot-3.5.3\Godot_v3.5.3-stable_win64.exe --version
Invoke-RestMethod -Uri https://api.github.com/repos/godotengine/godot-builds/releases/tags/3.5.3-stable
```

Expected: exit 0, editor string `3.5.3.stable.official.6c814135b`, and asset `Godot_v3.5.3-stable_export_templates.tpz`.

- [x] **Step 2: Add the minimal ignore boundary**

Add exactly:

```gitignore
# Local engine binaries, export templates, and test logs.
.tools/
```

- [x] **Step 3: Acquire only the pinned template archive into `.tools/` and calculate both SHA-256 hashes**

Run:

```powershell
Get-FileHash .\.tools\godot-3.5.3\Godot_v3.5.3-stable_win64.exe -Algorithm SHA256
Get-FileHash .\.tools\Godot_v3.5.3-stable_export_templates.tpz -Algorithm SHA256
```

Expected: each command exits 0 and produces one 64-character SHA-256 hash.

- [x] **Step 4: Write the exact baseline JSON, parse it, and prove `.tools` is ignored**

Run:

```powershell
Get-Content -Raw docs\superpowers\baselines\phase-00-toolchain-baseline.json | ConvertFrom-Json | Out-Null
git check-ignore -q .tools
```

Expected: both commands exit 0.

### Task 2: Capture immutable input and performance provenance

**Files:**
- Create: `docs/superpowers/baselines/phase-00-performance-provenance.json`
- Create: `docs/superpowers/reports/2026-07-21-phase-00-toolchain-baseline-acceptance.md`

- [x] **Step 1: Calculate input hash and read project inventory/hardware facts**

Run:

```powershell
Get-FileHash ..\..\arch.md -Algorithm SHA256
rg --files -g '*.tscn' | Measure-Object
Get-CimInstance Win32_Processor,Win32_VideoController,Win32_ComputerSystem,Win32_OperatingSystem
```

Expected: the input hash equals `8731C8420DC4898D3F23F5CC5D2174BE3F45F3313C846594B30593DBB409F397`; inventory is 75 scenes, 73 GDScript files, 3 JSON files under `Data/`, 8 `.tres` files, and 13 autoload entries.

- [x] **Step 2: Write provenance and acceptance evidence using exact observed values**

Expected: JSON parses; acceptance document identifies baseline limitations rather than claiming a clean resource/test state.

### Task 3: Verify clean discovery and commit exact files

**Files:**
- Modify: the seven Phase 00 files listed above

- [x] **Step 1: Add a detached temporary checkout at baseline HEAD and verify paths without editor launch**

Run:

```powershell
git worktree add --detach <validated-temp-path> db2daee15d3cf49e097e48633ab555b90848902b
Test-Path <validated-temp-path>\project.godot
Test-Path <validated-temp-path>\docs\superpowers\specs\2026-07-20-arch-input-record.md
```

Expected: all path checks return `True`; cleanup targets only that explicit temporary worktree.

- [x] **Step 2: Run static validation and stage only Phase-owned paths**

Run:

```powershell
git diff --check -- .gitignore docs/superpowers
Get-Content -Raw docs\superpowers\baselines\phase-00-toolchain-baseline.json | ConvertFrom-Json | Out-Null
Get-Content -Raw docs\superpowers\baselines\phase-00-performance-provenance.json | ConvertFrom-Json | Out-Null
git add .gitignore docs/superpowers/baselines/phase-00-toolchain-baseline.json docs/superpowers/baselines/phase-00-performance-provenance.json docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-spec.md docs/superpowers/specs/2026-07-21-phase-00-toolchain-baseline-design.md docs/superpowers/plans/2026-07-21-phase-00-toolchain-baseline-implementation.md docs/superpowers/reports/2026-07-21-phase-00-toolchain-baseline-acceptance.md
```

Expected: all validation commands exit 0 and no `.import`, `.tscn`, `.tres`, or `.tools` file is staged.

- [x] **Step 3: Commit the exact evidence set**

```powershell
git commit -m "docs: establish Phase 00 toolchain baseline"
```

Expected: one commit containing only the seven exact Phase-owned files.

## Plan self-review

- Spec coverage: P00-FR-01 through P00-FR-06 map respectively to Tasks 1, 2, and 3.
- Placeholder scan: no unresolved decision, TODO, or deferred implementation marker exists.
- Signature consistency: Phase 00 has no public runtime APIs.
