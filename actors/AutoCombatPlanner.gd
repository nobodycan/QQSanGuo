extends Reference

func decide(context: Dictionary) -> Dictionary:
	if typeof(context) != TYPE_DICTIONARY or not bool(context.get("has_reachable_target", false)):
		return {"action": "idle", "skill_id": ""}
	var candidates = []
	for skill in context.get("active_skills", []):
		if typeof(skill) == TYPE_DICTIONARY and bool(skill.get("available", false)) and not str(skill.get("id", "")).empty():
			candidates.append(skill)
	if not candidates.empty():
		candidates.sort_custom(self, "_higher_priority")
		return {"action": "cast", "skill_id": str(candidates[0].id)}
	var basic_skill_id = str(context.get("basic_skill_id", ""))
	return {"action": "cast", "skill_id": basic_skill_id} if not basic_skill_id.empty() else {"action": "idle", "skill_id": ""}

func _higher_priority(left: Dictionary, right: Dictionary) -> bool:
	var left_priority = int(left.get("priority", 0))
	var right_priority = int(right.get("priority", 0))
	return left_priority > right_priority or (left_priority == right_priority and str(left.id) < str(right.id))
