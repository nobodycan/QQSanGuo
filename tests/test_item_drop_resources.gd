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
			_finish(test)
			return
	var destination = ResourceLoader.load("res://assets/map/guyidaoguanai.tscn")
	if not (destination is PackedScene):
		test.expect(false, "loads teleport destination scene")
		_finish(test)
		return
	var scene_file = File.new()
	if scene_file.open("res://assets/map/guyidaoguanai.tscn", File.READ) != OK:
		test.expect(false, "opens teleport destination scene")
		_finish(test)
		return
	var scene_source = scene_file.get_as_text()
	scene_file.close()
	test.expect(scene_source.find('[node name="Steve"') >= 0, "teleport destination declares Steve")
	test.expect(scene_source.find('[node name="UserInterFace"') >= 0, "teleport destination declares UserInterFace")
	_finish(test)

func _finish(test):
	if current_scene != null:
		current_scene.free()
	test.finish(self, "item_drop_resources")
