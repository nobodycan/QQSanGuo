extends Reference

const IDLE = "idle"
const ACTIVE = "active"
const FAILED = "failed"
const COMPLETED = "completed"
const STATUSES = [IDLE, ACTIVE, FAILED, COMPLETED]

func new_state(dungeon_id: String) -> Dictionary:
	return {"dungeon_id": dungeon_id, "status": IDLE, "checkpoint": "", "events": []}

func apply(raw: Dictionary, event_id: String, action: String, checkpoint: String = "") -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or str(raw.get("dungeon_id", "")).empty() or not STATUSES.has(str(raw.get("status", ""))) or typeof(raw.get("events", null)) != TYPE_ARRAY or event_id.empty():
		return {}
	var result = raw.duplicate(true)
	if result.events.has(event_id):
		return {"ok": true, "duplicate": true, "state": result}
	if not _valid_transition(str(result.status), action, checkpoint):
		return {"ok": false, "duplicate": false, "state": raw.duplicate(true)}
	if action == "enter" or action == "retry":
		result.status = ACTIVE
	elif action == "fail":
		result.status = FAILED
	elif action == "complete":
		result.status = COMPLETED
	elif action == "checkpoint":
		result.checkpoint = checkpoint
	result.events.append(event_id)
	return {"ok": true, "duplicate": false, "state": result}

func _valid_transition(status: String, action: String, checkpoint: String) -> bool:
	if status == IDLE and action == "enter":
		return true
	if status == ACTIVE and action == "checkpoint":
		return not checkpoint.empty()
	if status == ACTIVE and (action == "fail" or action == "complete"):
		return true
	return status == FAILED and action == "retry"
