extends SceneTree

func _init():
	var manager = preload("res://autoload/SaveManager.gd").new()
	manager.save_path = "user://test_game_state.json"
	manager.backup_path = "user://test_game_state.backup.json"
	_cleanup(manager)
	var result = manager.load_data()
	assert(result["ok"] == false)
	assert(result["error"] == "missing_save")
	var state = preload("res://autoload/GameState.gd").new()
	var first = state.new_save_data()
	first["map_path"] = "res://Level1.tscn"
	assert(manager.save_data(first)["ok"] == true)
	var second = state.new_save_data()
	second["map_path"] = "res://Level1.tscn"
	second["player"]["money"] = 42
	assert(manager.save_data(second)["ok"] == true)
	var corrupt = File.new()
	assert(corrupt.open(manager.save_path, File.WRITE) == OK)
	corrupt.store_string("not json")
	corrupt.close()
	result = manager.load_data()
	assert(result["ok"] == true)
	assert(result["data"]["player"]["money"] == 0)
	_cleanup(manager)
	print("TEST_SAVE_MANAGER_PASS")
	quit()

func _cleanup(manager):
	var directory = Directory.new()
	for path in [manager.save_path, manager.backup_path]:
		if directory.file_exists(path):
			directory.remove(path)
