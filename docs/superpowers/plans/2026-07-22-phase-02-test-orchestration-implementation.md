# Phase 02: Test Orchestration Implementation Plan

1. Add a versioned manifest that assigns every current test to a lane and watchdog.
2. Add the PowerShell orchestrator with isolated environment variables, UTF-8 capture, JSON/JUnit output, protocol checks, and self-test fixtures.
3. Add `TestProtocol.gd` and migrate the existing GDScript tests from bare assertions to collected expectations and one terminal result.
4. Update the resource audit test to use the terminal protocol for both pass and failure.
5. Execute runner self-tests and the resource lane; record unavailable Godot evidence honestly.
6. Document the one-command workflow in `README.md` and release notes.
