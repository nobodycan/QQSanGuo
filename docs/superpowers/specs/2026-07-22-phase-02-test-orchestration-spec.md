# Phase 02: Test Orchestration and Structured Diagnostics Spec

**Status:** Implemented
**Depends on:** Phase 01
**Covers:** NFR-01, NFR-04, NFR-06

## Outcome

A test command reports a terminal JSON result, isolates `user://` state per process, times out stalled tests, and rejects false-green diagnostic logs.

## Requirements

- `scripts/test_runner.ps1` is the single PowerShell entry point and reads `tests/test_manifest.json`.
- Tests are classified as `unit`, `integration`, `resource`, `scene`, `e2e`, or `soak`; the runner accepts a lane filter.
- Every executed test emits exactly one terminal `TEST_RESULT {json}` object with ASCII `test_id` and Boolean `ok`.
- The runner captures UTF-8 stdout/stderr, writes JSON and JUnit reports, and fails on a missing terminal protocol, nonzero exit, `ok:false`, timeout, or unclassified `ERROR:`, `SCRIPT ERROR:`, `Parser Error`, or missing-resource diagnostic.
- Every child process receives a unique temporary `APPDATA` and `LOCALAPPDATA` root.
- Functional Godot lanes use `--fixed-fps 60`; performance testing is deliberately out of scope and must not reuse this lane.
- Existing smoke, save, scene, resource, and item tests use `TestProtocol.gd` or a PowerShell `TEST_RESULT` terminal line rather than bare `assert`.

## Acceptance

- Runner self-tests classify pass, explicit failure, timeout, and log-error correctly.
- The resource lane emits a JSON and JUnit report.
- Missing Godot is a blocking tool status, never a passing result.

## Out of Scope

Godot installation, performance benchmarks, new gameplay behavior, and Phase 03 static architecture gates.
