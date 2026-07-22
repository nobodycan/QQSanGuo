extends Reference

func apply(effects: Array, incoming: Dictionary) -> Array:
	var result = effects.duplicate(true)
	var effect_id = str(incoming.get("id", ""))
	if effect_id.empty() or int(incoming.get("remaining_ticks", 0)) <= 0:
		return result
	for index in range(result.size()):
		if result[index].id == effect_id:
			result[index].remaining_ticks = max(result[index].remaining_ticks, int(incoming.remaining_ticks))
			result[index].stacks = min(int(incoming.get("max_stacks", 1)), result[index].stacks + 1)
			return result
	result.append({"id": effect_id, "remaining_ticks": int(incoming.remaining_ticks), "stacks": 1, "power": int(incoming.get("power", 0))})
	return result

func tick(effects: Array) -> Dictionary:
	var result = []
	var total_power = 0
	for effect in effects:
		total_power += int(effect.power) * int(effect.stacks)
		var remaining = int(effect.remaining_ticks) - 1
		if remaining > 0:
			var next = effect.duplicate(true)
			next.remaining_ticks = remaining
			result.append(next)
	return {"effects": result, "total_power": total_power}
