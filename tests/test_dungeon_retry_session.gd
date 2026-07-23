extends SceneTree

const DungeonRetrySession = preload("res://actors/DungeonRetrySession.gd")
const DungeonState = preload("res://actors/DungeonState.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new().new_state("dungeon.pilot")
	dungeon = DungeonState.new().apply(dungeon, "enter.1", "enter").state
	dungeon = DungeonState.new().apply(dungeon, "checkpoint.1", "checkpoint", "wave.two").state
	dungeon = DungeonState.new().apply(dungeon, "failure.1", "fail").state
	var previous = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.1")
	previous = EncounterDirector.new().apply(previous, "start.1", "start").state
	previous = EncounterDirector.new().apply(previous, "failure.1", "failure").state
	previous = EncounterDirector.new().apply(previous, "cleanup.1", "cleanup").state
	var next = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.2")
	var session = DungeonRetrySession.new()
	var retried = session.retry(dungeon, previous, next, "retry.1")
	test.expect(retried.ok and not retried.duplicate and retried.dungeon.status == DungeonState.ACTIVE and retried.dungeon.checkpoint == "wave.two" and retried.run.status == EncounterDirector.ACTIVE, "retries from the preserved checkpoint only after the prior run is cleaned")
	var replay = session.retry(retried.dungeon, previous, retried.run, "retry.1")
	test.expect(replay.ok and replay.duplicate and replay.run.status == EncounterDirector.ACTIVE, "deduplicates stable retry events across dungeon and new run")
	var uncleared = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.3")
	var blocked = session.retry(dungeon, uncleared, next, "retry.2")
	test.expect(not blocked.ok and blocked.dungeon.status == DungeonState.FAILED and blocked.run.status == EncounterDirector.PREPARED, "rejects retries while the prior run still owns resources")
	test.finish(self, "dungeon_retry_session")
