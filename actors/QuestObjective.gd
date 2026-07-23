extends Reference

func new_state(kind: String, target_id: String, required_count: int) -> Dictionary:
	return {"kind": kind, "target_id": target_id, "required_count": required_count, "count": 0, "events": []}

func apply(raw: Dictionary, event_id: String, kind: String, target_id: String, amount: int = 1) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or event_id.empty() or amount < 1 or str(raw.get("kind", "")).empty() or str(raw.get("target_id", "")).empty() or int(raw.get("required_count", 0)) < 1 or typeof(raw.get("events", null)) != TYPE_ARRAY: return {}
	var result = raw.duplicate(true)
	if result.events.has(event_id): return {"ok": true, "duplicate": true, "state": result}
	if kind != result.kind or target_id != result.target_id: return {"ok": false, "duplicate": false, "state": raw.duplicate(true)}
	result.count = min(int(result.required_count), int(result.get("count", 0)) + amount)
	result.events.append(event_id)
	return {"ok": true, "duplicate": false, "state": result}

func complete(raw: Dictionary) -> bool:
	return typeof(raw) == TYPE_DICTIONARY and int(raw.get("count", 0)) >= int(raw.get("required_count", 1))
