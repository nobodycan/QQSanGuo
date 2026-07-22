extends Node

var settings_path = "user://settings.cfg"
var current_bgm = ""

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
