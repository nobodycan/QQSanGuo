extends Reference

func migrate_location(map_path: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has("maps") or not aliases.maps.has(map_path):
		return {"ok": false, "error": "unresolved_map", "value": map_path}
	return {"ok": true, "location": aliases.maps[map_path]}

func migrate_name(name: String, category: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has(category) or not aliases[category].has(name):
		return {"ok": false, "error": "unresolved_" + category, "value": name}
	return {"ok": true, "id": aliases[category][name]}

func migrate_location_registered(map_path: String, registry: Node) -> Dictionary:
	var resolved = _resolve_registry(registry, "maps", map_path)
	if not resolved.ok or typeof(resolved.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "unresolved_map", "value": map_path}
	return {"ok": true, "location": resolved.data}

func migrate_name_registered(name: String, category: String, registry: Node) -> Dictionary:
	var resolved = _resolve_registry(registry, category, name)
	if not resolved.ok or typeof(resolved.data) != TYPE_STRING:
		return {"ok": false, "error": "unresolved_" + category, "value": name}
	return {"ok": true, "id": resolved.data}

func migrate_skills_registered(raw: Dictionary, registry: Node) -> Dictionary:
	var skill_state = load("res://actors/SkillState.gd").new()
	var migrated = skill_state.migrate_legacy_registered(raw, registry)
	if migrated.empty():
		return {"ok": false, "error": "unresolved_skills", "state": {}}
	return {"ok": true, "error": "", "state": migrated}

func _resolve_registry(registry: Node, category: String, value: String) -> Dictionary:
	if registry == null or not registry.has_method("resolve_legacy"):
		return {"ok": false}
	return registry.resolve_legacy(category, value)
