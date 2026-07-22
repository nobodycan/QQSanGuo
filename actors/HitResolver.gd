extends Reference

var resolved_hits = {}

func resolve(hit_id: String, attacker: Dictionary, defender: Dictionary) -> Dictionary:
	if hit_id.empty() or resolved_hits.has(hit_id):
		return {"ok": false, "error": "duplicate_hit"}
	if attacker.empty() or defender.empty() or attacker.get("id", "") == defender.get("id", ""):
		return {"ok": false, "error": "invalid_target"}
	if attacker.get("faction", "") == defender.get("faction", ""):
		return {"ok": false, "error": "friendly_target"}
	resolved_hits[hit_id] = true
	return {"ok": true, "hit_id": hit_id, "attacker_id": attacker.id, "defender_id": defender.id}
