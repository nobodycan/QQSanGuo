extends Reference

func fail(encounter: Dictionary, run: Dictionary, event_id: String) -> Dictionary:
	if event_id.empty() or str(run.get("kind", "")) != "boss" or str(run.get("encounter_id", "")) != str(encounter.get("boss_id", "")):
		return _failure(encounter, run)
	var encounter_state = load("res://actors/BossEncounterState.gd").new()
	var replay = encounter_state.apply(encounter, event_id, "reset")
	if replay.get("ok", false) and replay.get("duplicate", false):
		return {"ok": true, "duplicate": true, "encounter": replay.state, "run": run.duplicate(true)}
	if not replay.get("ok", false):
		return _failure(encounter, run)
	var failed_run = load("res://actors/EncounterDirector.gd").new().apply(run, event_id, "failure")
	if not failed_run.get("ok", false):
		return _failure(encounter, run)
	return {"ok": true, "duplicate": false, "encounter": replay.state, "run": failed_run.state}

func _failure(encounter: Dictionary, run: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "encounter": encounter.duplicate(true), "run": run.duplicate(true)}
