# Release Notes

## Unreleased

### Phase 02 - Test Orchestration and Structured Diagnostics

- Added `scripts/test_runner.ps1` as the single test entry point with lane selection, watchdogs, isolated test homes, UTF-8 logs, JSON reports, and JUnit output.
- Added protocol self-tests for pass, explicit failure, timeout, and false-green error logs.
- Added `tests/TestProtocol.gd` and migrated current GDScript tests to emit `TEST_RESULT` instead of using bare `assert`.
- Added a versioned test manifest covering unit, integration, resource, and scene tests.
- Godot executable discovery uses `-GodotPath` or `GODOT_BIN`; when unavailable, Godot tests are reported as blocked rather than passing.

### Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_runner.ps1 -SelfTest` passes.
- Full Godot lanes require a Godot 3.5.3 executable and remain pending on machines without it.
