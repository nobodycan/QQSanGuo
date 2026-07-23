extends Reference

func decide(context: Dictionary) -> Dictionary:
	if typeof(context) != TYPE_DICTIONARY:
		return _deny("invalid_context")
	if not bool(context.get("map_allows_auto", false)):
		return _deny("map_disallows_auto")
	if not bool(context.get("player_alive", false)):
		return _deny("player_dead")
	if bool(context.get("manual_stop", false)):
		return _deny("manual_stop")
	if bool(context.get("transitioning", false)):
		return _deny("transition")
	if bool(context.get("pause_or_blocking_ui", false)):
		return _deny("pause_or_blocking_ui")
	if bool(context.get("inventory_full", false)):
		return _deny("inventory_full")
	if bool(context.get("quest_complete", false)):
		return _deny("quest_complete")
	if ["boss", "dungeon"].has(str(context.get("active_encounter_kind", ""))):
		return _deny("boss_or_dungeon")
	if not bool(context.get("has_reachable_target", false)):
		return _deny("no_reachable_target")
	return {"ok": true, "reason": ""}

func _deny(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
