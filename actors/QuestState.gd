extends Reference

const LOCKED = "locked"
const AVAILABLE = "available"
const ACTIVE = "active"
const READY = "ready_to_turn_in"
const COMPLETED = "completed"
const STATES = [LOCKED, AVAILABLE, ACTIVE, READY, COMPLETED]

func new_state(quest_id: String) -> Dictionary:
	return {"quest_id": quest_id, "status": LOCKED, "events": []}

func apply(raw: Dictionary, event_id: String, action: String) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or str(raw.get("quest_id", "")).empty() or not STATES.has(str(raw.get("status", ""))) or typeof(raw.get("events", null)) != TYPE_ARRAY or event_id.empty(): return {}
	var result = raw.duplicate(true)
	if result.events.has(event_id): return {"state": result, "duplicate": true, "ok": true}
	var next = _next(str(result.status), action)
	if next.empty(): return {"state": raw.duplicate(true), "duplicate": false, "ok": false}
	result.status = next
	result.events.append(event_id)
	return {"state": result, "duplicate": false, "ok": true}

func _next(status: String, action: String) -> String:
	if status == LOCKED and action == "unlock": return AVAILABLE
	if status == AVAILABLE and action == "accept": return ACTIVE
	if status == ACTIVE and action == "objectives_complete": return READY
	if status == READY and action == "turn_in": return COMPLETED
	return ""
