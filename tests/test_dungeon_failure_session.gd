extends SceneTree

const DungeonFailureSession = preload("res://actors/DungeonFailureSession.gd")
const DungeonState = preload("res://actors/DungeonState.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new().new_state("dungeon.pilot")
	dungeon = DungeonState.new().apply(dungeon, "enter.1", "enter").state
	dungeon = DungeonState.new().apply(dungeon, "checkpoint.1", "checkpoint", "wave.two").state
	var run = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.1")
	run = EncounterDirector.new().apply(run, "run.start.1", "start").state
	var session = DungeonFailureSession.new()
	var failed = session.fail(dungeon, run, "failure.1")
	test.expect(failed.ok and failed.dungeon.status == DungeonState.FAILED and failed.dungeon.checkpoint == "wave.two" and failed.run.status == EncounterDirector.FAILURE, "marks a running dungeon failed without losing its checkpoint")
	var replay = session.fail(failed.dungeon, failed.run, "failure.1")
	test.expect(replay.ok and replay.duplicate and replay.dungeon.checkpoint == "wave.two", "deduplicates repeated failure callbacks")
	var inactive_run = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.2")
	var blocked = session.fail(dungeon, inactive_run, "failure.2")
	test.expect(not blocked.ok and blocked.dungeon.status == DungeonState.ACTIVE and blocked.run.status == EncounterDirector.PREPARED, "rejects failure when the dungeon scope is not active")
	test.finish(self, "dungeon_failure_session")
