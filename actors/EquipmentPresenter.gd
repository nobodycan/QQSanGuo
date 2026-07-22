extends Reference

const EquipmentState = preload("res://actors/EquipmentState.gd")
const EnhancementState = preload("res://actors/EnhancementState.gd")

func present(raw: Dictionary, names_by_instance: Dictionary = {}) -> Dictionary:
	var state = EquipmentState.new().normalize(raw)
	if state.empty():
		return {}
	var result = {}
	for slot_name in EquipmentState.SLOTS:
		var item = state.slots[slot_name]
		if item.empty():
			result[slot_name] = {"empty": true, "name": "", "enhancement_level": 0, "power_score": 0, "title": ""}
			continue
		var level = int(item.enhancement_level)
		var name = str(names_by_instance.get(str(item.instance_id), str(item.instance_id)))
		result[slot_name] = {"empty": false, "name": name, "enhancement_level": level, "power_score": EnhancementState.new().power_score(item.modifiers, level), "title": "+" + str(level) + " " + name}
	return result
