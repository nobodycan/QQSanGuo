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
	var moved = inventory.move(state, 2, 4)
	test.expect(moved.slots[2].empty() and moved.slots[4].quantity == 5, "move transfers a stack to an empty slot")
	var split = inventory.split(state, 0, 4, 3)
	test.expect(split.slots[0].quantity == 7 and split.slots[4].quantity == 3, "split preserves stack quantity")
	test.expect(inventory.split(state, 0, 1, 3).empty(), "split rejects occupied targets without mutation")
	var consumed = inventory.consume(state, 2, 5, template)
	test.expect(consumed.slots[2].empty(), "consume removes the final stack item")
	var quest = ItemTemplate.new().normalize({"id": "item.quest", "stack_limit": 1, "quest": true})
	var quest_state = inventory.add(inventory.new_state(), quest, 1, instances)
	test.expect(inventory.consume(quest_state, 0, 1, quest).empty(), "quest items cannot be consumed")
	var random_state = inventory.add(inventory.new_state(), template, 300, instances)
	var random = RandomNumberGenerator.new()
	random.seed = 2201
	for command_index in range(1000):
		var before = inventory.export_state(random_state)
		var next = {}
		if command_index % 2 == 0:
			next = inventory.move(random_state, random.randi_range(0, InventoryState.SLOT_COUNT - 1), random.randi_range(0, InventoryState.SLOT_COUNT - 1))
		else:
			var source_slot = _slot_with_quantity(random_state, 2)
			var target_slot = _empty_slot(random_state)
			if source_slot >= 0 and target_slot >= 0:
				next = inventory.split(random_state, source_slot, target_slot, random.randi_range(1, int(random_state.slots[source_slot].quantity) - 1))
		if not next.empty():
			random_state = next
		else:
			test.expect(to_json(inventory.export_state(random_state)) == to_json(before), "rejected random command preserves state " + str(command_index))
		test.expect(_quantity(random_state, "item.herb") == 300, "random command preserves herb quantity " + str(command_index))
	test.expect(to_json(inventory.normalize(inventory.export_state(random_state))) == to_json(inventory.export_state(random_state)), "random inventory export round trips canonically")
	var migrated = inventory.migrate_v0({"0": ["草药", 2]}, {"草药": "item.herb"})
	var remigrated = inventory.migrate_v0(migrated, {})
	test.expect(migrated.slots[0].template_id == "item.herb" and remigrated.version == InventoryState.VERSION and remigrated.slots.size() == InventoryState.SLOT_COUNT and remigrated.slots[0].template_id == migrated.slots[0].template_id and remigrated.slots[0].quantity == migrated.slots[0].quantity, "v0 migration is idempotent and canonical")
	test.finish(self, "inventory_state")

func _quantity(state: Dictionary, template_id: String) -> int:
	var total = 0
	for slot in state.slots:
		if slot.get("template_id", "") == template_id:
			total += int(slot.get("quantity", 0))
	return total

func _slot_with_quantity(state: Dictionary, minimum: int) -> int:
	for index in range(InventoryState.SLOT_COUNT):
		if int(state.slots[index].get("quantity", 0)) >= minimum:
			return index
	return -1

func _empty_slot(state: Dictionary) -> int:
	for index in range(InventoryState.SLOT_COUNT):
		if state.slots[index].empty():
			return index
	return -1
