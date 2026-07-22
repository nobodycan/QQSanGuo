extends Reference

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or str(raw.get("id", "")).empty() or typeof(raw.get("nodes", null)) != TYPE_ARRAY or raw.nodes.empty(): return {}
	var result = {"id": str(raw.id), "nodes": []}
	var ids = {}
	for node in raw.nodes:
		if typeof(node) != TYPE_DICTIONARY or str(node.get("id", "")).empty() or str(node.get("text", "")).empty() or ids.has(str(node.id)): return {}
		ids[str(node.id)] = true
		result.nodes.append({"id": str(node.id), "text": str(node.text), "requires_flags": node.get("requires_flags", []).duplicate()})
	return result

func available_nodes(definition: Dictionary, flags: Array) -> Array:
	var normalized = normalize(definition)
	if normalized.empty(): return []
	var result = []
	for node in normalized.nodes:
		var allowed = true
		for flag_name in node.requires_flags:
			if not flags.has(flag_name): allowed = false
		if allowed: result.append(node)
	return result
