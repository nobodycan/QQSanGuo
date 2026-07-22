extends Reference

const VERSION = 1
const SLOTS = ["Head", "Up_Body", "Necklace", "Hand", "Sword", "Boot", "Down_Body", "Wing", "Mask", "Ring"]

func new_state() -> Dictionary:
	var slots = {}
	for slot_name in SLOTS:
		slots[slot_name] = {}
	return {"version": VERSION, "slots": slots}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION or typeof(raw.get("slots", null)) != TYPE_DICTIONARY:
		return {}
	var result = new_state()
	for slot_name in SLOTS:
		var item = raw.slots.get(slot_name, {})
		if item.empty():
			continue
		if not _valid_item(item, slot_name):
			return {}
		result.slots[slot_name] = item.duplicate(true)
	return result

func equip(raw: Dictionary, item: Dictionary, player_job: String, player_level: int) -> Dictionary:
	var result = normalize(raw)
	if result.empty() or not _valid_item(item, str(item.get("slot", ""))) or not _eligible(item, player_job, player_level):
		return {}
	result.slots[item.slot] = item.duplicate(true)
	return result

func unequip(raw: Dictionary, slot_name: String) -> Dictionary:
	var result = normalize(raw)
	if result.empty() or not SLOTS.has(slot_name) or result.slots[slot_name].empty():
		return {}
	result.slots[slot_name] = {}
	return result

func derived(base: Dictionary, raw) -> Dictionary:
	var state = normalize(raw)
	if state.empty():
		return {}
	var result = base.duplicate(true)
	for slot_name in SLOTS:
		var item = state.slots[slot_name]
		if item.empty():
			continue
		for key in item.modifiers:
			result[key] = int(result.get(key, 0)) + int(item.modifiers[key])
	return result

func _eligible(item: Dictionary, player_job: String, player_level: int) -> bool:
	return (str(item.get("job", "")) == "" or str(item.job) == player_job) and player_level >= int(item.get("level", 1))

func _valid_item(item, slot_name: String) -> bool:
	if typeof(item) != TYPE_DICTIONARY or not SLOTS.has(slot_name) or str(item.get("instance_id", "")).empty() or str(item.get("slot", "")) != slot_name or typeof(item.get("modifiers", null)) != TYPE_DICTIONARY:
		return false
	for key in item.modifiers:
		if typeof(key) != TYPE_STRING or typeof(item.modifiers[key]) != TYPE_INT:
			return false
	return true
