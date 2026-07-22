extends Reference

const HitResolver = preload("res://actors/HitResolver.gd")
const DamagePipeline = preload("res://actors/DamagePipeline.gd")
const Vitals = preload("res://actors/Vitals.gd")

var hits = HitResolver.new()
var damage = DamagePipeline.new()
var vitals = Vitals.new()

func resolve(action: Dictionary, defender_vitals: Dictionary) -> Dictionary:
	if typeof(action) != TYPE_DICTIONARY:
		return {"ok": false, "error": "invalid_action", "vitals": defender_vitals}
	var hit = hits.resolve(str(action.get("id", "")), action.get("attacker", {}), action.get("defender", {}))
	if not hit.ok:
		return {"ok": false, "error": hit.error, "vitals": defender_vitals}
	var result = damage.resolve(action.get("damage", {}))
	if not result.ok:
		return {"ok": false, "error": result.error, "vitals": defender_vitals}
	var next_vitals = vitals.damage(defender_vitals, result.damage)
	return {"ok": true, "hit_id": hit.hit_id, "damage": result.damage, "defeated": not next_vitals.alive, "vitals": next_vitals}
