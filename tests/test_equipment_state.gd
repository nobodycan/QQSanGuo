extends SceneTree

const EquipmentState = preload("res://actors/EquipmentState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var equipment = EquipmentState.new()
	var sword = {"instance_id": "item.sword.1", "slot": "Sword", "job": "js", "level": 2, "modifiers": {"basic_damage": 4, "max_health": 20}, "enhancement_level": 0}
	var better_sword = {"instance_id": "item.sword.2", "slot": "Sword", "job": "js", "level": 2, "modifiers": {"basic_damage": 9}, "enhancement_level": 0}
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
	var migrated = equipment.migrate_v0({"Sword": "legacy sword", "Ring": "legacy sword"}, {"legacy sword": {"job": "js", "level": 1, "modifiers": {"basic_damage": 4}}})
	var remigrated = equipment.migrate_v0(migrated, {})
	test.expect(migrated.slots.Sword.instance_id != migrated.slots.Ring.instance_id and remigrated.slots.Sword.instance_id == migrated.slots.Sword.instance_id and remigrated.slots.Ring.instance_id == migrated.slots.Ring.instance_id, "v0 migration creates stable distinct equipment identities")
	test.expect(equipment.migrate_v0({"Sword": "unknown"}, {}).empty(), "rejects legacy equipment without an explicit alias")
	var v1 = {"version": 1, "slots": equipment.new_state().slots}
	v1.slots.Sword = sword.duplicate(true)
	var migrated_v1 = equipment.migrate_v1(v1)
	test.expect(migrated_v1.version == 2 and migrated_v1.slots.Sword.enhancement_level == 0, "migrates v1 equipment with a default enhancement level")
	test.finish(self, "equipment_state")
