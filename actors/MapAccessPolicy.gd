extends Reference

const WorldState = preload("res://actors/WorldState.gd")

func can_enter(maps: Array, world: Dictionary, target_map_id: String, target_spawn_id: String, current_map_id: String = "") -> Dictionary:
	var normalized_world = WorldState.new().normalize(world)
	if normalized_world.empty() or target_map_id.empty() or target_spawn_id.empty(): return {"ok": false, "reason": "invalid"}
	for definition in maps:
		if typeof(definition) != TYPE_DICTIONARY or str(definition.get("id", "")) != target_map_id: continue
		var has_spawn = false
		for spawn in definition.get("spawns", []):
			if typeof(spawn) == TYPE_DICTIONARY and str(spawn.get("id", "")) == target_spawn_id: has_spawn = true
		if not has_spawn: return {"ok": false, "reason": "spawn_missing"}
		if target_map_id != current_map_id and not normalized_world.unlocked_maps.has(target_map_id): return {"ok": false, "reason": "locked"}
		return {"ok": true, "reason": "allowed"}
	return {"ok": false, "reason": "map_missing"}

func can_enter_registered(registry: Node, world: Dictionary, target_map_id: String, target_spawn_id: String, current_map_id: String = "") -> Dictionary:
	if registry == null or not registry.has_method("entries_of_kind"):
		return {"ok": false, "reason": "registry_unavailable"}
	return can_enter(registry.entries_of_kind("map"), world, target_map_id, target_spawn_id, current_map_id)
