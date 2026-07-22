extends Reference

const SECTION_VERSION = 1
const MAX_LEVEL = 30
const XP_TO_NEXT = [
	100, 120, 140, 160, 180, 200, 220, 240, 260, 280,
	300, 320, 340, 360, 380, 400, 420, 440, 460, 480,
	500, 520, 540, 560, 580, 600, 620, 640, 660
]
const BASE = {"max_health": 1000, "max_magic": 1000, "basic_damage": 20, "basic_defende": 10, "basic_shugong": 0, "basic_shufang": 0, "force": 0, "agility": 0, "strong": 0, "wisdom": 0, "aim": 0}
const EquipmentState = preload("res://actors/EquipmentState.gd")

func new_state() -> Dictionary:
	return {"version": SECTION_VERSION, "level": 1, "experience": 0, "overflow_experience": 0, "base": BASE.duplicate(true), "derived": BASE.duplicate(true)}

func required_experience(level: int) -> int:
	if level < 1 or level >= MAX_LEVEL:
		return 0
	return XP_TO_NEXT[level - 1]

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != SECTION_VERSION:
		return {}
	var result = new_state()
	if int(raw.get("level", 0)) < 1 or int(raw.level) > MAX_LEVEL or int(raw.get("experience", -1)) < 0 or int(raw.get("overflow_experience", -1)) < 0:
		return {}
	if typeof(raw.get("base", null)) != TYPE_DICTIONARY:
		return {}
	result.level = int(raw.level)
	result.experience = int(raw.experience)
	result.overflow_experience = int(raw.overflow_experience)
	for key in BASE:
		if typeof(raw.base.get(key, null)) != TYPE_INT:
			return {}
		result.base[key] = int(raw.base[key])
	if result.level < MAX_LEVEL and result.experience >= required_experience(result.level):
		return {}
	if result.level == MAX_LEVEL and result.experience != 0:
		return {}
	result.derived = _derived(result.base, result.level)
	return result

func migrate_v0(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return new_state()
	if int(raw.get("version", 0)) == SECTION_VERSION:
		var normalized = normalize(raw)
		return normalized.duplicate(true) if not normalized.empty() else {}
	var result = new_state()
	result.level = clamp(int(raw.get("level", 1)), 1, MAX_LEVEL)
	result.experience = max(0, int(raw.get("experience", raw.get("exprience", 0))))
	for key in BASE:
		if raw.has(key) and typeof(raw[key]) == TYPE_INT:
			result.base[key] = int(raw[key])
	if result.level == MAX_LEVEL:
		result.overflow_experience = result.experience
		result.experience = 0
	elif result.experience >= required_experience(result.level):
		result = grant_experience(result, 0)
	result.derived = _derived(result.base, result.level)
	return result

func grant_experience(raw, amount: int) -> Dictionary:
	var result = normalize(raw)
	if result.empty() or amount < 0:
		return {}
	if result.level == MAX_LEVEL:
		result.overflow_experience += amount
		return result
	result.experience += amount
	while result.level < MAX_LEVEL and result.experience >= required_experience(result.level):
		result.experience -= required_experience(result.level)
		result.level += 1
	if result.level == MAX_LEVEL:
		result.overflow_experience += result.experience
		result.experience = 0
	result.derived = _derived(result.base, result.level)
	return result

func apply_legacy(stats: Dictionary, inventory) -> bool:
	var normalized = normalize(stats)
	if normalized.empty() or inventory == null:
		return false
	inventory.level = normalized.level
	for key in normalized.derived:
		inventory.set(key, normalized.derived[key])
	return true

func derive_with_equipment(stats: Dictionary, equipment: Dictionary) -> Dictionary:
	var normalized = normalize(stats)
	if normalized.empty():
		return {}
	return EquipmentState.new().derived(normalized.derived, equipment)

func _derived(base: Dictionary, level: int) -> Dictionary:
	var result = base.duplicate(true)
	var gained = level - 1
	result.max_health += gained * 10
	result.max_magic += gained * 5
	result.basic_damage += gained * 2
	result.basic_defende += gained
	result.basic_shugong += gained
	result.basic_shufang += gained
	return result
