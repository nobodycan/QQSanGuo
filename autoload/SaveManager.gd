extends Node

const GameStateScript = preload("res://autoload/GameState.gd")

var save_path = "user://save_game.json"
var backup_path = "user://save_game.backup.json"

func save_current_scene() -> Dictionary:
	var snapshot = _game_state().capture_from_scene(get_tree().current_scene)
	return save_data(snapshot)

func save_data(snapshot) -> Dictionary:
	var normalized = _game_state().normalize(snapshot)
	if normalized == null:
		return _failure("invalid_state")
	_backup_current_save()
	var file = File.new()
	if file.open(save_path, File.WRITE) != OK:
		return _failure("write_failed")
	file.store_string(to_json(normalized))
	file.close()
	return {"ok": true, "data": normalized}

func load_data() -> Dictionary:
	var primary = _read_path(save_path)
	if primary["ok"]:
		return primary
	var backup = _read_path(backup_path)
	if backup["ok"]:
		return backup
	if primary["error"] == "missing_save" and backup["error"] == "missing_save":
		return _failure("missing_save")
	if primary["error"] == "unsupported_version" or backup["error"] == "unsupported_version":
		return _failure("unsupported_version")
	return _failure("corrupt_save")

func _read_path(path: String) -> Dictionary:
	var file = File.new()
	if not file.file_exists(path):
		return _failure("missing_save")
	if file.open(path, File.READ) != OK:
		return _failure("read_failed")
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return _failure("corrupt_save")
	var normalized = _game_state().normalize(parsed.result)
	if normalized == null:
		if parsed.result.has("version") and parsed.result.version != GameStateScript.VERSION:
			return _failure("unsupported_version")
		return _failure("corrupt_save")
	return {"ok": true, "data": normalized}

func _backup_current_save() -> void:
	var current_file = File.new()
	if not current_file.file_exists(save_path):
		return
	var current = _read_path(save_path)
	if not current["ok"]:
		return
	if current_file.open(save_path, File.READ) != OK:
		return
	var content = current_file.get_as_text()
	current_file.close()
	var backup_file = File.new()
	if backup_file.open(backup_path, File.WRITE) == OK:
		backup_file.store_string(content)
		backup_file.close()

func _game_state():
	var singleton = null
	if is_inside_tree():
		singleton = get_node_or_null("/root/GameState")
	return singleton if singleton != null else GameStateScript.new()

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error": error_code}
