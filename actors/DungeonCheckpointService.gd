extends Reference

func reach(dungeon: Dictionary, world: Dictionary, event_id: String, checkpoint: String) -> Dictionary:
	if event_id.empty() or checkpoint.empty():
		return _failure(dungeon, world)
	var state_service = load("res://actors/DungeonState.gd").new()
	var progressed = state_service.apply(dungeon, event_id, "checkpoint", checkpoint)
	if progressed.get("ok", false) and progressed.get("duplicate", false):
		return {"ok": true, "duplicate": true, "dungeon": progressed.state, "world": world.duplicate(true)}
	if not progressed.get("ok", false):
		return _failure(dungeon, world)
	var dungeon_id = str(dungeon.get("dungeon_id", ""))
	var saved = load("res://actors/WorldState.gd").new().apply(world, "dungeon.checkpoint." + dungeon_id + "." + event_id, "checkpoint", dungeon_id + ":" + checkpoint)
	if not saved.ok:
		return _failure(dungeon, world)
	return {"ok": true, "duplicate": false, "dungeon": progressed.state, "world": saved.state}

func _failure(dungeon: Dictionary, world: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "dungeon": dungeon.duplicate(true), "world": world.duplicate(true)}
