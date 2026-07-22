extends Reference

var spawned = {}
var rewarded_defeats = {}

func spawn(actor_id: String) -> bool:
	if actor_id.empty() or spawned.has(actor_id):
		return false
	spawned[actor_id] = true
	return true

func defeat(actor_id: String, defeat_id: String) -> Dictionary:
	if not spawned.has(actor_id):
		return {"ok": false, "error": "unknown_actor"}
	spawned.erase(actor_id)
	if defeat_id.empty() or rewarded_defeats.has(defeat_id):
		return {"ok": false, "error": "duplicate_defeat"}
	rewarded_defeats[defeat_id] = true
	return {"ok": true, "reward": true}

func cleanup() -> int:
	var count = spawned.size()
	spawned.clear()
	return count
