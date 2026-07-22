extends SceneTree

const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var scene = load("res://GameRoot.tscn")
	var root = scene.instance()
	test.expect(root.session_instance_id == 0, "session starts before ready")
	get_root().add_child(root)
	var snapshot = root.lifecycle_snapshot()
	test.expect(snapshot.game_root_id == root.get_instance_id(), "session id is stable")
	test.expect(snapshot.world_children == 0 and snapshot.player_children == 0 and snapshot.ui_children == 0, "compatibility roots start empty")
	root.queue_free()
	test.finish(self, "game_root")
