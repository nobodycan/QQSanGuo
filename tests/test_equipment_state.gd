extends SceneTree

const EquipmentState = preload("res://actors/EquipmentState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var equipment = EquipmentState.new()
	var sword = {"instance_id": "item.sword.1", "slot": "Sword", "job": "js", "level": 2, "modifiers": {"basic_damage": 4, "max_health": 20}}
	var better_sword = {"instance_id": "item.sword.2", "slot": "Sword", "job": "js", "level": 2, "modifiers": {"basic_damage": 9}}
	var base = {"basic_damage": 20, "max_health": 1000}
	var state = equipment.equip(equipment.new_state(), sword, "js", 2)
	test.expect(state.slots.Sword.instance_id == "item.sword.1", "equips an eligible instance into its fixed slot")
	test.expect(equipment.derived(base, state).basic_damage == 24 and equipment.derived(base, state).max_health == 1020, "derives modifiers from base values")
	state = equipment.equip(state, better_sword, "js", 2)
	test.expect(state.slots.Sword.instance_id == "item.sword.2" and equipment.derived(base, state).basic_damage == 29, "swaps equipment without additive drift")
	for _repeat in range(10):
		state = equipment.equip(state, better_sword, "js", 2)
	test.expect(equipment.derived(base, state).basic_damage == 29, "repeated equip does not drift derived stats")
	test.expect(equipment.equip(equipment.new_state(), sword, "fs", 2).empty() and equipment.equip(equipment.new_state(), sword, "js", 1).empty(), "rejects job and level ineligible equipment")
	var unequipped = equipment.unequip(state, "Sword")
	test.expect(unequipped.slots.Sword.empty() and equipment.derived(base, unequipped).basic_damage == 20, "unequip restores base-derived value")
	test.finish(self, "equipment_state")
