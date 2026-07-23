extends SceneTree

const DungeonSession = preload("res://actors/DungeonSession.gd")
const DungeonState = preload("res://actors/DungeonState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var state = DungeonState.new().new_state("dungeon.pilot")
	var definition = {"id":"dungeon.pilot","map_id":"map.cave","min_level":12,"requires_flags":["story.cave_open"]}
	var world = {"unlocked_maps":["map.cave"],"flags":["story.cave_open"]}
	var session = DungeonSession.new()
	var entered = session.enter(state, "dungeon.enter.1", definition, world, 12)
	test.expect(entered.ok and not entered.duplicate and entered.state.status == DungeonState.ACTIVE, "enters only through the access-checked session")
	var replay = session.enter(entered.state, "dungeon.enter.1", definition, {"unlocked_maps":[],"flags":[]}, 1)
	test.expect(replay.ok and replay.duplicate and replay.state.status == DungeonState.ACTIVE, "replays the stable entry event without rechecking changed progress")
	var blocked = session.enter(state, "dungeon.enter.2", definition, {"unlocked_maps":["map.cave"],"flags":[]}, 12)
	test.expect(not blocked.ok and blocked.reason == "flag_locked" and blocked.state.status == DungeonState.IDLE, "keeps dungeon idle when prerequisites are missing")
	test.expect(not session.enter(state, "dungeon.enter.3", {"id":"dungeon.other","map_id":"map.cave"}, world, 12).ok, "rejects definitions that target another dungeon state")
	test.finish(self, "dungeon_session")
