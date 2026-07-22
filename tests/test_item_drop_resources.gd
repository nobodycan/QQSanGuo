extends SceneTree

const TestProtocol = preload("res://tests/TestProtocol.gd")

const RESOURCE_PATHS = [
	"res://ItemDrop.tscn",
	"res://Enemy/Snake.gd",
	"res://assets/map/guyidaoguanai.tscn"
]

func _init():
	call_deferred("_run")

func _run():
	var test = TestProtocol.new()
	for resource_path in RESOURCE_PATHS:
		if ResourceLoader.load(resource_path) == null:
			test.expect(false, "loads resource chain: " + resource_path)
			test.finish(self, "item_drop_resources")
			return
	if change_scene("res://assets/map/guyidaoguanai.tscn") != OK:
		test.expect(false, "changes to teleport destination")
		test.finish(self, "item_drop_resources")
		return
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	if current_scene == null or current_scene.filename != "res://assets/map/guyidaoguanai.tscn":
		test.expect(false, "teleport destination is current scene")
		test.finish(self, "item_drop_resources")
		return
	if current_scene.get_node_or_null("Steve") == null or current_scene.get_node_or_null("UserInterFace") == null:
		test.expect(false, "teleport destination has gameplay nodes")
		test.finish(self, "item_drop_resources")
		return
	test.finish(self, "item_drop_resources")
