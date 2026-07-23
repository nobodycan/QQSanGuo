extends Reference

func normalize(raw: Dictionary) -> Dictionary:
	var boss_id = str(raw.get("boss_id", ""))
	var thresholds = raw.get("thresholds_bps", null)
	if boss_id.empty() or typeof(thresholds) != TYPE_ARRAY or thresholds.empty():
		return {}
	var previous = 10000
	var normalized = []
	for threshold in thresholds:
		if typeof(threshold) != TYPE_INT or threshold < 1 or threshold >= previous:
			return {}
		normalized.append(threshold)
		previous = threshold
	return {"boss_id": boss_id, "thresholds_bps": normalized}

func phase(definition: Dictionary, health_bps: int) -> int:
	var normalized = normalize(definition)
	if normalized.empty() or health_bps < 0 or health_bps > 10000:
		return -1
	var result = 0
	for threshold in normalized.thresholds_bps:
		if health_bps <= int(threshold):
			result += 1
	return result
