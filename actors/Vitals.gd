extends Reference

const VERSION = 1

func new_state(max_health: int = 1000, max_magic: int = 1000) -> Dictionary:
	return {"version": VERSION, "max_health": max(1, max_health), "max_magic": max(0, max_magic), "health": max(1, max_health), "magic": max(0, max_magic), "alive": true, "death_count": 0}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION or int(raw.get("max_health", 0)) < 1 or int(raw.get("max_magic", -1)) < 0:
		return {}
	var result = new_state(int(raw.max_health), int(raw.max_magic))
	result.health = clamp(int(raw.get("health", result.max_health)), 0, result.max_health)
	result.magic = clamp(int(raw.get("magic", result.max_magic)), 0, result.max_magic)
	result.alive = result.health > 0
	result.death_count = max(0, int(raw.get("death_count", 0)))
	return result

func damage(raw, amount: int) -> Dictionary:
	var result = normalize(raw)
	if result.empty() or amount < 0 or not result.alive:
		return result
	result.health = max(0, result.health - amount)
	if result.health == 0:
		result.alive = false
		result.death_count += 1
	return result

func recover(raw, health_amount: int, magic_amount: int) -> Dictionary:
	var result = normalize(raw)
	if result.empty() or not result.alive:
		return result
	result.health = clamp(result.health + max(0, health_amount), 0, result.max_health)
	result.magic = clamp(result.magic + max(0, magic_amount), 0, result.max_magic)
	return result

func revive(raw, health: int, magic: int) -> Dictionary:
	var result = normalize(raw)
	if result.empty():
		return result
	result.health = clamp(max(1, health), 1, result.max_health)
	result.magic = clamp(max(0, magic), 0, result.max_magic)
	result.alive = true
	return result
