extends Reference

const BASIS_POINTS = 10000

func resolve(raw: Dictionary, rng_seed: int, flags: Dictionary = {}) -> Array:
	if typeof(raw) != TYPE_DICTIONARY or typeof(raw.get("entries", null)) != TYPE_ARRAY:
		return []
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed
	var result = []
	for entry in raw.entries:
		if not _valid_entry(entry) or not _conditions_met(entry.get("requires", []), flags):
			continue
		if bool(entry.get("guaranteed", false)) or rng.randi_range(1, BASIS_POINTS) <= int(entry.chance_bps):
			result.append({"item_id": str(entry.item_id), "quantity": rng.randi_range(int(entry.min_quantity), int(entry.max_quantity))})
	return result

func _valid_entry(entry) -> bool:
	return typeof(entry) == TYPE_DICTIONARY and str(entry.get("item_id", "")).length() > 0 and int(entry.get("min_quantity", 0)) >= 1 and int(entry.get("max_quantity", 0)) >= int(entry.get("min_quantity", 0)) and int(entry.get("chance_bps", -1)) >= 0 and int(entry.get("chance_bps", -1)) <= BASIS_POINTS and typeof(entry.get("requires", [])) == TYPE_ARRAY

func _conditions_met(requires: Array, flags: Dictionary) -> bool:
	for flag_name in requires:
		if typeof(flag_name) != TYPE_STRING or not bool(flags.get(flag_name, false)):
			return false
	return true
