extends Reference

func retry(dungeon: Dictionary, previous_run: Dictionary, next_run: Dictionary, event_id: String) -> Dictionary:
	if event_id.empty() or str(previous_run.get("kind", "")) != "dungeon" or str(next_run.get("kind", "")) != "dungeon" or str(previous_run.get("encounter_id", "")) != str(dungeon.get("dungeon_id", "")) or str(next_run.get("encounter_id", "")) != str(dungeon.get("dungeon_id", "")) or str(previous_run.get("status", "")) != "cleaned" or not ["prepared", "active"].has(str(next_run.get("status", ""))):
		return _failure(dungeon, previous_run, next_run)
	var dungeon_state = load("res://actors/DungeonState.gd").new().apply(dungeon, event_id, "retry")
	if not dungeon_state.get("ok", false):
		return _failure(dungeon, previous_run, next_run)
	var director = load("res://actors/EncounterDirector.gd").new()
	var started_run = director.apply(next_run, event_id, "start")
	if not started_run.get("ok", false):
		return _failure(dungeon, previous_run, next_run)
	return {"ok": true, "duplicate": dungeon_state.duplicate and started_run.duplicate, "dungeon": dungeon_state.state, "previous_run": previous_run.duplicate(true), "run": started_run.state}

func _failure(dungeon: Dictionary, previous_run: Dictionary, next_run: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "dungeon": dungeon.duplicate(true), "previous_run": previous_run.duplicate(true), "run": next_run.duplicate(true)}
