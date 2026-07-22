extends SceneTree

const WorldState = preload("res://actors/WorldState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var world = WorldState.new()
	var state = world.new_state()
	state.flags = ["flag.met_elder"]
	state.unlocked_maps = ["map.level_one"]
	state.defeated_bosses = ["boss.dengmao"]
	state.checkpoint = "map.level_one.spawn.start"
	state.ledger = ["world.boss.dengmao"]
	var normalized = world.normalize(state)
	test.expect(not normalized.empty() and normalized.checkpoint == state.checkpoint and normalized.flags.size() == 1, "normalizes canonical world state")
	test.expect(world.migrate_v0({}).version == 1 and world.migrate_v0(normalized).checkpoint == normalized.checkpoint, "migrates empty v0 and preserves v1")
	state.flags.append("flag.met_elder")
	test.expect(world.normalize(state).empty(), "rejects duplicate world IDs")
	test.finish(self, "world_state")
