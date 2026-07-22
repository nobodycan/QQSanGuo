extends SceneTree

const WorldPickup = preload("res://actors/WorldPickup.gd")
const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var herb = ItemTemplate.new().normalize({"id": "item.herb", "stack_limit": 10})
	var table = {"entries": [{"item_id": "item.herb", "min_quantity": 1, "max_quantity": 1, "chance_bps": 0, "guaranteed": true}]}
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var pickup = WorldPickup.new()
	var collected = pickup.collect(wallet, inventory, "drop.1", table, 7, {"item.herb": herb})
	test.expect(collected.ok and collected.remove_pickup and collected.inventory.slots[0].quantity == 1, "removes a pickup only after the reward commits")
	var full = InventoryState.new().new_state()
	for index in range(InventoryState.SLOT_COUNT): full.slots.append(ItemInstance.new().new_stack(herb, 10))
	full = InventoryState.new().normalize(full)
	var blocked = pickup.collect(wallet, full, "drop.2", table, 7, {"item.herb": herb})
	test.expect(not blocked.ok and not blocked.remove_pickup and blocked.inventory.slots[0].quantity == 10, "keeps a pickup when the inventory is full")
	test.finish(self, "world_pickup")
