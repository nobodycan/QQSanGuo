extends Reference

func enter(state: Dictionary, event_id: String, definition: Dictionary, world: Dictionary, player_level: int) -> Dictionary:
	if event_id.empty() or typeof(definition) != TYPE_DICTIONARY or str(definition.get("id", "")).empty() or str(state.get("dungeon_id", "")) != str(definition.id):
		return _failure(state, "invalid_request")
	var dungeon_state = load("res://actors/DungeonState.gd").new()
	var replay = dungeon_state.apply(state, event_id, "enter")
	if replay.get("ok", false) and replay.get("duplicate", false):
		return {"ok": true, "duplicate": true, "reason": "", "state": replay.state}
	var access = load("res://actors/DungeonAccessPolicy.gd").new().can_enter(definition, world, player_level)
	if not access.ok:
		return _failure(state, access.reason)
	var result = dungeon_state.apply(state, event_id, "enter")
	return {"ok": result.ok, "duplicate": result.duplicate, "reason": "" if result.ok else "invalid_transition", "state": result.state}

func _failure(state: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "reason": reason, "state": state.duplicate(true)}
