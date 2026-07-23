extends SceneTree

const DungeonAccessPolicy = preload("res://actors/DungeonAccessPolicy.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var policy = DungeonAccessPolicy.new()
	var definition = {"id":"dungeon.pilot","map_id":"map.cave","min_level":12,"requires_flags":["story.cave_open"]}
	var world = {"unlocked_maps":["map.cave"],"flags":["story.cave_open"]}
	test.expect(policy.can_enter(definition, world, 12).ok, "allows players meeting dungeon prerequisites")
	test.expect(policy.can_enter(definition, world, 11).reason == "level_locked", "enforces minimum player level")
	world.flags = []
	test.expect(policy.can_enter(definition, world, 12).reason == "flag_locked", "enforces world-flag prerequisites")
	test.finish(self, "dungeon_access_policy")
