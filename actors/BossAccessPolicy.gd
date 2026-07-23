extends Reference

func can_start(definition: Dictionary, world: Dictionary, player_level: int) -> Dictionary:
	if typeof(definition) != TYPE_DICTIONARY or typeof(world) != TYPE_DICTIONARY or str(definition.get("id", "")).empty() or str(definition.get("map_id", "")).empty() or player_level < 1:
		return _deny("invalid_request")
	if player_level < int(definition.get("min_level", 1)):
		return _deny("level_locked")
	if not world.get("unlocked_maps", []).has(str(definition.map_id)):
		return _deny("map_locked")
	for required_flag in definition.get("requires_flags", []):
		if typeof(required_flag) != TYPE_STRING or not world.get("flags", []).has(required_flag):
			return _deny("flag_locked")
	if not bool(definition.get("repeatable", false)) and world.get("defeated_bosses", []).has(str(definition.id)):
		return _deny("already_defeated")
	return {"ok": true, "reason": ""}

func _deny(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
