extends Reference

const EquipmentState = preload("res://actors/EquipmentState.gd")
const EnhancementState = preload("res://actors/EnhancementState.gd")

var state = EquipmentState.new().new_state()
var names_by_instance = {}

func equip_legacy(name: String, raw: Dictionary, player_job: String, player_level: int) -> bool:
	var item = _item(name, raw)
	if item.empty():
		return false
	var next = EquipmentState.new().equip(state, item, player_job, player_level)
	if next.empty():
		return false
	state = next
	names_by_instance[item.instance_id] = name
	return true

func unequip(slot_name: String) -> bool:
	var current = state.slots.get(slot_name, {})
	var next = EquipmentState.new().unequip(state, slot_name)
	if next.empty():
		return false
	if not current.empty():
		names_by_instance.erase(str(current.instance_id))
	state = next
	return true

func project_legacy() -> Dictionary:
	var result = {}
	for slot_name in EquipmentState.SLOTS:
		var item = state.slots[slot_name]
		result[slot_name] = "" if item.empty() else str(names_by_instance.get(str(item.instance_id), ""))
	return result

func derived(base: Dictionary) -> Dictionary:
	return EquipmentState.new().derived(base, state)

func enhance(slot_name: String) -> bool:
	if not state.slots.has(slot_name) or state.slots[slot_name].empty():
		return false
	var upgraded = EnhancementState.new().upgrade(state.slots[slot_name])
	if upgraded.empty():
		return false
	state.slots[slot_name] = upgraded
	return true

func project_presenter() -> Dictionary:
	var result = {}
	for slot_name in EquipmentState.SLOTS:
		var item = state.slots[slot_name]
		result[slot_name] = {"name": "", "enhancement_level": 0, "power_score": 0} if item.empty() else {"name": str(names_by_instance.get(str(item.instance_id), "")), "enhancement_level": int(item.enhancement_level), "power_score": EnhancementState.new().power_score(item.modifiers, int(item.enhancement_level))}
	return result

func _item(name: String, raw: Dictionary) -> Dictionary:
	var slot_name = str(raw.get("ItemCategory", ""))
	if name.empty() or not EquipmentState.SLOTS.has(slot_name):
		return {}
	var modifiers = {}
	for source in {"WuGong": "basic_damage", "WuFang": "basic_defende", "ShuGong": "basic_shugong", "ShuFang": "basic_shufang", "HP": "max_health", "Mana": "max_magic", "Force": "force", "Agility": "agility", "Strong": "strong", "Wisdom": "wisdom", "Aim": "aim"}:
		if raw.get(source, null) != null:
			modifiers[{"WuGong": "basic_damage", "WuFang": "basic_defende", "ShuGong": "basic_shugong", "ShuFang": "basic_shufang", "HP": "max_health", "Mana": "max_magic", "Force": "force", "Agility": "agility", "Strong": "strong", "Wisdom": "wisdom", "Aim": "aim"}[source]] = int(raw[source])
	return {"instance_id": "legacy." + name.md5_text(), "slot": slot_name, "job": str(raw.get("Job", "")), "level": max(1, int(raw.get("ItemLevel", 1))), "modifiers": modifiers, "enhancement_level": int(raw.get("enhancement_level", 0))}
