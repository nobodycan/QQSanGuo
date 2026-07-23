extends SceneTree

const BossEncounterState = preload("res://actors/BossEncounterState.gd")
const BossFailureSession = preload("res://actors/BossFailureSession.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var encounter = BossEncounterState.new().new_state("boss.pilot", 3)
	encounter = BossEncounterState.new().apply(encounter, "start.1", "start").state
	encounter = BossEncounterState.new().apply(encounter, "phase.1", "next_phase").state
	var run = EncounterDirector.new().new_run("boss", "boss.pilot", "run.1")
	run = EncounterDirector.new().apply(run, "run.start.1", "start").state
	var session = BossFailureSession.new()
	var failed = session.fail(encounter, run, "failure.1")
	test.expect(failed.ok and failed.encounter.status == BossEncounterState.IDLE and failed.encounter.phase == 0 and failed.run.status == EncounterDirector.FAILURE, "resets a failed boss and ends its encounter scope")
	var replay = session.fail(failed.encounter, failed.run, "failure.1")
	test.expect(replay.ok and replay.duplicate, "deduplicates delayed boss failure callbacks")
	var inactive_run = EncounterDirector.new().new_run("boss", "boss.pilot", "run.2")
	var blocked = session.fail(encounter, inactive_run, "failure.2")
	test.expect(not blocked.ok and blocked.encounter.status == BossEncounterState.ACTIVE and blocked.run.status == EncounterDirector.PREPARED, "rejects failure when the boss scope is not active")
	test.finish(self, "boss_failure_session")
