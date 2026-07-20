extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var state = preload("res://autoload/GameState.gd").new()
	var snapshot = state.new_save_data()
	snapshot["map_path"] = "res://Level1.tscn"
	snapshot["player"]["position"] = {"x": 123.0, "y": 456.0}
	var manager = get_root().get_node_or_null("SceneManager")
	if manager == null:
		push_error("SceneManager Autoload is missing")
		quit(1)
		return
	var result = yield(manager.restore_snapshot(snapshot), "completed")
	if not result["ok"]:
		push_error("Scene restoration failed: " + str(result))
		quit(1)
		return
	if current_scene == null or current_scene.filename != "res://Level1.tscn":
		push_error("Wrong current scene after restore")
		quit(1)
		return
	var steve = current_scene.get_node_or_null("Steve")
	if steve == null or steve.position != Vector2(123.0, 456.0):
		push_error("Player state was not applied after scene readiness")
		quit(1)
		return
	var invalid_result = manager.change_to_map("user://Level1.tscn")
	if invalid_result["ok"] or invalid_result["error"] != "invalid_map_path":
		push_error("Invalid map path was accepted")
		quit(1)
		return
	print("TEST_SCENE_RESTORE_PASS")
	quit()
