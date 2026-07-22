extends SceneTree

const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var manager = preload("res://autoload/SaveManager.gd").new()
	var test = TestProtocol.new()
	manager.save_path = "user://test_game_state.json"
	manager.backup_path = "user://test_game_state.backup.json"
	_cleanup(manager)
	var result = manager.load_data()
	test.expect(result["ok"] == false, "missing save is not loaded")
	test.expect(result["error"] == "missing_save", "missing save returns missing_save")
	var state = preload("res://autoload/GameState.gd").new()
	var first = state.new_save_data()
	first["map_path"] = "res://Level1.tscn"
	test.expect(manager.save_data(first)["ok"] == true, "saves first generation")
	var second = state.new_save_data()
	second["map_path"] = "res://Level1.tscn"
	second["player"]["money"] = 42
	test.expect(manager.save_data(second)["ok"] == true, "saves second generation")
	var corrupt = File.new()
	test.expect(corrupt.open(manager.save_path, File.WRITE) == OK, "opens save for corruption fixture")
	corrupt.store_string("{\"version\":999}")
	corrupt.close()
	result = manager.load_data()
	test.expect(result["ok"] == true, "loads backup after corrupted save")
	test.expect(result["ok"] and result["data"]["player"]["money"] == 0, "backup preserves first generation")
	_cleanup(manager)
	test.finish(self, "save_manager")

func _cleanup(manager):
	var directory = Directory.new()
	for path in [manager.save_path, manager.backup_path]:
		if directory.file_exists(path):
			directory.remove(path)
