extends Node

var settings_path = "user://settings.cfg"
var current_bgm = ""

func load_settings() -> Dictionary:
	var config = ConfigFile.new()
	if config.load(settings_path) != OK:
		return {"ok": true, "volume_db": 0.0}
	return {"ok": true, "volume_db": float(config.get_value("audio", "master_volume_db", 0.0))}

func save_settings(volume_db: float) -> Dictionary:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume_db", volume_db)
	if config.save(settings_path) != OK:
		return _failure("settings_write_failed")
	return {"ok": true, "error_code": "", "operation_id": "audio.settings", "data": volume_db}

func set_bus_volume(bus_name: String, volume_db: float) -> Dictionary:
	if bus_name.empty():
		return _failure("invalid_bus")
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return _failure("bus_not_found")
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	return {"ok": true, "error_code": "", "operation_id": "audio.volume", "data": null}

func play_bgm(resource_path: String) -> Dictionary:
	if resource_path.empty():
		return _failure("invalid_bgm_path")
	current_bgm = resource_path
	return {"ok": true, "error_code": "", "operation_id": "audio.bgm", "data": resource_path}

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error_code": error_code, "operation_id": "audio", "data": null}
