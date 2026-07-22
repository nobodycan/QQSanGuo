extends Reference

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or str(raw.get("id", "")).empty() or str(raw.get("map_id", "")).empty() or str(raw.get("dialogue_id", "")).empty() or float(raw.get("interaction_radius", 0.0)) <= 0.0:
		return {}
	return {"id": str(raw.id), "map_id": str(raw.map_id), "dialogue_id": str(raw.dialogue_id), "interaction_radius": float(raw.interaction_radius)}
