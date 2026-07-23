extends Reference

const PREPARED = "prepared"
const ACTIVE = "active"
const VICTORY = "victory"
const FAILURE = "failure"
const ABORTED = "aborted"
const CLEANED = "cleaned"
const STATUSES = [PREPARED, ACTIVE, VICTORY, FAILURE, ABORTED, CLEANED]

func new_run(kind: String, encounter_id: String, run_id: String) -> Dictionary:
	if kind.empty() or encounter_id.empty() or run_id.empty():
		return {}
	return {"kind": kind, "encounter_id": encounter_id, "run_id": run_id, "status": PREPARED, "resources": [], "events": []}

func apply(raw: Dictionary, event_id: String, action: String, resource_id: String = "") -> Dictionary:
	if not _valid_state(raw) or event_id.empty():
		return {}
	var result = raw.duplicate(true)
	if result.events.has(event_id):
		return {"ok": true, "duplicate": true, "state": result}
	if not _valid_transition(result.status, action, resource_id):
		return {"ok": false, "duplicate": false, "state": raw.duplicate(true)}
	if action == "start": result.status = ACTIVE
	elif action == "victory": result.status = VICTORY
	elif action == "failure": result.status = FAILURE
	elif action == "abort": result.status = ABORTED
	elif action == "attach": result.resources.append(resource_id)
	elif action == "detach": result.resources.erase(resource_id)
	elif action == "cleanup":
		result.status = CLEANED
		result.resources = []
	result.events.append(event_id)
	return {"ok": true, "duplicate": false, "state": result}

func _valid_state(raw: Dictionary) -> bool:
	return typeof(raw) == TYPE_DICTIONARY and not str(raw.get("kind", "")).empty() and not str(raw.get("encounter_id", "")).empty() and not str(raw.get("run_id", "")).empty() and STATUSES.has(str(raw.get("status", ""))) and typeof(raw.get("resources", null)) == TYPE_ARRAY and typeof(raw.get("events", null)) == TYPE_ARRAY

func _valid_transition(status: String, action: String, resource_id: String) -> bool:
	if status == PREPARED: return action == "start" or action == "abort"
	if status == ACTIVE:
		if action == "attach": return not resource_id.empty()
		if action == "detach": return not resource_id.empty()
		return action == "victory" or action == "failure" or action == "abort"
	return (status == VICTORY or status == FAILURE or status == ABORTED) and action == "cleanup"
