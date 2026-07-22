extends SceneTree

const EquipmentState = preload("res://actors/EquipmentState.gd")
const EquipmentPresenter = preload("res://actors/EquipmentPresenter.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var equipment = EquipmentState.new().new_state()
	equipment.slots.Sword = {"instance_id": "item.sword.1", "slot": "Sword", "job": "js", "level": 1, "modifiers": {"basic_damage": 25}, "enhancement_level": 5}
	var view = EquipmentPresenter.new().present(equipment, {"item.sword.1": "pilot sword"})
	test.expect(view.Sword.title == "+5 pilot sword" and view.Sword.power_score == 30 and view.Head.empty, "presents enhanced and empty equipment slots without mutating state")
	test.expect(EquipmentPresenter.new().present({}).empty(), "rejects malformed presenter input")
	test.finish(self, "equipment_presenter")
