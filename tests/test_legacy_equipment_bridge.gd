extends SceneTree

const LegacyEquipmentBridge = preload("res://actors/LegacyEquipmentBridge.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var bridge = LegacyEquipmentBridge.new()
	var sword = {"ItemCategory": "Sword", "Job": "js", "ItemLevel": 2, "WuGong": 4, "HP": 20}
	var better = {"ItemCategory": "Sword", "Job": "js", "ItemLevel": 2, "WuGong": 9}
	test.expect(bridge.equip_legacy("legacy sword", sword, "js", 2), "converts a legacy item definition into equipment")
	test.expect(bridge.derived({"basic_damage": 20, "max_health": 1000}).basic_damage == 24 and bridge.project_legacy().Sword == "legacy sword", "projects equipment and recomputes its modifiers")
	test.expect(bridge.equip_legacy("better sword", better, "js", 2) and bridge.derived({"basic_damage": 20}).basic_damage == 29, "swaps legacy equipment without additive drift")
	test.expect(not bridge.equip_legacy("better sword", better, "fs", 2) and not bridge.equip_legacy("better sword", better, "js", 1), "enforces legacy job and level eligibility")
	test.expect(bridge.unequip("Sword") and bridge.project_legacy().Sword == "", "unequips legacy equipment through the bridge")
	test.finish(self, "legacy_equipment_bridge")
