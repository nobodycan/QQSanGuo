# Phase 02: Test Orchestration and Structured Diagnostics Design

**Implements:** `2026-07-22-phase-02-test-orchestration-spec.md`

## Flow

`test_manifest.json` selects a test and watchdog -> `test_runner.ps1` creates an isolated home -> child stdout/stderr are captured as UTF-8 -> terminal protocol and diagnostics are classified -> `test-report.json` and `junit.xml` are written.

`TestProtocol.gd` owns GDScript expectation collection and emits one terminal object before `SceneTree.quit()`. PowerShell tests emit the identical prefix directly.

## Failure Semantics

`passed` requires exit 0, one parseable `TEST_RESULT`, `ok:true`, and no forbidden diagnostic. `failed`, `timeout`, `log_error`, `protocol_error`, and `blocked_tool_missing` all make the report unsuccessful. Reports retain stdout/stderr file names for diagnosis.

## Data and Safety

The manifest is versioned (`schema_version: 1`). Test state is isolated below the OS temporary directory and removed after each completed child. Reports are generated under ignored `artifacts/test-reports/`; no test writes the real user save directory.

## Rollback

Revert Phase 02-owned runner, manifest, protocol, test migrations, and documents. Runtime gameplay code is untouched.
