extends Reference

const FACTION_PLAYER = "player"
const FACTION_ENEMY = "enemy"
const FACTION_BOSS = "boss"

var targets = {}

func register_target(actor_id: String, faction: String, position: Vector2) -> bool:
	if actor_id.empty() or faction.empty() or targets.has(actor_id):
		return false
	targets[actor_id] = {"id": actor_id, "faction": faction, "position": position}
	return true

func unregister_target(actor_id: String) -> void:
	targets.erase(actor_id)

func select_nearest(source_id: String, source_faction: String, source_position: Vector2) -> Dictionary:
	var selected = {}
	var best_distance = INF
	for actor_id in targets.keys():
		var candidate = targets[actor_id]
		if actor_id == source_id or candidate.faction == source_faction:
			continue
		var distance = source_position.distance_squared_to(candidate.position)
		if selected.empty() or distance < best_distance or (distance == best_distance and actor_id < selected.id):
			selected = candidate
			best_distance = distance
	return selected
