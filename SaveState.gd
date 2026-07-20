extends Node

func save_game() -> Dictionary:
	var manager = get_node_or_null("/root/SaveManager")
	if manager == null:
		return {"ok": false, "error": "save_manager_unavailable"}
	return manager.save_current_scene()

func load_game():
	var manager = get_node_or_null("/root/SaveManager")
	var scene_manager = get_node_or_null("/root/SceneManager")
	if manager == null:
		return {"ok": false, "error": "save_manager_unavailable"}
	if scene_manager == null:
		return {"ok": false, "error": "scene_manager_unavailable"}
	var result = manager.load_data()
	if not result["ok"]:
		return result
	return scene_manager.restore_snapshot(result["data"])
