extends Reference

func resolve(action: Dictionary) -> Dictionary:
	if typeof(action) != TYPE_DICTIONARY or int(action.get("base_damage", -1)) < 0 or int(action.get("defense", -1)) < 0:
		return {"ok": false, "error": "invalid_action"}
	var multiplier = float(action.get("multiplier", 1.0))
	if is_nan(multiplier) or is_inf(multiplier) or multiplier < 0.0:
		return {"ok": false, "error": "invalid_multiplier"}
	var critical = bool(action.get("critical", false))
	var critical_multiplier = float(action.get("critical_multiplier", 1.5)) if critical else 1.0
	if is_nan(critical_multiplier) or is_inf(critical_multiplier) or critical_multiplier < 1.0:
		return {"ok": false, "error": "invalid_critical_multiplier"}
	var scaled = int(floor(float(action.base_damage) * multiplier * critical_multiplier))
	var final_damage = max(0, scaled - int(action.defense))
	return {"ok": true, "damage": final_damage, "critical": critical, "scaled_damage": scaled}
