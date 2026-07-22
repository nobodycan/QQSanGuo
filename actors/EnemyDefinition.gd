extends Reference

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var required = ["id", "max_health", "damage", "aggro_range", "attack_range", "ai_role", "telegraph", "loot_id"]
	for key in required:
		if not raw.has(key):
			return {}
	if typeof(raw.id) != TYPE_STRING or raw.id.empty() or int(raw.max_health) < 1 or int(raw.damage) < 0 or float(raw.aggro_range) < float(raw.attack_range):
		return {}
	return raw.duplicate(true)

func primary_difference(left: Dictionary, right: Dictionary) -> String:
	for key in ["ai_role", "telegraph", "loot_id", "damage", "max_health"]:
		if left.get(key) != right.get(key):
			return key
	return ""
