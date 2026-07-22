extends Reference

func migrate_location(map_path: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has("maps") or not aliases.maps.has(map_path):
		return {"ok": false, "error": "unresolved_map", "value": map_path}
	return {"ok": true, "location": aliases.maps[map_path]}

func migrate_name(name: String, category: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has(category) or not aliases[category].has(name):
		return {"ok": false, "error": "unresolved_" + category, "value": name}
	return {"ok": true, "id": aliases[category][name]}
