extends Reference

const VERSION = 1
const LEDGER_LIMIT = 256

func new_state() -> Dictionary:
	return {"version": VERSION, "money": 0, "juntuan": 0, "ledger": []}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION or int(raw.get("money", -1)) < 0 or int(raw.get("juntuan", -1)) < 0 or typeof(raw.get("ledger", null)) != TYPE_ARRAY or raw.ledger.size() > LEDGER_LIMIT:
		return {}
	var result = new_state()
	result.money = int(raw.money)
	result.juntuan = int(raw.juntuan)
	for operation_id in raw.ledger:
		if typeof(operation_id) != TYPE_STRING or operation_id.empty() or result.ledger.has(operation_id):
			return {}
		result.ledger.append(operation_id)
	return result

func apply(raw: Dictionary, operation_id: String, money_delta: int, juntuan_delta: int) -> Dictionary:
	var state = normalize(raw)
	if state.empty() or operation_id.empty():
		return {"ok": false, "state": raw.duplicate(true), "duplicate": false}
	if state.ledger.has(operation_id):
		return {"ok": true, "state": state, "duplicate": true}
	if state.money + money_delta < 0 or state.juntuan + juntuan_delta < 0:
		return {"ok": false, "state": state, "duplicate": false}
	state.money += money_delta
	state.juntuan += juntuan_delta
	state.ledger.append(operation_id)
	if state.ledger.size() > LEDGER_LIMIT:
		state.ledger.pop_front()
	return {"ok": true, "state": state, "duplicate": false}

func migrate_v0(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	if int(raw.get("version", 0)) == VERSION:
		return normalize(raw)
	var result = new_state()
	result.money = max(0, int(raw.get("money", 0)))
	result.juntuan = max(0, int(raw.get("juntuan", 0)))
	return result
