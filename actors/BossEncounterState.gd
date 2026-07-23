extends Reference

const IDLE = "idle"
const ACTIVE = "active"
const DEFEATED = "defeated"
const STATUSES = [IDLE, ACTIVE, DEFEATED]

func new_state(boss_id: String, phase_count: int) -> Dictionary:
	if boss_id.empty() or phase_count < 1:
		return {}
	return {"boss_id": boss_id, "phase_count": phase_count, "phase": 0, "status": IDLE, "events": []}

func apply(raw: Dictionary, event_id: String, action: String) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or str(raw.get("boss_id", "")).empty() or int(raw.get("phase_count", 0)) < 1 or int(raw.get("phase", -1)) < 0 or int(raw.get("phase", -1)) >= int(raw.get("phase_count", 0)) or not STATUSES.has(str(raw.get("status", ""))) or typeof(raw.get("events", null)) != TYPE_ARRAY or event_id.empty():
		return {}
	var result = raw.duplicate(true)
	if result.events.has(event_id):
		return {"ok": true, "duplicate": true, "state": result}
	if not _valid(result, action):
		return {"ok": false, "duplicate": false, "state": raw.duplicate(true)}
	if action == "start":
		result.status = ACTIVE
	elif action == "next_phase":
		result.phase += 1
	elif action == "defeat":
		result.status = DEFEATED
	elif action == "reset":
		result.status = IDLE
		result.phase = 0
	result.events.append(event_id)
	return {"ok": true, "duplicate": false, "state": result}

func _valid(state: Dictionary, action: String) -> bool:
	if state.status == IDLE:
		return action == "start"
	if state.status == ACTIVE:
		return action == "defeat" or action == "reset" or (action == "next_phase" and int(state.phase) + 1 < int(state.phase_count))
	return state.status == DEFEATED and action == "reset"
