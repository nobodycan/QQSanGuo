extends Reference

func start(encounter: Dictionary, run: Dictionary, event_id: String, definition: Dictionary, world: Dictionary, player_level: int) -> Dictionary:
	if event_id.empty() or str(encounter.get("boss_id", "")).empty() or str(encounter.get("boss_id", "")) != str(definition.get("id", "")) or str(run.get("kind", "")) != "boss" or str(run.get("encounter_id", "")) != str(definition.get("id", "")):
		return _failure(encounter, run, "invalid_request")
	var encounter_state = load("res://actors/BossEncounterState.gd").new()
	var replay = encounter_state.apply(encounter, event_id, "start")
	if replay.get("ok", false) and replay.get("duplicate", false):
		return {"ok": true, "duplicate": true, "reason": "", "encounter": replay.state, "run": run.duplicate(true)}
	var access = load("res://actors/BossAccessPolicy.gd").new().can_start(definition, world, player_level)
	if not access.ok:
		return _failure(encounter, run, access.reason)
	var started_run = load("res://actors/EncounterDirector.gd").new().apply(run, event_id, "start")
	if not started_run.get("ok", false):
		return _failure(encounter, run, "run_unavailable")
	var started_encounter = encounter_state.apply(encounter, event_id, "start")
	if not started_encounter.ok:
		return _failure(encounter, run, "invalid_transition")
	return {"ok": true, "duplicate": false, "reason": "", "encounter": started_encounter.state, "run": started_run.state}

func _failure(encounter: Dictionary, run: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "reason": reason, "encounter": encounter.duplicate(true), "run": run.duplicate(true)}
