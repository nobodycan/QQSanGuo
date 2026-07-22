extends Reference

const PlayerIntent = preload("res://actors/PlayerIntent.gd")
const CombatAction = preload("res://actors/CombatAction.gd")

var combat = CombatAction.new()
var action_sequence = 0

func execute(intent: Reference, skill_book, skill_id: String, attacker: Dictionary, defender: Dictionary, defender_vitals: Dictionary, defense: int) -> Dictionary:
	if intent == null or (intent.source != PlayerIntent.SOURCE_MANUAL and intent.source != PlayerIntent.SOURCE_AUTOMATION):
		return {"ok": false, "error": "invalid_intent", "vitals": defender_vitals}
	var cast = skill_book.cast(skill_id, int(attacker.get("magic", 0)))
	if not cast.ok:
		return {"ok": false, "error": cast.error, "vitals": defender_vitals}
	action_sequence += 1
	var action = {
		"id": intent.source + ":" + skill_id + ":" + str(defender.get("id", "")) + ":" + str(action_sequence),
		"attacker": {"id": str(attacker.get("id", "")), "faction": str(attacker.get("faction", ""))},
		"defender": {"id": str(defender.get("id", "")), "faction": str(defender.get("faction", ""))},
		"damage": {"base_damage": cast.damage, "defense": defense}
	}
	var result = combat.resolve(action, defender_vitals)
	result.source = intent.source
	result.magic = cast.magic
	return result
