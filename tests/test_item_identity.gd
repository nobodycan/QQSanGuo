extends SceneTree

const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var templates = ItemTemplate.new()
	var instances = ItemInstance.new()
	var herb = templates.normalize({"id": "item.herb", "stack_limit": 99, "kind": "consumable"})
	var sword = templates.normalize({"id": "item.sword", "stack_limit": 1, "kind": "equipment"})
	test.expect(not herb.empty() and herb.stackable, "stackable template normalizes with a stable ID")
	test.expect(instances.new_stack(herb, 99).quantity == 99 and instances.new_stack(herb, 100).empty(), "stack quantity respects template capacity")
	var first = instances.new_instance(sword)
	var second = instances.new_instance(sword)
	test.expect(not first.empty() and first.instance_id != second.instance_id, "same-template equipment has distinct instance identities")
	test.expect(templates.normalize({"id": "bad-id", "stack_limit": 1}).empty(), "invalid template IDs are rejected")
	test.finish(self, "item_identity")
