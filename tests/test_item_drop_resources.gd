extends SceneTree

const RESOURCE_PATHS = [
	"res://ItemDrop.tscn",
	"res://Enemy/Snake.gd",
	"res://assets/map/guyidaoguanai.tscn"
]

func _init():
	call_deferred("_run")

func _run():
	for resource_path in RESOURCE_PATHS:
		if ResourceLoader.load(resource_path) == null:
			push_error("Failed to load resource chain at: " + resource_path)
			quit(1)
			return
	if change_scene("res://assets/map/guyidaoguanai.tscn") != OK:
		push_error("Failed to change to teleport destination")
		quit(1)
		return
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	if current_scene == null or current_scene.filename != "res://assets/map/guyidaoguanai.tscn":
		push_error("Teleport destination did not become the current scene")
		quit(1)
		return
	if current_scene.get_node_or_null("Steve") == null or current_scene.get_node_or_null("UserInterFace") == null:
		push_error("Teleport destination is missing gameplay nodes")
		quit(1)
		return
	print("TEST_ITEM_DROP_RESOURCES_PASS")
	quit()
