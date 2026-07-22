extends Reference

const MAX_LEVEL = 10
const BASIS_POINTS = 10000
const MULTIPLIERS = [10000, 10400, 10800, 11200, 11600, 12000, 12400, 12800, 13200, 13600, 14000]

func valid_level(level: int) -> bool:
	return level >= 0 and level <= MAX_LEVEL

func multiplier_bps(level: int) -> int:
	return MULTIPLIERS[level] if valid_level(level) else 0

func round_value(value: int, level: int) -> int:
	var multiplier = multiplier_bps(level)
	if multiplier == 0:
		return 0
	return int(round(float(value * multiplier) / float(BASIS_POINTS)))

func modifiers(base: Dictionary, level: int) -> Dictionary:
	if typeof(base) != TYPE_DICTIONARY or not valid_level(level):
		return {}
	var result = {}
	for key in base:
		if typeof(key) != TYPE_STRING or typeof(base[key]) != TYPE_INT:
			return {}
		result[key] = round_value(base[key], level)
	return result

func power_score(base: Dictionary, level: int) -> int:
	var enhanced = modifiers(base, level)
	if enhanced.empty() and not base.empty():
		return 0
	var score = 0
	for key in enhanced:
		score += max(0, int(enhanced[key]))
	return score

func upgrade(item: Dictionary) -> Dictionary:
	if typeof(item) != TYPE_DICTIONARY:
		return {}
	var level = int(item.get("enhancement_level", 0))
	if not valid_level(level) or level >= MAX_LEVEL:
		return {}
	var result = item.duplicate(true)
	result.enhancement_level = level + 1
	return result
