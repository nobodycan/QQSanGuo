# Phase 01: Resource Closure and Repeatable Clean Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make static/dynamic resource closure and clean import reproducible without committing generated import artifacts.

**Architecture:** A PowerShell audit validates only trusted project files and a typed JSON manifest before Godot receives a clean checkout. A GDScript smoke runner loads every scene after static closure. The stale editor plugin is removed as an independent configuration correction.

**Tech Stack:** Godot 3.5.3, GDScript, PowerShell 5+, JSON

---

### Task 1: Make the resource audit testable

**Files:**
- Create: `tests/test_resource_audit.ps1`
- Create: `scripts/resource_audit.ps1`

- [x] Write fixture-based tests for missing plugin, missing path, case mismatch, invalid manifest, UTF-8, spaces, directory prefixes, comments, and closed fixtures.
- [x] Run `powershell -ExecutionPolicy Bypass -File tests/test_resource_audit.ps1` and verify it fails because `scripts/resource_audit.ps1` is absent.
- [x] Implement the smallest audit API described in the Design.
- [x] Re-run the test and require `TEST_RESOURCE_AUDIT_PASS` with exit 0.

### Task 2: Add the manifest and remove only the stale plugin

**Files:**
- Modify: `project.godot:51-53`
- Create: `Data/resource_manifest.json`

- [x] Add an initially empty, schema-versioned manifest and a test that validates it.
- [x] Remove the only enabled missing plugin declaration.
- [x] Run the audit against the project and fix every reported production reference with a separate red/green test where required.

### Task 3: Smoke scenes and clean imports

**Files:**
- Create: `tests/resource_scene_smoke.gd`
- Create: `docs/superpowers/reports/2026-07-21-phase-01-resource-closure-acceptance.md`

- [x] Write a runner that returns a JSON terminal result and fails on any scene load/instance error after two idle and two physics frames.
- [x] Run it with Godot 3.5.3 `--no-window --audio-driver Dummy --fixed-fps 60`.
- [x] Create two explicit temporary detached checkouts, run `--editor --no-window --audio-driver Dummy --quit`, classify logs, and remove only those verified temporary worktrees.
- [x] Run static validation, stage exact Phase paths, commit, and record evidence.

## Plan self-review

- P01-FR-01 through P01-FR-05 map to Tasks 1 through 3.
- There are no unresolved placeholders or public runtime API names beyond the documented audit command.
