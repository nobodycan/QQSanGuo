extends SceneTree

const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var inventory = InventoryState.new()
	var template = ItemTemplate.new().normalize({"id": "item.herb", "stack_limit": 10})
	var instances = ItemInstance.new()
	var state = inventory.add(inventory.new_state(), template, 25, instances)
	test.expect(state.slots[0].quantity == 10 and state.slots[1].quantity == 10 and state.slots[2].quantity == 5, "add fills deterministic stacks")
	var full = inventory.new_state()
	for index in range(InventoryState.SLOT_COUNT):
		full.slots.append(instances.new_stack(template, 10))
	test.expect(inventory.add(full, template, 1, instances).empty(), "full inventory rejects without mutating state")
	test.finish(self, "inventory_state")
