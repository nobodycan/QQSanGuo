extends Reference

func decide(context: Dictionary) -> Dictionary:
	var safety = load("res://actors/AutoCombatPolicy.gd").new().decide(context)
	if not safety.ok:
		return {"ok": false, "reason": safety.reason, "action": "idle", "skill_id": ""}
	var action = load("res://actors/AutoCombatPlanner.gd").new().decide(context)
	if action.action != "cast":
		return {"ok": false, "reason": "no_action", "action": "idle", "skill_id": ""}
	return {"ok": true, "reason": "", "action": action.action, "skill_id": action.skill_id}
