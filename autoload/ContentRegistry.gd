extends Node

var _entries = {}

func _ready() -> void:
	load_content()

func load_content(manifest_path: String = "res://content/v1/manifest.json") -> Dictionary:
	var manifest = _read_json(manifest_path)
	if manifest.empty() or typeof(manifest.get("packs", null)) != TYPE_ARRAY:
		return _failure("invalid_content_manifest")
	var staged = {}
	for pack in manifest.packs:
		if typeof(pack) != TYPE_STRING or pack.empty() or pack.find("/") >= 0 or pack.find("\\") >= 0:
			return _failure("invalid_content_pack")
		var data = _read_json(manifest_path.get_base_dir().plus_file(pack))
		if data.empty() or typeof(data.get("entries", null)) != TYPE_ARRAY:
			return _failure("invalid_content_pack")
		for entry in data.entries:
			if typeof(entry) != TYPE_DICTIONARY or not _is_valid_id(str(entry.get("id", ""))) or staged.has(entry.id) or not _resources_exist(entry):
				return _failure("invalid_content_entry")
			staged[entry.id] = entry.duplicate(true)
	_entries = staged
	return {"ok": true, "error_code": "", "operation_id": "content.load", "data": {"entry_count": _entries.size()}}

func has_entry(content_id: String) -> bool:
	return _entries.has(content_id)

func get_entry(content_id: String) -> Dictionary:
	if not has_entry(content_id):
		return _failure("content_not_found")
	return {"ok": true, "error_code": "", "operation_id": "content.get", "data": _entries[content_id]}

func validate_id(content_id: String) -> Dictionary:
	if not _is_valid_id(content_id):
		return _failure("invalid_content_id")
	return {"ok": true, "error_code": "", "operation_id": "content.validate", "data": content_id}

func _read_json(path: String) -> Dictionary:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return {}
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	return parsed.result if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY else {}

func _resources_exist(entry: Dictionary) -> bool:
	for field in ["icon", "scene"]:
		if entry.has(field) and (typeof(entry[field]) != TYPE_STRING or not ResourceLoader.exists(entry[field])):
			return false
	return true

func _is_valid_id(content_id: String) -> bool:
	var parts = content_id.split(".")
	if parts.size() != 2 or parts[0].empty() or parts[1].empty():
		return false
	for character in parts[0]:
		if not (character >= "a" and character <= "z"):
			return false
	for character in parts[1]:
		if not ((character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_"):
			return false
	return true

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error_code": error_code, "operation_id": "content", "data": null}
