extends SceneTree

const SceneManagerScript = preload("res://autoload/SceneManager.gd")
const WorldState = preload("res://actors/WorldState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var manager = SceneManagerScript.new()
	var world = Node.new()
	var previous = Node.new()
	world.add_child(previous)
	var invalid = manager.replace_world(world, "res://missing.tscn")
	test.expect(not invalid.ok and world.get_child_count() == 1 and world.get_child(0) == previous, "invalid candidate preserves current world")
	var valid = manager.replace_world(world, "res://Login.tscn")
	test.expect(valid.ok and world.get_child_count() == 1 and world.get_child(0) != previous, "valid candidate commits replacement")
	var locked_previous = world.get_child(0)
	var maps = [{"id": "map.locked", "spawns": [{"id": "spawn.entry"}]}]
	var locked = manager.replace_world_if_allowed(world, "res://Login.tscn", maps, WorldState.new().new_state(), "map.locked", "spawn.entry", "map.start")
	test.expect(not locked.ok and locked.error == "map_locked" and world.get_child(0) == locked_previous, "locked map preserves current world before loading")
	var unlocked_world = WorldState.new().new_state()
	unlocked_world.unlocked_maps.append("map.locked")
	var unlocked = manager.replace_world_if_allowed(world, "res://Login.tscn", maps, unlocked_world, "map.locked", "spawn.entry", "map.start")
	test.expect(unlocked.ok and world.get_child(0) != locked_previous, "unlocked map commits world replacement")
	manager.free()
	world.free()
	test.finish(self, "scene_transaction")
