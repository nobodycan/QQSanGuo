extends SceneTree

const SceneManagerScript = preload("res://autoload/SceneManager.gd")
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
	manager.free()
	world.free()
	test.finish(self, "scene_transaction")
