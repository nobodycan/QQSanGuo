extends Node

var _entries = {}
var _aliases = {}
var _content_revision = ""

func _ready() -> void:
	load_content()

func load_content(manifest_path: String = "res://content/v1/manifest.json") -> Dictionary:
	var manifest = _read_json(manifest_path)
	if manifest.empty() or typeof(manifest.get("packs", null)) != TYPE_ARRAY or not _is_valid_revision(str(manifest.get("content_revision", ""))):
		return _failure("invalid_content_manifest")
	var staged = {}
	for pack in manifest.packs:
		if typeof(pack) != TYPE_STRING or pack.empty() or pack.find("/") >= 0 or pack.find("\\") >= 0:
			return _failure("invalid_content_pack")
		var data = _read_json(manifest_path.get_base_dir().plus_file(pack))
		if data.empty() or typeof(data.get("entries", null)) != TYPE_ARRAY:
			return _failure("invalid_content_pack")
		for entry in data.entries:
			if typeof(entry) != TYPE_DICTIONARY or not _is_valid_id(str(entry.get("id", ""))) or staged.has(entry.id) or not _valid_entry(entry) or not _resources_exist(entry):
				return _failure("invalid_content_entry")
			staged[entry.id] = entry.duplicate(true)
	var aliases = _read_json(manifest_path.get_base_dir().plus_file("legacy_aliases.json"))
	if not _valid_aliases(aliases, staged):
		return _failure("invalid_content_aliases")
	_entries = staged
	_aliases = aliases.duplicate(true)
	_content_revision = str(manifest.content_revision)
	return {"ok": true, "error_code": "", "operation_id": "content.load", "data": {"entry_count": _entries.size(), "content_revision": _content_revision}}

func content_revision() -> String:
	return _content_revision

func has_entry(content_id: String) -> bool:
	return _entries.has(content_id)

func get_entry(content_id: String) -> Dictionary:
	if not has_entry(content_id):
		return _failure("content_not_found")
	return {"ok": true, "error_code": "", "operation_id": "content.get", "data": _entries[content_id].duplicate(true)}

func entries_of_kind(kind: String) -> Array:
	var result = []
	for content_id in _entries.keys():
		var entry = _entries[content_id]
		if str(entry.get("kind", "")) == kind:
			result.append(entry.duplicate(true))
	result.sort_custom(self, "_sort_entries_by_id")
	return result

func resolve_legacy(category: String, legacy_value: String) -> Dictionary:
	if not _aliases.has(category) or not _aliases[category].has(legacy_value):
		return _failure("legacy_alias_not_found")
	var value = _aliases[category][legacy_value]
	return {"ok": true, "error_code": "", "operation_id": "content.resolve_legacy", "data": value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else value}

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

func _valid_entry(entry: Dictionary) -> bool:
	var kind = str(entry.get("kind", ""))
	if kind == "map":
		return typeof(entry.get("scene", null)) == TYPE_STRING and not str(entry.scene).empty() and typeof(entry.get("default_spawn_id", null)) == TYPE_STRING and typeof(entry.get("spawns", null)) == TYPE_ARRAY
	if kind == "skill":
		return int(entry.get("unlock_level", 0)) >= 1 and int(entry.get("magic_cost", -1)) >= 0 and int(entry.get("cooldown_ticks", -1)) >= 0 and int(entry.get("damage", -1)) >= 0
	return ["equipment", "material", "consumable"].has(kind) and int(entry.get("stack_limit", 0)) >= 1 and typeof(entry.get("quest", null)) == TYPE_BOOL

func _valid_aliases(aliases: Dictionary, entries: Dictionary) -> bool:
	for category in ["items", "skills"]:
		if typeof(aliases.get(category, null)) != TYPE_DICTIONARY:
			return false
		for legacy_name in aliases[category]:
			if typeof(legacy_name) != TYPE_STRING or not entries.has(str(aliases[category][legacy_name])):
				return false
	if typeof(aliases.get("maps", null)) != TYPE_DICTIONARY:
		return false
	for legacy_path in aliases.maps:
		var location = aliases.maps[legacy_path]
		if typeof(legacy_path) != TYPE_STRING or typeof(location) != TYPE_DICTIONARY or not entries.has(str(location.get("map_id", ""))) or str(entries[location.map_id].get("kind", "")) != "map":
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

func _is_valid_revision(revision: String) -> bool:
	return revision.begins_with("v") and revision.length() > 1 and revision.find(" ") < 0

func _sort_entries_by_id(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("id", "")) < str(right.get("id", ""))

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error_code": error_code, "operation_id": "content", "data": null}
