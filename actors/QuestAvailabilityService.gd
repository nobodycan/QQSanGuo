extends Reference

func refresh(definitions: Array, states: Dictionary) -> Dictionary:
	var definition_result = load("res://actors/QuestDefinition.gd").new().validate(definitions)
	if not definition_result.ok:
		return {"ok": false, "states": states.duplicate(true)}
	var quest_state = load("res://actors/QuestState.gd").new()
	var result = states.duplicate(true)
	var quest_ids = definition_result.definitions.keys()
	quest_ids.sort()
	for quest_id in quest_ids:
		var state = result.get(quest_id, quest_state.new_state(quest_id))
		if str(state.get("status", "")) != "locked" or not _prerequisites_complete(definition_result.definitions[quest_id].prerequisites, result):
			result[quest_id] = state
			continue
		var unlocked = quest_state.apply(state, "availability." + quest_id, "unlock")
		if not unlocked.ok:
			return {"ok": false, "states": states.duplicate(true)}
		result[quest_id] = unlocked.state
	return {"ok": true, "states": result}

func _prerequisites_complete(prerequisites: Array, states: Dictionary) -> bool:
	for quest_id in prerequisites:
		if not states.has(quest_id) or str(states[quest_id].get("status", "")) != "completed":
			return false
	return true
