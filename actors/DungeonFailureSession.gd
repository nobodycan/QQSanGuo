extends Reference

func fail(dungeon: Dictionary, run: Dictionary, event_id: String) -> Dictionary:
	if event_id.empty() or str(run.get("kind", "")) != "dungeon" or str(run.get("encounter_id", "")) != str(dungeon.get("dungeon_id", "")):
		return _failure(dungeon, run)
	var dungeon_state = load("res://actors/DungeonState.gd").new()
	var replay = dungeon_state.apply(dungeon, event_id, "fail")
	if replay.get("ok", false) and replay.get("duplicate", false):
		return {"ok": true, "duplicate": true, "dungeon": replay.state, "run": run.duplicate(true)}
	if not replay.get("ok", false):
		return _failure(dungeon, run)
	var failed_run = load("res://actors/EncounterDirector.gd").new().apply(run, event_id, "failure")
	if not failed_run.get("ok", false):
		return _failure(dungeon, run)
	return {"ok": true, "duplicate": false, "dungeon": replay.state, "run": failed_run.state}

func _failure(dungeon: Dictionary, run: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "dungeon": dungeon.duplicate(true), "run": run.duplicate(true)}
