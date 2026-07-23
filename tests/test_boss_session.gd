extends SceneTree

const BossEncounterState = preload("res://actors/BossEncounterState.gd")
const BossSession = preload("res://actors/BossSession.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var encounter = BossEncounterState.new().new_state("boss.pilot", 2)
	var run = EncounterDirector.new().new_run("boss", "boss.pilot", "run.1")
	var definition = {"id":"boss.pilot","map_id":"map.cave","min_level":15}
	var world = {"unlocked_maps":["map.cave"],"flags":[],"defeated_bosses":[]}
	var session = BossSession.new()
	var started = session.start(encounter, run, "start.1", definition, world, 15)
	test.expect(started.ok and started.encounter.status == BossEncounterState.ACTIVE and started.run.status == EncounterDirector.ACTIVE, "starts boss state and encounter scope together")
	var replay = session.start(started.encounter, started.run, "start.1", definition, {"unlocked_maps":[],"flags":[],"defeated_bosses":["boss.pilot"]}, 1)
	test.expect(replay.ok and replay.duplicate, "replays a stable start event without rechecking later progress")
	var blocked = session.start(encounter, run, "start.2", definition, {"unlocked_maps":[],"flags":[],"defeated_bosses":[]}, 15)
	test.expect(not blocked.ok and blocked.reason == "map_locked" and blocked.encounter.status == BossEncounterState.IDLE and blocked.run.status == EncounterDirector.PREPARED, "does not partially start a blocked encounter")
	test.finish(self, "boss_session")
