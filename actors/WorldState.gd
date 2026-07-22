extends Reference

const VERSION = 1
const LEDGER_LIMIT = 256

func new_state() -> Dictionary:
	return {"version": VERSION, "flags": [], "unlocked_maps": [], "defeated_bosses": [], "checkpoint": "", "ledger": []}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION or typeof(raw.get("flags", null)) != TYPE_ARRAY or typeof(raw.get("unlocked_maps", null)) != TYPE_ARRAY or typeof(raw.get("defeated_bosses", null)) != TYPE_ARRAY or typeof(raw.get("ledger", null)) != TYPE_ARRAY or typeof(raw.get("checkpoint", null)) != TYPE_STRING or raw.ledger.size() > LEDGER_LIMIT:
		return {}
	var result = new_state()
	for key in ["flags", "unlocked_maps", "defeated_bosses", "ledger"]:
		for value in raw[key]:
			if typeof(value) != TYPE_STRING or value.empty() or result[key].has(value): return {}
			result[key].append(value)
	result.checkpoint = raw.checkpoint
	return result

func migrate_v0(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY: return {}
	if int(raw.get("version", 0)) == VERSION: return normalize(raw)
	return new_state() if raw.empty() else {}

func apply(raw: Dictionary, operation_id: String, kind: String, value: String) -> Dictionary:
	var state = normalize(raw)
	if state.empty() or operation_id.empty() or value.empty() or not ["flag", "unlock_map", "defeat_boss", "checkpoint"].has(kind):
		return {"ok": false, "state": raw.duplicate(true), "duplicate": false}
	if state.ledger.has(operation_id):
		return {"ok": true, "state": state, "duplicate": true}
	if kind == "flag" and not state.flags.has(value): state.flags.append(value)
	elif kind == "unlock_map" and not state.unlocked_maps.has(value): state.unlocked_maps.append(value)
	elif kind == "defeat_boss" and not state.defeated_bosses.has(value): state.defeated_bosses.append(value)
	elif kind == "checkpoint": state.checkpoint = value
	state.ledger.append(operation_id)
	if state.ledger.size() > LEDGER_LIMIT: state.ledger.pop_front()
	return {"ok": true, "state": state, "duplicate": false}
