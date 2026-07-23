extends Reference

func validate(definitions: Array) -> Dictionary:
	var by_id = {}
	for definition in definitions:
		if typeof(definition) != TYPE_DICTIONARY or str(definition.get("id", "")).empty() or by_id.has(str(definition.id)) or typeof(definition.get("prerequisites", [])) != TYPE_ARRAY: return {"ok": false, "error": "invalid_definition"}
		by_id[str(definition.id)] = definition
	for quest_id in by_id:
		for prerequisite in by_id[quest_id].get("prerequisites", []):
			if typeof(prerequisite) != TYPE_STRING or not by_id.has(prerequisite): return {"ok": false, "error": "missing_prerequisite"}
		if _has_cycle(quest_id, by_id, {}, {}): return {"ok": false, "error": "cycle"}
	return {"ok": true, "definitions": by_id}

func _has_cycle(quest_id: String, by_id: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(quest_id): return true
	if visited.has(quest_id): return false
	visiting[quest_id] = true
	for prerequisite in by_id[quest_id].get("prerequisites", []):
		if _has_cycle(prerequisite, by_id, visiting, visited): return true
	visiting.erase(quest_id)
	visited[quest_id] = true
	return false
