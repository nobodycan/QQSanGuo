extends Reference

const SCHEMA_VERSION = 2

func new_envelope() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"section_versions": {"metadata": 1, "location": 1, "player": 0, "inventory": 0, "equipment": 0, "skills": 0, "quests": 0, "world": 0, "legacy": 0},
		"metadata": {"content_revision": "v1-pilot"},
		"location": {"map_id": "", "spawn_id": ""},
		"player": {}, "inventory": {}, "equipment": {}, "skills": {}, "quests": {}, "world": {}, "legacy": {}
	}

func normalize(raw):
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("schema_version", -1)) != SCHEMA_VERSION:
		return null
	if typeof(raw.get("section_versions", null)) != TYPE_DICTIONARY or typeof(raw.get("location", null)) != TYPE_DICTIONARY:
		return null
	if typeof(raw.location.get("map_id", null)) != TYPE_STRING or typeof(raw.location.get("spawn_id", null)) != TYPE_STRING:
		return null
	var result = new_envelope()
	for key in result:
		if raw.has(key): result[key] = raw[key]
	return result
