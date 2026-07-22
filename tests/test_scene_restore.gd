extends SceneTree

const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	call_deferred("_run")

func _run():
	var test = TestProtocol.new()
	var state = preload("res://autoload/GameState.gd").new()
	var snapshot = state.new_save_data()
	snapshot["map_path"] = "res://tests/fixtures/scene_restore_target.tscn"
	snapshot["player"]["position"] = {"x": 123.0, "y": 456.0}
	var manager = get_root().get_node_or_null("SceneManager")
	if manager == null:
		test.expect(false, "SceneManager Autoload is present")
		_finish(test, state)
		return
	var missing_snapshot = state.new_save_data()
	missing_snapshot["map_path"] = "res://does-not-exist.tscn"
	var missing_result = manager.restore_snapshot(missing_snapshot)
	if typeof(missing_result) != TYPE_DICTIONARY or missing_result.get("ok", true) or missing_result.get("error", "") != "scene_change_failed":
		test.expect(false, "missing scene returns scene_change_failed")
		_finish(test, state)
		return
	var result = yield(manager.restore_snapshot(snapshot), "completed")
	if not result["ok"]:
		test.expect(false, "scene restoration succeeds: " + str(result))
		_finish(test, state)
		return
	if current_scene == null or current_scene.filename != "res://tests/fixtures/scene_restore_target.tscn":
		test.expect(false, "restored current scene is the target fixture")
		_finish(test, state)
		return
	var steve = current_scene.get_node_or_null("Steve")
	if steve == null or steve.position != Vector2(123.0, 456.0):
		test.expect(false, "restores player position after scene readiness")
		_finish(test, state)
		return
	var invalid_result = manager.change_to_map("user://Level1.tscn")
	if invalid_result["ok"] or invalid_result["error"] != "invalid_map_path":
		test.expect(false, "rejects user path map")
		_finish(test, state)
		return
	_finish(test, state)

func _finish(test, state):
	if current_scene != null:
		current_scene.free()
	state.free()
	test.finish(self, "scene_restore")
